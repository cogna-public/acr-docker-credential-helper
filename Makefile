.PHONY: build build-static test clean install image help

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
DATE    ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LDFLAGS        := -ldflags "-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)"
STATIC_LDFLAGS := -ldflags "-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE) -extldflags '-static'"

# Binary names
BINARY_NAME := docker-credential-acr
BUILD_DIR   := bin
IMAGE       := $(BINARY_NAME):dev

help:
	@echo "Available targets:"
	@echo "  build         - Build the binary for current platform"
	@echo "  build-static  - Build statically-linked binaries for all platforms"
	@echo "  test          - Run tests"
	@echo "  image         - Build container image"
	@echo "  clean         - Clean build artifacts"
	@echo "  install       - Install binary to ~/bin"
	@echo "  help          - Show this help message"

build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) .

build-static:
	@echo "Building statically-linked binaries..."
	@mkdir -p $(BUILD_DIR)
	@echo "  -> Linux AMD64"
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a $(STATIC_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	@echo "  -> Linux ARM64"
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a $(STATIC_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 .
	@echo "  -> macOS AMD64"
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -a $(STATIC_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	@echo "  -> macOS ARM64"
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -a $(STATIC_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .
	@echo "Done! Binaries are in $(BUILD_DIR)/"

install: build
	cp $(BUILD_DIR)/$(BINARY_NAME) ~/bin/ && chmod +x ~/bin/$(BINARY_NAME)

image:
	podman build -t $(IMAGE) .

test:
	@echo "Running tests..."
	go vet ./...
	go test -v -race -coverprofile=coverage.out ./...

clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out

fmt:
	@echo "Formatting code..."
	go fmt ./...

lint:
	@echo "Linting code..."
	golangci-lint run ./...

.DEFAULT_GOAL := help
