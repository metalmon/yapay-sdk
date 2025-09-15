.PHONY: help build test clean install-deps lint

# Default target
help:
	@echo "Yapay Plugin Development Kit"
	@echo ""
	@echo "Available targets:"
	@echo "  help         - Show this help message"
	@echo "  build        - Build all examples"
	@echo "  test         - Run tests for all examples"
	@echo "  clean        - Clean build artifacts"
	@echo "  install-deps - Install development dependencies"
	@echo "  lint         - Run linter on all code"
	@echo "  sdk-build    - Build SDK"
	@echo "  sdk-test     - Test SDK"
	@echo "  tools-build  - Build development tools"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    # Build all examples"
	@echo "  make test                     # Test all examples"
	@echo "  make -C examples/simple-plugin build  # Build specific plugin"

# Build all examples
build:
	@echo "Building all examples..."
	@for example in examples/*/; do \
		if [ -f "$$example/Makefile" ]; then \
			echo "Building $$example..."; \
			$(MAKE) -C "$$example" build; \
		fi; \
	done

# Test all examples
test:
	@echo "Testing all examples..."
	@for example in examples/*/; do \
		if [ -f "$$example/Makefile" ]; then \
			echo "Testing $$example..."; \
			$(MAKE) -C "$$example" test; \
		fi; \
	done

# Clean all build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@for example in examples/*/; do \
		if [ -f "$$example/Makefile" ]; then \
			echo "Cleaning $$example..."; \
			$(MAKE) -C "$$example" clean; \
		fi; \
	done
	@$(MAKE) -C tools/plugin-debug clean

# Install development dependencies
install-deps:
	@echo "Installing development dependencies..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run linter on all code
lint:
	@echo "Running linter..."
	golangci-lint run ./...

# Build SDK
sdk-build:
	@echo "Building SDK..."
	@go mod tidy
	@go build ./...

# Test SDK
sdk-test:
	@echo "Testing SDK..."
	@go test ./...

# Build development tools
tools-build:
	@echo "Building development tools..."
	@$(MAKE) -C tools/plugin-debug build

# Create new plugin from template
new-plugin:
	@if [ -z "$(NAME)" ]; then \
		echo "Usage: make new-plugin NAME=my-plugin"; \
		exit 1; \
	fi; \
	if [ -d "examples/$(NAME)" ]; then \
		echo "Error: Plugin '$(NAME)' already exists"; \
		exit 1; \
	fi; \
	echo "Creating new plugin: $(NAME)"; \
	cp -r examples/simple-plugin examples/$(NAME); \
	cd examples/$(NAME) && \
	sed -i "s/simple-plugin/$(NAME)/g" go.mod && \
	sed -i "s/Simple Plugin Example/$(NAME)/g" config.yaml && \
	sed -i "s/simple-plugin/$(NAME)/g" Makefile && \
	echo "Plugin '$(NAME)' created in examples/$(NAME)/"

# Check if all examples build successfully
check-all:
	@echo "Checking all examples..."
	@$(MAKE) build
	@$(MAKE) test
	@echo "✅ All examples build and test successfully"

# Update SDK dependencies
update-sdk-deps:
	@echo "Updating SDK dependencies..."
	@go get -u ./...
	@go mod tidy
