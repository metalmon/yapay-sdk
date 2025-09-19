# YAPAY SDK Makefile
# Provides consistent plugin building using the same builder image as the main yapay project

.PHONY: help build-plugins build-plugin-% clean check-compatibility test test-plugins test-tools build-tools tunnel tunnel-start tunnel-stop tunnel-status tunnel-url debug-plugin debug-plugin-% tools build-plugin-debug plugin-list plugin-reload plugin-refresh-dirs update-builder

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
	@echo "  build-plugins        - Build all plugins (universal command)"
	@echo "  build-plugin-NAME    - Build specific plugin"
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
	@echo "$(YELLOW)Server Development:$(NC)"
	@echo "  dev-server           - Start YAPAY server for development"
	@echo "  dev-watch            - Start plugin hot-reload watcher"
	@echo "  dev-stop             - Stop development server"
	@echo ""
	@echo "$(YELLOW)Plugin Management:$(NC)"
	@echo "  plugin-list          - List loaded plugins"
	@echo "  plugin-reload        - Reload plugins via API"
	@echo "  plugin-refresh-dirs  - Refresh plugin directories"
	@echo ""
	@echo "$(YELLOW)Builder Management:$(NC)"
	@echo "  update-builder       - Update builder image from registry"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  clean                - Clean build artifacts"
	@echo "  tools                - Alias for build-tools"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make new-plugin-my-plugin"
	@echo "  make build-plugin-my-plugin"
	@echo "  make dev-server      # Start server with hot-reload"
	@echo "  make dev-watch       # Watch for plugin changes"
	@echo "  make plugin-list     # List loaded plugins"
	@echo "  make test"
	@echo "  make debug-plugin-my-plugin"
	@echo "  make tunnel-start"

# Build all plugins from src/ directory only
build-plugins:
	@printf "$(BLUE)--- Building all plugins using official builder ---$(NC)\n"
	@if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
		printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
		docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
		(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
		 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
		 exit 1); \
	fi; \
	printf "$(YELLOW)Compiling all plugins inside the builder container...$(NC)\n"; \
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		-e GOPRIVATE=github.com/metalmon/yapay-sdk \
		-e GOCACHE=/tmp/go-build \
		-u $(shell id -u):$(shell id -g) \
		$(DOCKER_IMAGE):$(BUILDER_TAG) \
		sh -c 'mkdir -p plugins && \
		for plugin_dir in src/*; do \
			if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
				plugin_name=$$(basename "$$plugin_dir"); \
				printf "Building plugin: $$plugin_name\n"; \
				mkdir -p plugins/$$plugin_name; \
				rm -f "$$plugin_dir/$$plugin_name.so"; \
				(cd "$$plugin_dir" && cp /app/go.mod . && cp /app/go.sum . && cp -r /app/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
					-mod=vendor \
					-buildmode=plugin \
					-buildvcs=false \
					-ldflags="-w -s" \
					-o $$plugin_name.so \
					.); \
				cp "$$plugin_dir/$$plugin_name.so" plugins/$$plugin_name/; \
				if [ -f "$$plugin_dir/config.yaml" ]; then \
					cp "$$plugin_dir/config.yaml" plugins/$$plugin_name/; \
				fi; \
				printf "Plugin $$plugin_name built successfully!\n"; \
			fi; \
		done'; \
	printf "$(GREEN)All plugins built successfully!$(NC)\n"


# Build individual plugin using official builder
build-plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name using official builder$(NC)\n"; \
	if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
		printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
		docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
		(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
		 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
		 printf "$(YELLOW)  or build it locally: cd ../yapay && make docker-build-builder$(NC)\n"; \
		 exit 1); \
	fi; \
	printf "$(YELLOW)Compiling plugin $$plugin_name inside the builder container...$(NC)\n"; \
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace/src/$$plugin_name \
		-e GOPRIVATE=github.com/metalmon/yapay-sdk \
		-e GOCACHE=/tmp/go-build \
		-u $(shell id -u):$(shell id -g) \
		$(DOCKER_IMAGE):$(BUILDER_TAG) \
		sh -c 'cp /app/go.mod . && cp /app/go.sum . && cp -r /app/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
			-mod=vendor \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags="-w -s" \
			-o '$$plugin_name'.so \
			.'; \
	mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
	cp "src/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
	if [ -f "src/$$plugin_name/config.yaml" ]; then \
		cp "src/$$plugin_name/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
	fi; \
	printf "$(GREEN)Plugin $$plugin_name built successfully!$(NC)\n"






# Clean build artifacts
clean:
	@printf "$(YELLOW)Cleaning build artifacts...$(NC)\n"
	rm -rf $(OUTPUT_DIR)
	@for plugin_dir in src/* examples/*; do \
		if [ -d "$$plugin_dir" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			rm -f $$plugin_dir/*.so; \
			rm -rf $$plugin_dir/vendor; \
			rm -f $$plugin_dir/go.mod $$plugin_dir/go.sum; \
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

# Development server commands
.PHONY: dev-server dev-watch dev-stop

# Start YAPAY server for development
dev-server:
	@printf "$(GREEN)Starting YAPAY server for development...$(NC)\n"
	@if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - starting server directly$(NC)\n"; \
		chmod +x .devcontainer/start-server.sh; \
		.devcontainer/start-server.sh; \
	else \
		printf "$(YELLOW)Not in devcontainer - please run this inside the devcontainer$(NC)\n"; \
		printf "$(YELLOW)Use: docker-compose -f .devcontainer/docker-compose.yml up -d yapay-sdk-development$(NC)\n"; \
		printf "$(YELLOW)Then: docker exec -it yapay-sdk_devcontainer-yapay-sdk-development-1 bash$(NC)\n"; \
		exit 1; \
	fi

# Start plugin hot-reload watcher
dev-watch:
	@printf "$(GREEN)Starting plugin hot-reload watcher...$(NC)\n"
	@if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - starting watcher$(NC)\n"; \
		chmod +x .devcontainer/watch-plugins.sh; \
		.devcontainer/watch-plugins.sh; \
	else \
		printf "$(YELLOW)Not in devcontainer - please run this inside the devcontainer$(NC)\n"; \
		printf "$(YELLOW)Use: docker-compose -f .devcontainer/docker-compose.yml up -d yapay-sdk-development$(NC)\n"; \
		printf "$(YELLOW)Then: docker exec -it yapay-sdk_devcontainer-yapay-sdk-development-1 bash$(NC)\n"; \
		exit 1; \
	fi

# Stop development server
dev-stop:
	@printf "$(YELLOW)Stopping development server...$(NC)\n"
	@pkill -f "yapay" || printf "$(YELLOW)No server process found$(NC)\n"
	@pkill -f "watch-plugins" || printf "$(YELLOW)No watcher process found$(NC)\n"
	@printf "$(GREEN)Development server stopped$(NC)\n"

# Plugin management commands (for development server)
plugin-list:
	@printf "$(GREEN)Listing plugins...$(NC)\n"
	@curl -s --max-time 10 http://localhost:8080/api/v1/plugins/ | jq . || printf "$(RED)Failed to list plugins. Is the server running?$(NC)\n"

plugin-reload:
	@printf "$(GREEN)Reloading plugins via API...$(NC)\n"
	@curl -X POST -s --max-time 30 http://localhost:8080/api/v1/plugins/reload | jq . || printf "$(RED)Failed to reload plugins. Is the server running?$(NC)\n"

plugin-refresh-dirs:
	@printf "$(GREEN)Refreshing plugin directories via API...$(NC)\n"
	@curl -X POST -s --max-time 30 http://localhost:8080/api/v1/plugins/refresh-directories | jq . || printf "$(RED)Failed to refresh directories. Is the server running?$(NC)\n"

# Builder image management
update-builder:
	@printf "$(BLUE)Pulling latest builder image from registry...$(NC)\n"
	docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)
	@printf "$(GREEN)Builder image updated successfully!$(NC)\n"

