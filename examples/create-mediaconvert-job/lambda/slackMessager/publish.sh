#!/bin/bash

export AWS_PROFILE=hpchan
AWS_ACCOUNT_ID=$1

aws lambda delete-function --function-name slackMessager
rm slackMessager.zip slackMessager
GOOS=linux GOARCH=amd64 go build -o slackMessager .
zip slackMessager.zip slackMessager

aws lambda create-function \
    --function-name slackMessager \
    --runtime go1.x \
    --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/slack_messager \
    --handler slackMessager \
    --zip-file fileb://slackMessager.zip
