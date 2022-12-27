package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	dnmTypes "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/mediaconvert"
	emcTypes "github.com/aws/aws-sdk-go-v2/service/mediaconvert/types"
	"github.com/sirupsen/logrus"
)

var (
	logger *logrus.Logger
)

type Event struct {
	Task    Task    `json:"task"`
	SfnInfo SfnInfo `json:"sfnInfo"`
}

type Task struct {
	Bucket string `json:"bucket"`
	Object string `json:"object"`
}

type SfnInfo struct {
	Token string `json:"token"`
}

type StateRecord struct {
	EMCJobId    string `json:"emcJobID"`
	EMCProgress string `json:"emcProgress"`
	Input       string `json:"input"`
	Output      string `json:"output"`
	CreatedAt   string `json:"createdAt"`
}

func HandleCreateEMCJob(ctx context.Context, event Event) error {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}

	// Env
	stateTableName := os.Getenv("DYNAMODB_STATE_TABLE_NAME")
	role := os.Getenv("EMC_ROLE")
	queue := os.Getenv("EMC_QUEUE")

	// Parse Event
	input := fmt.Sprintf("s3://%s/%s", event.Task.Bucket, event.Task.Object)
	output := fmt.Sprintf("s3://%s/%s/", "hpchan-poc-video-output", event.Task.Object)

	// Create Elemental MediaConvert Job
	emc := mediaconvert.NewFromConfig(cfg)
	jobSpec := CreateJobSpec(input, output, queue, role)
	result, err := emc.CreateJob(ctx, jobSpec)
	if err != nil {
		return err
	}

	// Insert DynamoDB
	stateDB := dynamodb.NewFromConfig(cfg)
	record := CreateDynamodbInput(stateTableName, input, output, *result.Job.Id)
	if _, err := stateDB.PutItem(ctx, record); err != nil {
		return err
	}
	return nil

}

func CreateJobSpec(input string, output string, queue string, roleArn string) *mediaconvert.CreateJobInput {
	return &mediaconvert.CreateJobInput{
		AccelerationSettings: &emcTypes.AccelerationSettings{
			Mode: emcTypes.AccelerationModeDisabled,
		},
		Queue:       &queue,
		Role:        &roleArn,
		JobTemplate: aws.String("HEVC File Output"),
		Settings: &emcTypes.JobSettings{
			Inputs: []emcTypes.Input{
				{
					AudioSelectors: map[string]emcTypes.AudioSelector{
						"Audio Selector 1": {
							DefaultSelection: emcTypes.AudioDefaultSelectionDefault,
						},
					},
					VideoSelector:  &emcTypes.VideoSelector{},
					TimecodeSource: emcTypes.InputTimecodeSourceZerobased,
					FileInput:      aws.String(input),
				},
			},
			OutputGroups: []emcTypes.OutputGroup{
				{
					Name: aws.String("File Group"),
					Outputs: []emcTypes.Output{
						{
							Preset: aws.String("System-Generic_Hd_Mp4_Hevc_Aac_16x9_1920x1080p_50Hz_6Mbps"),
						},
					},
					OutputGroupSettings: &emcTypes.OutputGroupSettings{
						FileGroupSettings: &emcTypes.FileGroupSettings{
							Destination: aws.String(output),
						},
					},
				},
			},
		},
	}
}

func CreateDynamodbInput(tableName, input, output, jobID string) *dynamodb.PutItemInput {
	return &dynamodb.PutItemInput{
		TableName: &tableName,
		Item: map[string]dnmTypes.AttributeValue{
			"emcJobID":    dnmTypes.AttributeValueMemberS{Value: jobID},
			"emcProgress": dnmTypes.AttributeValueMemberS{Value: "Kick Off"},
			"input":       dnmTypes.AttributeValueMemberS{Value: input},
			"output":      dnmTypes.AttributeValueMemberS{Value: output},
			"createdAt":   dnmTypes.AttributeValueMemberN{Value: time.Now().Format("2006-01-02T15:04:05-0700")},
		},
	}
}

func main() {
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
	lambda.Start(HandleCreateEMCJob)
}
