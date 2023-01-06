/*
Trigger: EventBridge Rule Event;
Input Parameter: Event Rules -> Input to Target
Source Event Samples:
{
  "version": "0",
  "id": "3fbdfd76-ff41-9ff8-d1ac-c3eecd53031b",
  "detail-type": "MediaConvert Job State Change",
  "source": "aws.mediaconvert",
  "account": "123456789012",
  "time": "2017-11-29T18:57:11Z",
  "region": "us-east-1",
  "resources": ["arn:aws:mediaconvert:us-east-1:123456789012:jobs/123456789012-smb6o7"],
  "detail": {
    "timestamp": 1511981831811,
    "accountId": "123456789012",
    "queue": "arn:aws:mediaconvert:us-east-1:123456789012:queues/Default",
    "jobId": "123456789012-smb6o7",
    "status": "PROGRESSING",
    "userMetadata": {}
  }
}
*/

package main

import (
	"context"
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sfn"
	"github.com/payt0nc/aws-event-driven-vod-transcode-pipeline/src/databases"
	"github.com/payt0nc/aws-event-driven-vod-transcode-pipeline/src/utils"
	"github.com/sirupsen/logrus"
)

var (
	logger                *logrus.Logger
	sfnTokenTableName     string
	mediaPackagingGroupID string
	mediaPackagingARN     string
)

type Event struct {
	JobID        string       `json:"jobId"`
	Status       string       `json:"status"`
	UserMetadata UserMetadata `json:"userMetadata"`
}

type UserMetadata struct {
	ContentID    string `json:"contentID"`
	SFNName      string `json:"sfnName"`
	SourceBucket string `json:"sourceBucket"`
	SourcePath   string `json:"sourcePath"`
	DestBucket   string `json:"destBucket"`
	DestPath     string `json:"destPath"`
}

type Output struct {
	Event
	MediaPackageInput MediaPackageInput `json:"task"`
}

type MediaPackageInput struct {
	ID               string `json:"id"`
	PackagingGroupID string `json:"packagingGroupId"`
	SourceARN        string `json:"sourceArn"`
	SourceRoleARN    string `json:"sourceRoleArn"`
}

func Handle(ctx context.Context, event Event) error {
	l := logger.WithField("event", event)
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}
	// Step Function
	client := sfn.NewFromConfig(cfg)

	// Get SFN Token
	tokenDB := databases.NewTokenTableClient(cfg, sfnTokenTableName, l)
	token, err := tokenDB.GetSFNToken(ctx, event.UserMetadata.SFNName)
	if err != nil {
		l.WithError(err).Error("Get SFN Token Error")
		return err
	}

	// Handle the MediaConvert Job Failure
	if event.Status == "ERROR" {
		_, err := client.SendTaskFailure(ctx, &sfn.SendTaskFailureInput{
			TaskToken: aws.String(token),
			Error:     aws.String("ERROR"),
			Cause:     aws.String("MediaConvert Job Error"),
		})
		if err != nil {
			logger.WithError(err).Error("SendFailure to SFN Error")
			return err
		}
		return nil
	}

	// Fomulate Output
	output, _ := json.Marshal(Output{
		event,
		MediaPackageInput{
			ID:               event.UserMetadata.ContentID,
			PackagingGroupID: mediaPackagingGroupID,
			SourceARN:        utils.GetS3OutputM3U8Arn(event.UserMetadata.DestBucket, event.UserMetadata.ContentID),
			SourceRoleARN:    mediaPackagingARN,
		},
	})

	resp, err := client.SendTaskSuccess(ctx, &sfn.SendTaskSuccessInput{
		TaskToken: aws.String(token),
		Output:    aws.String(string(output)),
	})
	if err != nil {
		logger.WithError(err).Error("SendTaskSuccess to SFN Error")
		return err
	}
	logger.WithField("sfnResponse", resp).Info("SendTaskSuccess OK")
	return nil
}

func main() {
	lambda.Start(Handle)
}

func init() {
	// Load Env
	sfnTokenTableName = os.Getenv("DYNAMODB_SFN_TOKEN_TABLE_NAME")
	mediaPackagingGroupID = os.Getenv("EMP_PACKING_GROUP_ID")
	mediaPackagingARN = os.Getenv("EMP_PACKING_ARN")
	// Prepare Logger
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
}
