# YAPAY SDK Makefile
# Provides consistent plugin building using the same builder image as the main yapay project

.PHONY: help build-plugins build-plugin-% build-examples clean check-compatibility test test-plugins test-tools build-tools tunnel tunnel-start tunnel-stop tunnel-status tunnel-url debug-plugin debug-plugin-% tools build-plugin-debug

# Configuration
PLUGINS_DIR := examples
OUTPUT_DIR := plugins
TOOLS_DIR := tools
DOCKER_IMAGE := metalmon/yapay
BUILDER_TAG := builder

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Show help
help:
	@echo "$(GREEN)YAPAY SDK Development Tools$(NC)"
	@echo ""
	@echo "$(YELLOW)Plugin management:$(NC)"
	@echo "  new-plugin-NAME      - Create new plugin from template"
	@echo "  build-plugins        - Build all plugins from src/ directory"
	@echo "  build-examples       - Build all example plugins (for testing/demo)"
	@echo "  build-plugin-NAME    - Build specific plugin (auto-detects environment)"
	@echo "  check-compatibility  - Check development environment compatibility"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  test                 - Run all tests (plugins + tools)"
	@echo "  test-plugins         - Test all plugins"
	@echo "  test-tools           - Test all tools"
	@echo ""
	@echo "$(YELLOW)Tools:$(NC)"
	@echo "  build-tools          - Build all development tools"
	@echo "  build-plugin-debug   - Build plugin debug tool"
	@echo "  debug-plugin-NAME    - Debug specific plugin"
	@echo ""
	@echo "$(YELLOW)CloudPub tunnel (webhook testing):$(NC)"
	@echo "  tunnel               - Start CloudPub tunnel"
	@echo "  tunnel-start         - Start CloudPub tunnel"
	@echo "  tunnel-stop          - Stop CloudPub tunnel"
	@echo "  tunnel-status        - Show tunnel status"
	@echo "  tunnel-url           - Get tunnel URL"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  clean                - Clean build artifacts"
	@echo "  tools                - Alias for build-tools"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make new-plugin-my-plugin"
	@echo "  make build-plugin-my-plugin"
	@echo "  make test"
	@echo "  make debug-plugin-my-plugin"
	@echo "  make tunnel-start"

# Build all plugins from src/ directory only
build-plugins:
	@printf "$(BLUE)--- Building all plugins from src/ (smart environment detection) ---$(NC)\n"
	@mkdir -p $(OUTPUT_DIR)
	@if [ ! -d "src" ]; then \
		printf "$(YELLOW)No src/ directory found. Creating it...$(NC)\n"; \
		mkdir -p src; \
	fi; \
	for plugin_dir in src/*; do \
		if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			printf "$(YELLOW)Building plugin: $$plugin_name$(NC)\n"; \
			mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
			rm -f "$$plugin_dir/$$plugin_name.so"; \
			$(MAKE) build-plugin-$$plugin_name; \
			printf "$(GREEN)Plugin $$plugin_name copied to output directory$(NC)\n"; \
		fi; \
	done; \
	if [ ! -d "src" ] || [ -z "$$(ls -A src 2>/dev/null)" ]; then \
		printf "$(YELLOW)No plugins found in src/. Examples are in examples/ directory.$(NC)\n"; \
		printf "$(YELLOW)To build examples, copy them to src/ first:$(NC)\n"; \
		printf "$(YELLOW)  cp -r examples/simple-plugin src/my-plugin$(NC)\n"; \
	fi
	@printf "$(GREEN)All plugins from src/ built successfully!$(NC)\n"

# Build all example plugins (for testing/demo purposes)
build-examples:
	@printf "$(BLUE)--- Building all example plugins (for testing/demo) ---$(NC)\n"
	@mkdir -p $(OUTPUT_DIR)
	@for plugin_dir in $(PLUGINS_DIR)/*; do \
		if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			printf "$(YELLOW)Building example plugin: $$plugin_name$(NC)\n"; \
			mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
			rm -f "$$plugin_dir/$$plugin_name.so"; \
			$(MAKE) build-plugin-examples-$$plugin_name; \
			printf "$(GREEN)Example plugin $$plugin_name copied to output directory$(NC)\n"; \
		fi; \
	done
	@printf "$(GREEN)All example plugins built successfully!$(NC)\n"

# Build individual plugin using smart environment detection
build-plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name (smart environment detection)...$(NC)\n"; \
	if [ -d "src/$$plugin_name" ]; then \
		printf "$(YELLOW)Found plugin in src/ directory$(NC)\n"; \
		$(MAKE) build-plugin-src-$$plugin_name; \
	elif [ -d "$(PLUGINS_DIR)/$$plugin_name" ]; then \
		printf "$(YELLOW)Found plugin in examples/ directory (deprecated - copy to src/ first)$(NC)\n"; \
		printf "$(YELLOW)To use examples, copy them to src/: cp -r examples/$$plugin_name src/$$plugin_name$(NC)\n"; \
		$(MAKE) build-plugin-examples-$$plugin_name; \
	else \
		printf "$(RED)Error: Plugin $$plugin_name not found in src/ or examples/$(NC)\n"; \
		printf "$(YELLOW)Available examples:$(NC)\n"; \
		ls -1 examples/ 2>/dev/null | sed 's/^/  /' || printf "$(YELLOW)  (no examples found)$(NC)\n"; \
		printf "$(YELLOW)Copy an example to src/: cp -r examples/simple-plugin src/my-plugin$(NC)\n"; \
		exit 1; \
	fi

# Build plugin from src/ directory
build-plugin-src-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin from src/: $$plugin_name$(NC)\n"; \
	if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - building plugin directly$(NC)\n"; \
		(cd "src/$$plugin_name" && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
			-mod=mod \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags="-w -s" \
			-o $$plugin_name.so \
			.); \
		mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
		cp "src/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
	else \
		printf "$(YELLOW)Using builder image for compatibility$(NC)\n"; \
		if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
			printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
			docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
			(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
			 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
			 printf "$(YELLOW)  or build it locally: cd ../yapay && make build-builder$(NC)\n"; \
			 exit 1); \
		fi; \
		docker run --rm \
			-v $(PWD):/workspace \
			-w /workspace/src/$$plugin_name \
			$(DOCKER_IMAGE):$(BUILDER_TAG) \
			sh -c 'CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
				-mod=mod \
				-buildmode=plugin \
				-buildvcs=false \
				-ldflags="-w -s" \
				-o '$$plugin_name.so' \
				.'; \
		mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
		cp "src/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
		if [ -f "src/$$plugin_name/config.yaml" ]; then \
			cp "src/$$plugin_name/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
		fi; \
	fi; \
	printf "$(GREEN)Plugin $$plugin_name built successfully from src/!$(NC)\n"

# Build plugin from examples/ directory
build-plugin-examples-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin from examples/: $$plugin_name$(NC)\n"; \
	if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - building plugin directly$(NC)\n"; \
		(cd "$(PLUGINS_DIR)/$$plugin_name" && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
			-mod=mod \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags="-w -s" \
			-o $$plugin_name.so \
			.); \
		mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
		cp "$(PLUGINS_DIR)/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
	else \
		printf "$(YELLOW)Using builder image for compatibility$(NC)\n"; \
		if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
			printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
			docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
			(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
			 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
			 printf "$(YELLOW)  or build it locally: cd ../yapay && make build-builder$(NC)\n"; \
			 exit 1); \
		fi; \
		docker run --rm \
			-v $(PWD):/workspace \
			-w /workspace/$(PLUGINS_DIR)/$$plugin_name \
			$(DOCKER_IMAGE):$(BUILDER_TAG) \
			sh -c 'CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
				-mod=mod \
				-buildmode=plugin \
				-buildvcs=false \
				-ldflags="-w -s" \
				-o '$$plugin_name.so' \
				.'; \
		mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
		cp "$(PLUGINS_DIR)/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
		if [ -f "$(PLUGINS_DIR)/$$plugin_name/config.yaml" ]; then \
			cp "$(PLUGINS_DIR)/$$plugin_name/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
		fi; \
	fi; \
	printf "$(GREEN)Plugin $$plugin_name built successfully from examples/!$(NC)\n"

# Build plugin directly in Alpine environment (when already in Alpine container)
build-plugin-alpine-%:
	@plugin_name=$*; \
	plugin_dir=$${PLUGIN_DIR:-$(PLUGINS_DIR)/$$plugin_name}; \
	printf "$(GREEN)Building plugin: $$plugin_name in Alpine environment...$(NC)\n"; \
	if [ ! -d "$$plugin_dir" ]; then \
		printf "$(RED)Error: Plugin directory $$plugin_dir not found.$(NC)\n"; \
		exit 1; \
	fi; \
	(cd "$$plugin_dir" && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
		-mod=mod \
		-buildmode=plugin \
		-buildvcs=false \
		-ldflags="-w -s" \
		-o $$plugin_name.so \
		.); \
	mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
	cp "$$plugin_dir/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
	printf "$(GREEN)Plugin $$plugin_name built successfully in Alpine environment!$(NC)\n"

# Build plugin via builder image (when not in Alpine or on host)
build-plugin-via-builder-%:
	@plugin_name=$*; \
	plugin_dir=$${PLUGIN_DIR:-$(PLUGINS_DIR)/$$plugin_name}; \
	printf "$(GREEN)Building plugin: $$plugin_name using builder image...$(NC)\n"; \
	if [ ! -d "$$plugin_dir" ]; then \
		printf "$(RED)Error: Plugin directory $$plugin_dir not found.$(NC)\n"; \
		exit 1; \
	fi; \
	printf "$(YELLOW)Ensuring builder image is available...$(NC)\n"; \
	if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
		printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
		docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
		(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
		 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
		 printf "$(YELLOW)  or build it locally: cd ../yapay && make build-builder$(NC)\n"; \
		 exit 1); \
	fi; \
	printf "$(YELLOW)Building plugin $$plugin_name in builder container...$(NC)\n"; \
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace/$$plugin_dir \
		$(DOCKER_IMAGE):$(BUILDER_TAG) \
		sh -c 'CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
			-mod=mod \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags="-w -s" \
			-o '$$plugin_name.so' \
			.'; \
	mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
	cp "$$plugin_dir/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
	printf "$(GREEN)Plugin $$plugin_name built successfully!$(NC)\n"

# Clean build artifacts
clean:
	@printf "$(YELLOW)Cleaning build artifacts...$(NC)\n"
	rm -rf $(OUTPUT_DIR)
	@for plugin_dir in $(PLUGINS_DIR)/*; do \
		if [ -d "$$plugin_dir" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			rm -f $$plugin_dir/*.so; \
		fi; \
	done
	@printf "$(GREEN)Clean completed!$(NC)\n"

# Check environment compatibility
check-compatibility:
	@printf "$(GREEN)Checking development environment compatibility...$(NC)\n"
	@printf "$(YELLOW)Environment detection:$(NC)\n"
	@if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(GREEN)  ✓ Running in Alpine devcontainer - direct build available$(NC)\n"; \
		printf "$(YELLOW)  Go version:$(NC)\n"; \
		go version; \
	elif [ -f /.dockerenv ]; then \
		printf "$(YELLOW)  ✓ Running in Docker container - builder image will be used$(NC)\n"; \
		printf "$(YELLOW)  Checking builder image availability...$(NC)\n"; \
		if docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
			printf "$(GREEN)  ✓ Builder image found locally$(NC)\n"; \
		else \
			printf "$(YELLOW)  ⚠ Builder image will be pulled when needed$(NC)\n"; \
		fi; \
	else \
		printf "$(YELLOW)  ✓ Running on host - builder image will be used$(NC)\n"; \
		printf "$(YELLOW)  Checking Docker availability...$(NC)\n"; \
		if command -v docker >/dev/null 2>&1; then \
			printf "$(GREEN)  ✓ Docker is available$(NC)\n"; \
			if docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
				printf "$(GREEN)  ✓ Builder image found locally$(NC)\n"; \
			else \
				printf "$(YELLOW)  ⚠ Builder image will be pulled when needed$(NC)\n"; \
			fi; \
		else \
			printf "$(RED)  ✗ Docker is not available$(NC)\n"; \
			printf "$(RED)Please install Docker to use the SDK$(NC)\n"; \
		exit 1; \
		fi; \
	fi
	@printf "$(GREEN)Environment compatibility check completed!$(NC)\n"

# Test commands
test: test-plugins test-tools
	@printf "$(GREEN)All tests completed!$(NC)\n"

# Test plugins
test-plugins:
	@printf "$(GREEN)Testing plugins...$(NC)\n"
	@for plugin_dir in $(PLUGINS_DIR)/*; do \
		if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			printf "$(YELLOW)Testing plugin: $$plugin_name$(NC)\n"; \
			(cd "$$plugin_dir" && go test -v ./... || printf "$(RED)Plugin $$plugin_name tests failed$(NC)\n"); \
		fi; \
	done

# Test tools
test-tools:
	@printf "$(GREEN)Testing tools...$(NC)\n"
	@for tool_dir in $(TOOLS_DIR)/*; do \
		if [ -d "$$tool_dir" ] && [ -f "$$tool_dir/go.mod" ]; then \
			tool_name=$$(basename "$$tool_dir"); \
			printf "$(YELLOW)Testing tool: $$tool_name$(NC)\n"; \
			(cd "$$tool_dir" && go test -v ./... || printf "$(RED)Tool $$tool_name tests failed$(NC)\n"); \
		fi; \
	done

# Build tools
build-tools:
	@printf "$(GREEN)Building development tools...$(NC)\n"
	@for tool_dir in $(TOOLS_DIR)/*; do \
		if [ -d "$$tool_dir" ] && [ -f "$$tool_dir/go.mod" ]; then \
			tool_name=$$(basename "$$tool_dir"); \
			printf "$(YELLOW)Building tool: $$tool_name$(NC)\n"; \
			$(MAKE) build-tool-$$tool_name; \
		fi; \
	done
	@printf "$(GREEN)All tools built successfully!$(NC)\n"

# Build individual tool
build-tool-%:
	@tool_name=$*; \
	printf "$(GREEN)Building tool: $$tool_name...$(NC)\n"; \
	if [ ! -d "$(TOOLS_DIR)/$$tool_name" ]; then \
		printf "$(RED)Error: Tool directory $(TOOLS_DIR)/$$tool_name not found.$(NC)\n"; \
		exit 1; \
	fi; \
	(cd "$(TOOLS_DIR)/$$tool_name" && go build -o $$tool_name .); \
	printf "$(GREEN)Tool $$tool_name built successfully!$(NC)\n"

# Build plugin debug tool specifically
build-plugin-debug:
	@printf "$(GREEN)Building plugin debug tool...$(NC)\n"
	@$(MAKE) build-tool-plugin-debug

# CloudPub tunnel commands (for webhook testing)
tunnel: tunnel-start

# Start CloudPub tunnel
tunnel-start:
	@printf "$(GREEN)Starting CloudPub tunnel for webhook testing...$(NC)\n"
	@if command -v clo >/dev/null 2>&1; then \
		clo start --background; \
		printf "$(GREEN)CloudPub tunnel started successfully!$(NC)\n"; \
	else \
		printf "$(RED)CloudPub tunnel not available - install it first$(NC)\n"; \
		printf "$(YELLOW)CloudPub is installed in the devcontainer$(NC)\n"; \
	fi

# Stop CloudPub tunnel
tunnel-stop:
	@printf "$(YELLOW)Stopping CloudPub tunnel...$(NC)\n"
	@if command -v clo >/dev/null 2>&1; then \
		clo stop; \
		printf "$(GREEN)CloudPub tunnel stopped successfully!$(NC)\n"; \
	else \
		printf "$(YELLOW)CloudPub tunnel not available$(NC)\n"; \
	fi

# Show CloudPub tunnel status
tunnel-status:
	@printf "$(GREEN)Checking CloudPub tunnel status...$(NC)\n"
	@if command -v clo >/dev/null 2>&1; then \
		clo status; \
	else \
		printf "$(YELLOW)CloudPub tunnel not available$(NC)\n"; \
	fi

# Get CloudPub tunnel URL
tunnel-url:
	@printf "$(GREEN)Getting CloudPub tunnel URL...$(NC)\n"
	@if command -v clo >/dev/null 2>&1; then \
		clo url; \
	else \
		printf "$(YELLOW)CloudPub tunnel not available$(NC)\n"; \
	fi

# Debug plugin using plugin-debug tool
debug-plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Debugging plugin: $$plugin_name$(NC)\n"; \
	if [ ! -f "$(OUTPUT_DIR)/$$plugin_name/$$plugin_name.so" ]; then \
		printf "$(YELLOW)Plugin not built, building first...$(NC)\n"; \
		$(MAKE) build-plugin-$$plugin_name; \
	fi; \
	if [ ! -f "$(TOOLS_DIR)/plugin-debug/plugin-debug" ]; then \
		printf "$(YELLOW)Debug tool not built, building first...$(NC)\n"; \
		$(MAKE) build-plugin-debug; \
	fi; \
	printf "$(YELLOW)Running plugin debug tool...$(NC)\n"; \
	cd "$(TOOLS_DIR)/plugin-debug" && ./plugin-debug -plugin $$plugin_name -plugins-dir "$(PWD)/$(OUTPUT_DIR)" -test validate

# Create new plugin from template
new-plugin-%:
	@plugin_name=$*; \
	src_dir="src/$$plugin_name"; \
	if [ -d "$$src_dir" ]; then \
		printf "$(RED)Error: Plugin $$plugin_name already exists in src/$(NC)\n"; \
		exit 1; \
	fi; \
	printf "$(GREEN)Creating new plugin: $$plugin_name in src/$(NC)\n"; \
	mkdir -p "$$src_dir"; \
	cp -r "$(PLUGINS_DIR)/simple-plugin/"* "$$src_dir/"; \
	sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/go.mod"; \
	sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/Makefile"; \
	sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/README.md"; \
	sed -i "s/SimplePlugin/$$(echo $$plugin_name | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')/g" "$$src_dir/main.go"; \
	sed -i "s/SimpleGenerator/$$(echo $$plugin_name | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/')Generator/g" "$$src_dir/main.go"; \
	printf "$(GREEN)Plugin $$plugin_name created successfully in src/!$(NC)\n"; \
	printf "$(YELLOW)Next steps:$(NC)\n"; \
	printf "$(YELLOW)  1. Edit src/$$plugin_name/main.go$(NC)\n"; \
	printf "$(YELLOW)  2. Edit src/$$plugin_name/config.yaml$(NC)\n"; \
	printf "$(YELLOW)  3. Run: make build-plugin-$$plugin_name$(NC)\n"; \
	printf "$(YELLOW)  4. Add to Git: git add src/$$plugin_name/$(NC)\n"

# Tools command (alias for build-tools)
tools: build-tools