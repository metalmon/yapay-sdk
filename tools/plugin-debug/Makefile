.PHONY: build clean test help

# Build the plugin debug tool
build:
	@echo "Building plugin debug tool..."
	CGO_ENABLED=1 go build -o plugin-debug .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f plugin-debug

# Test the debug tool with example plugin
test: build
	@echo "Testing with simple plugin..."
	cd ../../examples/simple-plugin && make build
	./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test validate -plugins-dir ../../examples/simple-plugin

# Test simulation
test-simulate: build
	@echo "Running simulation test..."
	cd ../../examples/simple-plugin && make build
	./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test simulate -verbose -plugins-dir ../../examples/simple-plugin

# Test benchmark
test-benchmark: build
	@echo "Running benchmark test..."
	cd ../../examples/simple-plugin && make build
	./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test benchmark -plugins-dir ../../examples/simple-plugin

# Install to /usr/local/bin
install: build
	@echo "Installing plugin-debug..."
	sudo cp plugin-debug /usr/local/bin/
	@echo "Plugin debug tool installed successfully"

# Help
help:
	@echo "Available targets:"
	@echo "  build          - Build the plugin debug tool"
	@echo "  clean          - Clean build artifacts"
	@echo "  test           - Test with simple plugin (validation)"
	@echo "  test-simulate  - Test with simple plugin (simulation)"
	@echo "  test-benchmark - Test with simple plugin (benchmark)"
	@echo "  install        - Install to /usr/local/bin"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Usage examples:"
	@echo "  ./plugin-debug -plugin swschool -test validate"
	@echo "  ./plugin-debug -plugin swschool -config path/to/config.yaml -test simulate -verbose"
	@echo "  ./plugin-debug -plugin swschool -test benchmark"
