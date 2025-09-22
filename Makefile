# YAPAY SDK Makefile
# Provides consistent plugin building using the same builder image as the main yapay project

.PHONY: help show-env build-plugins build-plugin-% clean check-compatibility test test-plugins test-tools build-tools tunnel tunnel-start tunnel-stop tunnel-status tunnel-url debug-plugin debug-plugin-% tools build-plugin-debug plugin-list plugin-reload plugin-refresh-dirs update-builder fmt lint lint-fix security check

# Configuration
OUTPUT_DIR := plugins
TOOLS_DIR := tools
DOCKER_IMAGE := metalmon/yapay
BUILDER_TAG := builder

# Universal Environment Detection and Path Configuration
# Automatically detects environment: devcontainer, container, or host
DETECT_ENV := $(shell if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then echo "devcontainer"; elif [ -f /.dockerenv ]; then echo "container"; else echo "host"; fi)

# Universal workspace path - always use /workspace for consistency across all environments
WORKSPACE_PATH := /workspace
DOCKER_VOLUME := $(PWD):$(WORKSPACE_PATH)
DOCKER_WORKDIR := $(WORKSPACE_PATH)

# Builder dependencies path (from builder image - always /app)
BUILDER_DEPS_PATH := /app

# Environment-specific configurations
ifeq ($(DETECT_ENV),devcontainer)
	# Running in devcontainer - direct build available, no Docker needed
	BUILD_MODE := direct
	ENV_INFO := "Alpine devcontainer - direct build "
else
	# Running on host or in other container - use Docker builder
	BUILD_MODE := docker
	ENV_INFO := "Host/Container - Docker builder "
endif

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Show environment information
show-env:
	@printf "$(GREEN)Environment Detection:$(NC)\n"
	@printf "  Detected: $(DETECT_ENV)\n"
	@printf "  Build Mode: $(BUILD_MODE)\n"
	@printf "  Info: $(ENV_INFO)\n"
	@printf "  Workspace: $(WORKSPACE_PATH)\n"
	@printf "  Docker Volume: $(DOCKER_VOLUME)\n"
	@printf "  Builder Deps: $(BUILDER_DEPS_PATH)\n"
	@printf "  Current PWD: $(PWD)\n"

# Show help
help:
	@printf "$(GREEN)YAPAY SDK Development Tools$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)Environment:$(NC)\n"
	@printf "  show-env             - Show environment detection and configuration\n"
	@printf "\n"
	@printf "$(YELLOW)Plugin management:$(NC)\n"
	@printf "  new-plugin-NAME      - Create new plugin from template (auto-replaces all template strings)\n"
	@printf "  build-plugins        - Build all plugins (universal command)\n"
	@printf "  build-plugin-NAME    - Build specific plugin\n"
	@printf "  check-compatibility  - Check development environment compatibility\n"
	@printf "  check-plugin-compatibility - Check plugin compatibility with builder image\n"
	@printf "  check-sdk-compatibility - Check if SDK changes break plugins\n"
	@printf "\n"
	@printf "$(YELLOW)Testing:$(NC)\n"
	@printf "  test                 - Run all tests (plugins + tools)\n"
	@printf "  test-plugins         - Test all plugins\n"
	@printf "  test-tools           - Test all tools\n"
	@printf "\n"
	@printf "$(YELLOW)Code Quality:$(NC)\n"
	@printf "  fmt                  - Format code with imports management\n"
	@printf "  lint                 - Simple linter check (as in CI)\n"
	@printf "  lint-fix             - Automatic formatting fix + linter check\n"
	@printf "  security             - Run security scan\n"
	@printf "  check                - Full check (format + lint-fix + test + security)\n"
	@printf "\n"
	@printf "$(YELLOW)Tools:$(NC)\n"
	@printf "  build-tools          - Build all development tools\n"
	@printf "  build-plugin-debug   - Build plugin debug tool\n"
	@printf "  debug-plugin-NAME    - Debug specific plugin\n"
	@printf "\n"
	@printf "$(YELLOW)CloudPub tunnel (webhook testing):$(NC)\n"
	@printf "  tunnel               - Start CloudPub tunnel\n"
	@printf "  tunnel-start         - Start CloudPub tunnel\n"
	@printf "  tunnel-stop          - Stop CloudPub tunnel\n"
	@printf "  tunnel-status        - Show tunnel status\n"
	@printf "  tunnel-url           - Get tunnel URL\n"
	@printf "\n"
	@printf "$(YELLOW)Server Development:$(NC)\n"
	@printf "  dev-server           - Start YAPAY server for development\n"
	@printf "  dev-watch            - Start plugin hot-reload watcher\n"
	@printf "  dev-stop             - Stop development server\n"
	@printf "\n"
	@printf "$(YELLOW)Plugin Management:$(NC)\n"
	@printf "  plugin-list          - List loaded plugins\n"
	@printf "  plugin-reload        - Reload plugins via API\n"
	@printf "  plugin-refresh-dirs  - Refresh plugin directories\n"
	@printf "\n"
	@printf "$(YELLOW)Builder Management:$(NC)\n"
	@printf "  update-builder       - Update builder image from registry\n"
	@printf "  update-dev-image     - Update development image from registry\n"
	@printf "\n"
	@printf "$(YELLOW)Utilities:$(NC)\n"
	@printf "  clean                - Clean build artifacts\n"
	@printf "  tools                - Alias for build-tools\n"
	@printf "\n"
	@printf "$(BLUE)Examples:$(NC)\n"
	@printf "  make new-plugin-my-plugin\n"
	@printf "  make build-plugin-my-plugin\n"
	@printf "  make dev-server      # Start server with hot-reload\n"
	@printf "  make dev-watch       # Watch for plugin changes\n"
	@printf "  make plugin-list     # List loaded plugins\n"
	@printf "  make test\n"
	@printf "  make debug-plugin-my-plugin\n"
	@printf "  make tunnel-start\n"
	@printf "\n"
	@printf "$(BLUE)Code Quality Examples:$(NC)\n"
	@printf "  make lint            # Simple linter check\n"
	@printf "  make lint-fix        # Auto-fix formatting and linting\n"
	@printf "  make check           # Full quality check\n"

# Build all plugins using universal builder (works in all environments)
build-plugins:
	@printf "$(GREEN)Building plugins using universal builder...$(NC)\n"
	@printf "$(BLUE)Environment: $(ENV_INFO)$(NC)\n"
	@if [ "$(BUILD_MODE)" = "direct" ]; then \
		printf "$(YELLOW)Direct build in devcontainer...$(NC)\n"; \
		mkdir -p $(OUTPUT_DIR) && \
		for plugin_dir in src/*; do \
			if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
				plugin_name=$$(basename "$$plugin_dir"); \
				printf "Building plugin: $$plugin_name\n"; \
				mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
				rm -f "$$plugin_dir/$$plugin_name.so"; \
				(cd "$$plugin_dir" && cp $(BUILDER_DEPS_PATH)/go.mod . && cp $(BUILDER_DEPS_PATH)/go.sum . && cp -r $(BUILDER_DEPS_PATH)/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
					-mod=vendor \
					-buildmode=plugin \
					-buildvcs=false \
					-ldflags="-w -s" \
					-o $$plugin_name.so \
					.); \
				cp "$$plugin_dir/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
				if [ -f "$$plugin_dir/config.yaml" ]; then \
					cp "$$plugin_dir/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
				fi; \
				printf "Plugin $$plugin_name built successfully!\n"; \
			fi; \
		done; \
	else \
		printf "$(YELLOW)Docker build mode...$(NC)\n"; \
		if ! docker image inspect $(DOCKER_IMAGE):$(BUILDER_TAG) >/dev/null 2>&1; then \
			printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
			docker pull $(DOCKER_IMAGE):$(BUILDER_TAG) || \
			(printf "$(RED)Failed to pull builder image. Please ensure it's available:$(NC)\n"; \
			 printf "$(YELLOW)  docker pull $(DOCKER_IMAGE):$(BUILDER_TAG)$(NC)\n"; \
			 exit 1); \
		fi; \
		printf "$(YELLOW)Compiling all plugins inside the builder container...$(NC)\n"; \
		docker run --rm \
			-v $(DOCKER_VOLUME) \
			-w $(DOCKER_WORKDIR) \
			-e GOPRIVATE=github.com/metalmon/yapay-sdk \
			-e GOCACHE=/tmp/go-build \
			-u $(shell id -u):$(shell id -g) \
			$(DOCKER_IMAGE):$(BUILDER_TAG) \
			sh -c 'mkdir -p $(OUTPUT_DIR) && \
			for plugin_dir in src/*; do \
				if [ -d "$$plugin_dir" ] && [ -f "$$plugin_dir/go.mod" ]; then \
					plugin_name=$$(basename "$$plugin_dir"); \
					printf "Building plugin: $$plugin_name\n"; \
					mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
					rm -f "$$plugin_dir/$$plugin_name.so"; \
					(cd "$$plugin_dir" && cp $(BUILDER_DEPS_PATH)/go.mod . && cp $(BUILDER_DEPS_PATH)/go.sum . && cp -r $(BUILDER_DEPS_PATH)/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
						-mod=vendor \
						-buildmode=plugin \
						-buildvcs=false \
						-ldflags="-w -s" \
						-o $$plugin_name.so \
						.); \
					cp "$$plugin_dir/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
					if [ -f "$$plugin_dir/config.yaml" ]; then \
						cp "$$plugin_dir/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
					fi; \
					printf "Plugin $$plugin_name built successfully!\n"; \
				fi; \
			done'; \
	fi; \
	printf "$(GREEN)All plugins built successfully!$(NC)\n"


# Build individual plugin using universal builder (works in all environments)
build-plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name using universal builder$(NC)\n"; \
	printf "$(BLUE)Environment: $(ENV_INFO)$(NC)\n"; \
	if [ "$(BUILD_MODE)" = "direct" ]; then \
		printf "$(YELLOW)Direct build in devcontainer...$(NC)\n"; \
		(cd "src/$$plugin_name" && cp $(BUILDER_DEPS_PATH)/go.mod . && cp $(BUILDER_DEPS_PATH)/go.sum . && cp -r $(BUILDER_DEPS_PATH)/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
			-mod=vendor \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags="-w -s" \
			-o $$plugin_name.so \
			.); \
		mkdir -p $(OUTPUT_DIR)/$$plugin_name; \
		cp "src/$$plugin_name/$$plugin_name.so" $(OUTPUT_DIR)/$$plugin_name/; \
		if [ -f "src/$$plugin_name/config.yaml" ]; then \
			cp "src/$$plugin_name/config.yaml" $(OUTPUT_DIR)/$$plugin_name/; \
		fi; \
	else \
		printf "$(YELLOW)Docker build mode...$(NC)\n"; \
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
			-v $(DOCKER_VOLUME) \
			-w $(DOCKER_WORKDIR)/src/$$plugin_name \
			-e GOPRIVATE=github.com/metalmon/yapay-sdk \
			-e GOCACHE=/tmp/go-build \
			-u $(shell id -u):$(shell id -g) \
			$(DOCKER_IMAGE):$(BUILDER_TAG) \
			sh -c 'cp $(BUILDER_DEPS_PATH)/go.mod . && cp $(BUILDER_DEPS_PATH)/go.sum . && cp -r $(BUILDER_DEPS_PATH)/vendor . && CGO_ENABLED=1 GOPRIVATE=github.com/metalmon/yapay-sdk GOOS=linux GOARCH=amd64 go build \
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
	fi; \
	printf "$(GREEN)Plugin $$plugin_name built successfully!$(NC)\n"






# Clean build artifacts
clean:
	@printf "$(YELLOW)Cleaning build artifacts...$(NC)\n"
	rm -rf $(OUTPUT_DIR)
	@for plugin_dir in src/*; do \
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

# Check plugin compatibility with builder image
check-plugin-compatibility:
	@printf "$(GREEN)Checking plugin compatibility with builder image...$(NC)\n"
	@chmod +x ./scripts/check-plugin-compatibility.sh
	@./scripts/check-plugin-compatibility.sh

# Check if SDK changes break plugin compatibility
check-sdk-compatibility:
	@printf "$(GREEN)Checking SDK compatibility with existing plugins...$(NC)\n"
	@chmod +x ./scripts/check-plugin-compatibility.sh
	@./scripts/check-plugin-compatibility.sh
	@if [ $$? -ne 0 ]; then \
		printf "$(RED)SDK CHANGES WILL BREAK PLUGINS!$(NC)\n"; \
		printf "$(YELLOW)Recommendation: Review changes or update builder image$(NC)\n"; \
		exit 1; \
	fi

# Test commands
test: test-plugins test-tools
	@printf "$(GREEN)All tests completed!$(NC)\n"

# Test plugins
test-plugins:
	@printf "$(GREEN)Testing plugins...$(NC)\n"
	@for plugin_dir in src/*; do \
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
	cp -r "src/simple-plugin/"* "$$src_dir/"; \
	\
	# Convert plugin name to PascalCase for Go types \
	pascal_name=$$(echo $$plugin_name | sed 's/-\([a-z]\)/\U\1/g' | sed 's/^\([a-z]\)/\U\1/'); \
	\
	# Replace all occurrences of simple-plugin with new plugin name \
	printf "$(YELLOW)Replacing template strings...$(NC)\n"; \
	\
	# Replace in go.mod (if exists) \
	if [ -f "$$src_dir/go.mod" ]; then \
		sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/go.mod"; \
	fi; \
	\
	# Remove individual Makefile (not needed - use main Makefile instead) \
	rm -f "$$src_dir/Makefile"; \
	\
	# Replace in README.md \
	sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/README.md"; \
	sed -i "s/Simple Plugin Example/$$pascal_name Plugin/g" "$$src_dir/README.md"; \
	sed -i "s/Простой пример плагина/$$pascal_name плагин/g" "$$src_dir/README.md"; \
	\
	# Replace in config.yaml \
	sed -i "s/simple-plugin-client/$$plugin_name-client/g" "$$src_dir/config.yaml"; \
	sed -i "s/Simple Plugin Example/$$pascal_name Plugin/g" "$$src_dir/config.yaml"; \
	sed -i "s/Простой пример плагина для Yapay SDK/$$pascal_name плагин для Yapay SDK/g" "$$src_dir/config.yaml"; \
	sed -i "s/example.com/$$plugin_name.example.com/g" "$$src_dir/config.yaml"; \
	sed -i "s/business_type: \"example\"/business_type: \"$$plugin_name\"/g" "$$src_dir/config.yaml"; \
	\
	# Replace in main.go \
	sed -i "s/SimplePlugin/$$pascal_name/g" "$$src_dir/main.go"; \
	sed -i "s/SimpleGenerator/$$pascal_name""Generator/g" "$$src_dir/main.go"; \
	sed -i "s/simple plugin handler/$$plugin_name plugin handler/g" "$$src_dir/main.go"; \
	sed -i "s/Simple plugin handler created/$$pascal_name plugin handler created/g" "$$src_dir/main.go"; \
	\
	# Replace in main_test.go \
	if [ -f "$$src_dir/main_test.go" ]; then \
		sed -i "s/simple-plugin/$$plugin_name/g" "$$src_dir/main_test.go"; \
	fi; \
	\
	printf "$(GREEN)Plugin $$plugin_name created successfully in src/!$(NC)\n"; \
	printf "$(YELLOW)Template replacements completed:$(NC)\n"; \
	printf "$(YELLOW)  - Plugin name: $$plugin_name$(NC)\n"; \
	printf "$(YELLOW)  - PascalCase name: $$pascal_name$(NC)\n"; \
	printf "$(YELLOW)  - Client ID: $$plugin_name-client$(NC)\n"; \
	printf "$(YELLOW)  - Domain: $$plugin_name.example.com$(NC)\n"; \
	printf "$(YELLOW)Next steps:$(NC)\n"; \
	printf "$(YELLOW)  1. Edit src/$$plugin_name/main.go$(NC)\n"; \
	printf "$(YELLOW)  2. Edit src/$$plugin_name/config.yaml$(NC)\n"; \
	printf "$(YELLOW)  3. Build: make build-plugin-$$plugin_name$(NC)\n"; \
	printf "$(YELLOW)  4. Test: make test-plugins$(NC)\n"; \
	printf "$(YELLOW)  5. Add to Git: git add src/$$plugin_name/$(NC)\n"; \
	printf "$(YELLOW)$(NC)\n"; \
	printf "$(YELLOW)Note: Individual Makefile removed - use main Makefile commands$(NC)\n"

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

# Development image management
update-dev-image:
	@printf "$(BLUE)Updating development image...$(NC)\n"
	@chmod +x ./scripts/update-dev-image.sh
	@./scripts/update-dev-image.sh

# Format code with imports management
fmt:
	@printf "$(GREEN)Formatting code...$(NC)\n"
	@if ! command -v goimports >/dev/null 2>&1; then \
		printf "$(YELLOW)Installing goimports...$(NC)\n"; \
		go install golang.org/x/tools/cmd/goimports@v0.20.0; \
	fi
	go fmt ./...
	goimports -w .
	@printf "$(GREEN)Code formatting completed!$(NC)\n"

# Lint code with auto-fix formatting
lint: fmt
	@printf "$(GREEN)Linting code...$(NC)\n"
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		printf "$(YELLOW)Installing golangci-lint...$(NC)\n"; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.8; \
	fi
	golangci-lint run --timeout=5m
	@printf "$(GREEN)Linting completed!$(NC)\n"

# Lint with auto-fix (fixes what can be fixed automatically)
lint-fix: fmt
	@printf "$(GREEN)Linting code with auto-fix...$(NC)\n"
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		printf "$(YELLOW)Installing golangci-lint...$(NC)\n"; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.8; \
	fi
	golangci-lint run --timeout=5m --fix
	@printf "$(GREEN)Linting with auto-fix completed!$(NC)\n"

# Security scan
security:
	@printf "$(GREEN)Running security scan...$(NC)\n"
	gosec ./...

# Check all (format, lint-fix, test, security)
check: lint-fix test security
	@printf "$(GREEN)All checks passed!$(NC)\n"

