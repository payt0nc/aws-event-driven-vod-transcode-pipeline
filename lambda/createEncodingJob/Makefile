# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0

.PHONY: all

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o createEncodingJob .
pack:
	@zip createEncodingJob.zip createEncodingJob
upload:
	@aws s3 cp createEncodingJob.zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/createEncodingJob.zip"
clean:
	rm -f createEncodingJob createEncodingJob.zip
all: build pack upload clean