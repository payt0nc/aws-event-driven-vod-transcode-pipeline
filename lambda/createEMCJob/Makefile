# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0

.PHONY: all

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o createEMCJob .
pack:
	@zip createEMCJob.zip createEMCJob
upload:
	@aws s3 cp createEMCJob.zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/createEMCJob.zip"
clean:
	rm -f createEMCJob createEMCJob.zip
all: build pack upload clean