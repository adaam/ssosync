OUTPUT = main # Referenced as Handler in template.yaml
RELEASER = goreleaser
PACKAGED_TEMPLATE = packaged.yaml
STACK_NAME := $(STACK_NAME)
S3_BUCKET := $(S3_BUCKET)
TEMPLATE = template.yaml
APP_NAME ?= ssosync


.PHONY: test
test:
	go test ./...

.PHONY: go-build
go-build:
	go build -o $(APP_NAME) main.go

.PHONY: clean
clean:
	rm -f $(OUTPUT) $(PACKAGED_TEMPLATE)

.PHONY: install
install:
	go get ./...

main: main.go
	goreleaser build --snapshot --rm-dist

# compile the code to run in Lambda (local or real)
.PHONY: lambda
lambda:
	$(MAKE) main

.PHONY: build
build: clean lambda

.PHONY: api
api: build
	sam local start-api

.PHONY: publish
publish:
	sam publish -t packaged.yaml

.PHONY: package
package: build
	sam package  --s3-bucket $(S3_BUCKET) --output-template-file $(PACKAGED_TEMPLATE) --s3-bucket $(S3_BUCKET)

.PHONY: deploy
deploy: package
	sam deploy --stack-name $(STACK_NAME) --template-file $(PACKAGED_TEMPLATE) --capabilities CAPABILITY_IAM
