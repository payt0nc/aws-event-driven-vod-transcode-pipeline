# Build Vars

GOOS = linux
GOARCH = amd64
CGO_ENABLED = 0
FUNCTION_NAME = "slackMessager"

build:
	@GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o $(FUNCTION_NAME) .
pack:
	@zip $(FUNCTION_NAME).zip $(FUNCTION_NAME)
upload:
	@aws s3 cp $(FUNCTION_NAME).zip "s3://$(S3_BUCKET)/vod-encoding-pipeline/$(FUNCTION_NAME).zip"
clean:
	rm -f $(FUNCTION_NAME) $(FUNCTION_NAME).zip