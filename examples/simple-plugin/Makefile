.PHONY: build clean install test

# Plugin name
PLUGIN_NAME := simple-plugin

# Build the plugin
build:
	@echo "Building plugin: $(PLUGIN_NAME)"
	CGO_ENABLED=1 go build -buildmode=plugin -o $(PLUGIN_NAME).so .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(PLUGIN_NAME).so

# Install plugin to yapay plugins directory
install: build
	@echo "Installing plugin to yapay..."
	mkdir -p ../../plugins/$(PLUGIN_NAME)
	cp $(PLUGIN_NAME).so ../../plugins/$(PLUGIN_NAME)/
	cp config.yaml ../../plugins/$(PLUGIN_NAME)/
	@echo "Plugin installed successfully"

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Development workflow
dev: clean build install
	@echo "Plugin built and installed for development"

# Help
help:
	@echo "Available targets:"
	@echo "  build   - Build the plugin (.so file)"
	@echo "  clean   - Clean build artifacts"
	@echo "  install - Build and install plugin to yapay"
	@echo "  test    - Run tests"
	@echo "  dev     - Development workflow (clean + build + install)"
	@echo "  help    - Show this help"
