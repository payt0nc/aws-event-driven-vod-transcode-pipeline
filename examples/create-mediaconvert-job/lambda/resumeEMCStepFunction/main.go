package main

import (
	"context"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sfn"
	"github.com/sirupsen/logrus"
)

var (
	logger *logrus.Logger
)

type Event struct {
}

func HandleResumeStepFunction(ctx context.Context, event Event) error {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}

	client := sfn.NewFromConfig(cfg)

	status := true
	switch status {
	case true:
		client.SendTaskSuccess(ctx, &sfn.SendTaskSuccessInput{
			Output:    aws.String(""),
			TaskToken: aws.String(""),
		})

	case false:
		client.SendTaskFailure(ctx, &sfn.SendTaskFailureInput{
			Cause:     aws.String(""),
			Error:     aws.String(""),
			TaskToken: aws.String(""),
		})
	}
	return nil
}

func main() {
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
	lambda.Start(HandleResumeStepFunction)
}
