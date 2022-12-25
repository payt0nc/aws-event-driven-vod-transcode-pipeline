package main

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/sirupsen/logrus"
)

var (
	AppName string
	logger  *logrus.Logger
)

type Event struct {
	ReportType   ReportType `json:"reportType"`
	PipelineName string     `json:"pipelineName"`
	JobID        string     `json:"jobID"`
	Status       string     `json:"status"`
	Input        string     `json:"input"`
	Output       string     `json:"output"`
}

type ReportType string

const (
	EncodingReport ReportType = "encoding"
)

func HandleMessage(ctx context.Context, event Event) error {
	// Load Env Var
	slackEndpoint := os.Getenv("SLACK_NOTIFICATION_ENDPOINT")
	if len(slackEndpoint) == 0 {
		panic("empty slack endpoint")
	}
	l := logger.WithContext(ctx).WithField("event", event)
	l.Info("Lambda Start")

	// Render Message
	msg := getMessage(event)

	// Send Message
	client := &http.Client{}
	req, err := http.NewRequest("POST", slackEndpoint, bytes.NewBuffer(msg))
	if err != nil {
		l.WithError(err).Error("request error")
		return err
	}

	req.Header.Add("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		l.WithError(err).Error("response error")
		return err
	}
	l.WithFields(logrus.Fields{"response": resp.Body, "status": resp.Status}).Info("Lambda End")
	return nil
}

func getMessage(event Event) []byte {
	switch event.ReportType {
	case EncodingReport:
		report := RenderStatusMessage(event)
		msgBody, _ := json.Marshal(report)
		return msgBody
	default:
		return nil
	}
}

func main() {
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
	lambda.Start(HandleMessage)
}
