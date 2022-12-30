# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0

.PHONY: all

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o resumeSFN .
pack:
	@zip resumeSFN.zip resumeSFN
upload:
	@aws s3 cp resumeSFN.zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/resumeSFN.zip"
clean:
	@rm -f resumeSFN resumeSFN.zip
all: build pack upload clean