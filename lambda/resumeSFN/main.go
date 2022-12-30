package main

import (
	"context"
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/sfn"
	"github.com/sirupsen/logrus"
)

var (
	logger *logrus.Logger
)

type emcStatus string

const (
	emcStatusProgressing      emcStatus = "PROGRESSING"
	emcStatusInputInformation emcStatus = "INPUT_INFORMATION"
	emcStatusComplete         emcStatus = "COMPLETE"
	emcStatusError            emcStatus = "ERROR"
)

type Event struct {
	Status emcStatus `json:"status"`
	JobID  string    `json:"jobId" dynamodbav:"emcJobId"`
}

type StateRecord struct {
	EMCJobID          string `json:"emcJobId" dynamodbav:"emcJobId"`
	StepFunctionToken string `json:"sfnToken" dynamodbav:"sfnToken"`
	CreatedAt         string `json:"createdAt" dynamodbav:"createdAt"`
}

type StepResult struct {
	EMCJobID string `json:"emcJobId`
	Status   string `json:"status"`
}

func HandleResumeSFN(ctx context.Context, event Event) error {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}

	// Env
	stateTableName := os.Getenv("DYNAMODB_STATE_TABLE_NAME")
	logger.WithField("event", event).Info("Incoming event")

	// DynamoDB
	var stateRecord StateRecord
	stateDB := dynamodb.NewFromConfig(cfg)
	input, err := createDynamodbGetItemInput(stateTableName, event.JobID)
	if err != nil {
		return err
	}
	record, err := stateDB.GetItem(ctx, input)
	if err != nil {
		logger.WithError(err).Error("Get Item Error")
		return err
	}
	attributevalue.UnmarshalMap(record.Item, &stateRecord)

	// Step Function
	client := sfn.NewFromConfig(cfg)
	resultB, _ := json.Marshal(StepResult{
		Status:   string(event.Status),
		EMCJobID: stateRecord.EMCJobID,
	})
	output, err := client.SendTaskSuccess(ctx, &sfn.SendTaskSuccessInput{
		TaskToken: aws.String(stateRecord.StepFunctionToken),
		Output:    aws.String(string(resultB)),
	})
	if err != nil {
		logger.WithError(err).Error("SendTaskSuccess to SFN Error")
		return err
	}
	logger.WithField("sfnResponse", output).Info("SendTaskSuccess OK")
	return nil
}

func createDynamodbGetItemInput(tableName, jobID string) (*dynamodb.GetItemInput, error) {
	return &dynamodb.GetItemInput{
		TableName: &tableName,
		Key: map[string]types.AttributeValue{
			"emcJobId": &types.AttributeValueMemberS{Value: jobID},
		},
	}, nil
}

func main() {
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
	lambda.Start(HandleResumeSFN)
}
