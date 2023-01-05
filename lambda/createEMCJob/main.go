package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/mediaconvert"
	emcTypes "github.com/aws/aws-sdk-go-v2/service/mediaconvert/types"
	"github.com/payt0nc/aws-event-driven-vod-transcode-pipeline/src/databases"
	"github.com/sirupsen/logrus"
)

var (
	logger            *logrus.Logger
	sfnTokenTableName string
	role              string
	queue             string
	endpoint          string
	outputBucket      string
)

type Event struct {
	SFNName   string `json:"sfnName"`
	SFNToken  string `json:"sfnToken"`
	SrcBucket string `json:"srcBucket"`
	SrcObject string `json:"srcObject"`
}

type UserMetadata struct {
	ContentID    string `json:"contentID"`
	SFNName      string `json:"sfnName"`
	SourceBucket string `json:"sourceBucket"`
	SourcePath   string `json:"sourcePath"`
	DestBucket   string `json:"destBucket"`
	DestPath     string `json:"destPath"`
}

func fomulateUserMetadata(contentID, sfnName, srcBucket, srcPath, dstBucket string) UserMetadata {
	return UserMetadata{
		ContentID:    contentID,
		SFNName:      sfnName,
		SourceBucket: srcBucket,
		SourcePath:   srcPath,
		DestBucket:   dstBucket,
		DestPath:     fmt.Sprintf("%s/", contentID),
	}
}

func (m UserMetadata) GetInputS3Path() string {
	return fmt.Sprintf("s3://%s/%s", m.SourceBucket, m.SourcePath)
}

func (m UserMetadata) GetOutputS3Path() string {
	return fmt.Sprintf("s3://%s/%s", m.DestBucket, m.DestPath)
}

func Handle(ctx context.Context, event Event) error {
	l := logger.WithField("event", event)
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}

	contentID := strings.TrimSuffix(event.SrcObject, filepath.Ext(event.SrcObject))
	meta := fomulateUserMetadata(contentID, event.SFNName, event.SrcBucket, event.SrcObject, outputBucket)
	l = l.WithField("userMetadata", meta)

	// Mediaconvert Endpoint
	resolver := mediaconvert.EndpointResolverFromURL(endpoint)

	// Create Elemental MediaConvert Job
	emc := mediaconvert.NewFromConfig(cfg, mediaconvert.WithEndpointResolver(resolver))
	jobSpec := CreateJobSpec(queue, role, meta)

	resp, err := emc.CreateJob(ctx, jobSpec)
	if err != nil {
		l.WithError(err).Error("Create MediaConvert Job Error")
		return err
	}
	l = l.WithField("mediaConvertJob", resp)
	l.Info("Create Job Success")

	// Insert DynamoDB
	sfnTokenTable := databases.NewTokenTableClient(cfg, sfnTokenTableName, l)
	if err := sfnTokenTable.InsertSFNToken(ctx, event.SFNName, event.SFNToken); err != nil {
		l.WithError(err).Error("Insert SFN Token Error")
		return err
	}
	l.Info("Insert SFN Token Success")
	return nil
}

func CreateJobSpec(queue string, roleArn string, meta UserMetadata) *mediaconvert.CreateJobInput {
	return &mediaconvert.CreateJobInput{
		AccelerationSettings: &emcTypes.AccelerationSettings{
			Mode: emcTypes.AccelerationModeDisabled,
		},
		Queue:       &queue,
		Role:        &roleArn,
		JobTemplate: aws.String("h265_cmaf"),
		Settings: &emcTypes.JobSettings{
			Inputs: []emcTypes.Input{
				{
					FileInput: aws.String(meta.GetInputS3Path()),
				},
			},
			OutputGroups: []emcTypes.OutputGroup{
				{
					OutputGroupSettings: &emcTypes.OutputGroupSettings{
						Type: "CMAF_GROUP_SETTINGS",
						CmafGroupSettings: &emcTypes.CmafGroupSettings{
							SegmentLength:  10,
							FragmentLength: 2,
							Destination:    aws.String(meta.GetOutputS3Path()),
						},
					},
				},
			},
		},
		UserMetadata: map[string]string{
			"contentID":    meta.ContentID,
			"sfnName":      meta.SFNName,
			"sourceBucket": meta.SourceBucket,
			"sourcePath":   meta.SourcePath,
			"destBucket":   meta.DestBucket,
			"destPath":     meta.DestPath,
		},
	}
}

func main() {
	lambda.Start(Handle)
}

func init() {
	// Load Env
	sfnTokenTableName = os.Getenv("DYNAMODB_SFN_TOKEN_TABLE_NAME")
	role = os.Getenv("EMC_ROLE")
	queue = os.Getenv("EMC_QUEUE")
	endpoint = os.Getenv("EMC_ENDPOINT")
	outputBucket = os.Getenv("EMC_OUTPUT_BUCKET")

	// Prepare Logger
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
}
