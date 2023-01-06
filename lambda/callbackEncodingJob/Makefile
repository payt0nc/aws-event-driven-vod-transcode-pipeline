# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0

.PHONY: all

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o callbackEncodingJob .
pack:
	@zip callbackEncodingJob.zip callbackEncodingJob
upload:
	@aws s3 cp callbackEncodingJob.zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/callbackEncodingJob.zip"
clean:
	@rm -f callbackEncodingJob callbackEncodingJob.zip
all: build pack upload clean