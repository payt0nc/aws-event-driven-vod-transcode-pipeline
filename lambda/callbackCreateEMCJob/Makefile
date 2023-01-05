# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0

.PHONY: all

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o callbackCreateEMCJob .
pack:
	@zip callbackCreateEMCJob.zip callbackCreateEMCJob
upload:
	@aws s3 cp callbackCreateEMCJob.zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/callbackCreateEMCJob.zip"
clean:
	@rm -f callbackCreateEMCJob callbackCreateEMCJob.zip
all: build pack upload clean