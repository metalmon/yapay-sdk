.PHONY: help build examples all test clean install-deps lint dev-build dev-run dev-stop dev-shell dev-logs dev-status dev-clean dev-setup dev-test dev-debug dev-plugins dev-server dev-tunnel dev-tunnel-start dev-tunnel-stop dev-tunnel-status dev-tunnel-url plugins plugin-% build-plugins-alpine build-plugins-via-devcontainer build-plugin-alpine-% build-plugin-via-devcontainer-%

# Configuration
DOCKER_IMAGE := metalmon/yapay

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
help:
	@printf "$(GREEN)Yapay Plugin Development Kit$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)Available targets:$(NC)\n"
	@printf "  help         - Show this help message\n"
	@printf "  plugins      - Build all plugins (smart environment detection)\n"
	@printf "  plugin-NAME  - Build specific plugin (smart environment detection)\n"
	@printf "  build        - Build all plugins from src/ (legacy)\n"
	@printf "  examples     - Build all examples\n"
	@printf "  all          - Build everything\n"
	@printf "  test         - Run tests for all plugins and examples\n"
	@printf "  clean        - Clean build artifacts\n"
	@printf "  install-deps - Install development dependencies\n"
	@printf "  lint         - Run linter on all code\n"
	@printf "  sdk-build    - Build SDK\n"
	@printf "  sdk-test     - Test SDK\n"
	@printf "  tools-build  - Build development tools\n"
	@printf "\n"
	@printf "$(YELLOW)Development Container Commands:$(NC)\n"
	@printf "  dev-build       - Build development container\n"
	@printf "  docker-build-dev - Build devcontainer image for plugin compilation\n"
	@printf "  dev-run         - Run development container\n"
	@printf "  dev-stop        - Stop development container\n"
	@printf "  dev-shell       - Open shell in development container\n"
	@printf "  dev-logs        - Show development container logs\n"
	@printf "  dev-status      - Show development container status\n"
	@printf "  dev-clean       - Clean development container and volumes\n"
	@printf "  dev-setup       - Setup development environment\n"
	@printf "  dev-test        - Run tests in development container\n"
	@printf "  dev-debug       - Start debug session in container\n"
	@printf "  dev-plugins     - Build and test plugins in container\n"
	@printf "  dev-server      - Start Yapay server for integration testing\n"
	@printf "  dev-tunnel      - Start CloudPub tunnel for webhook testing\n"
	@printf "  dev-tunnel-start  - Start CloudPub tunnel\n"
	@printf "  dev-tunnel-stop   - Stop CloudPub tunnel\n"
	@printf "  dev-tunnel-status - Show tunnel status\n"
	@printf "  dev-tunnel-url    - Get tunnel URL\n"
	@printf "\n"
	@printf "$(YELLOW)Examples:$(NC)\n"
	@printf "  make plugins                  # Build all plugins (smart detection)\n"
	@printf "  make plugin-my-plugin         # Build specific plugin (smart detection)\n"
	@printf "  make examples                 # Build all examples\n"
	@printf "  make all                      # Build everything\n"
	@printf "  make test                     # Test all plugins and examples\n"
	@printf "  make -C src/my-plugin build   # Build specific plugin (legacy)\n"
	@printf "  make -C examples/simple-plugin build  # Build example plugin\n"
	@printf "  make dev-run                  # Start development container\n"
	@printf "  make dev-shell                # Open shell in container\n"

# Smart plugin build - ALWAYS uses the official builder for consistency
plugins:
	@printf "$(GREEN)Building plugins using official builder image...$(NC)\n"
	@if ! command -v docker >/dev/null 2>&1; then \
		printf "$(RED)Error: Docker CLI is not available. Please install Docker or run this from an environment where 'docker' command is present.$(NC)\n"; \
		exit 1; \
	fi
	@if ! docker image inspect $(DOCKER_IMAGE):builder >/dev/null 2>&1; then \
		printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
		docker pull $(DOCKER_IMAGE):builder; \
	fi
	@printf "$(YELLOW)Compiling all plugins inside the builder container...$(NC)\n"
	@docker run --rm \
		-v $(HOST_PROJECT_PATH):/workspace \
		-w /workspace \
		$(DOCKER_IMAGE):builder \
		make build-plugins-alpine
	@printf "$(GREEN)All plugins built successfully!$(NC)\n"

# Build plugins directly in Alpine environment (intended to be run INSIDE the builder)
# This logic is copied from the main yapay project for 100% compatibility.
build-plugins-alpine:
	@printf "$(BLUE)--- Running inside builder: Building all plugins ---$(NC)\n"
	@mkdir -p plugins
	@for plugin_dir in src/*; do \
		if [ -d "$$plugin_dir" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			printf "$(YELLOW)Building plugin: $$plugin_name$(NC)\n"; \
			mkdir -p plugins/$$plugin_name; \
			(cd "$$plugin_dir" && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
				-mod=mod \
				-buildmode=plugin \
				-buildvcs=false \
				-ldflags='-w -s' \
				-o $$plugin_name.so \
				.); \
			cp "$$plugin_dir/$$plugin_name.so" plugins/$$plugin_name/; \
			if [ -f "$$plugin_dir/config.yaml" ]; then \
				cp $$plugin_dir/config.yaml plugins/$$plugin_name/; \
			fi; \
			printf "$(GREEN)Plugin $$plugin_name built successfully!$(NC)\n"; \
		fi; \
	done
	@printf "$(GREEN)All plugins built successfully in Alpine environment!$(NC)\n"

# Build individual plugin - ALWAYS uses the official builder
plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name using official builder image...$(NC)\n"; \
	@if ! command -v docker >/dev/null 2>&1; then \
		printf "$(RED)Error: Docker CLI is not available.$(NC)\n"; \
		exit 1; \
	fi
	@if ! docker image inspect $(DOCKER_IMAGE):builder >/dev/null 2>&1; then \
		printf "$(YELLOW)Builder image not found locally, pulling from registry...$(NC)\n"; \
		docker pull $(DOCKER_IMAGE):builder; \
	fi
	@printf "$(YELLOW)Compiling plugin $$plugin_name inside the builder container...$(NC)\n"; \
	@docker run --rm \
		-v $(HOST_PROJECT_PATH):/workspace \
		-w /workspace \
		$(DOCKER_IMAGE):builder \
		make build-plugin-alpine-$$plugin_name
	@printf "$(GREEN)Plugin $$plugin_name built successfully!$(NC)\n"

# Build individual plugin directly in Alpine environment (intended to be run INSIDE the builder)
# This logic is copied from the main yapay project for 100% compatibility.
build-plugin-alpine-%:
	@plugin_name=$*; \
	@printf "$(BLUE)--- Running inside builder: Building plugin $$plugin_name ---$(NC)\n"; \
	@if [ -d "src/$$plugin_name" ]; then \
		mkdir -p plugins/$$plugin_name; \
		(cd "src/$$plugin_name" && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
			-mod=mod \
			-buildmode=plugin \
			-buildvcs=false \
			-ldflags='-w -s' \
			-o $$plugin_name.so \
			.); \
		cp "src/$$plugin_name/$$plugin_name.so" plugins/$$plugin_name/; \
		if [ -f "src/$$plugin_name/config.yaml" ]; then \
			cp "src/$$plugin_name/config.yaml" "plugins/$$plugin_name/"; \
		fi; \
		printf "$(GREEN)Plugin $$plugin_name built successfully in Alpine environment!$(NC)\n"; \
	else \
		printf "$(RED)Error: Plugin $$plugin_name not found in src/$(NC)\n"; \
		exit 1; \
	fi

# Legacy command for backward compatibility
build: plugins

# Build all examples
examples:
	@printf "$(GREEN)Building all examples...$(NC)\n"
	@for example in examples/*/; do \
		if [ -f "$$example/Makefile" ]; then \
			printf "$(YELLOW)Building $$example...$(NC)\n"; \
			$(MAKE) -C "$$example" build; \
		fi; \
	done

# Build everything (plugins + examples)
all:
	@printf "$(GREEN)Building everything...$(NC)\n"
	@$(MAKE) plugins
	@$(MAKE) examples

# Test all plugins and examples
test:
	@printf "$(GREEN)Testing all plugins and examples...$(NC)\n"
	@for plugin in src/*/ examples/*/; do \
		if [ -f "$$plugin/Makefile" ]; then \
			printf "$(YELLOW)Testing $$plugin...$(NC)\n"; \
			$(MAKE) -C "$$plugin" test; \
		fi; \
	done

# Clean all build artifacts
clean:
	@printf "$(GREEN)Cleaning build artifacts...$(NC)\n"
	@for plugin in src/*/ examples/*/; do \
		if [ -f "$$plugin/Makefile" ]; then \
			printf "$(YELLOW)Cleaning $$plugin...$(NC)\n"; \
			$(MAKE) -C "$$plugin" clean; \
		fi; \
	done
	@$(MAKE) -C tools/plugin-debug clean

# Install development dependencies
install-deps:
	@printf "$(GREEN)Installing development dependencies...$(NC)\n"
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run linter on all code
lint:
	@printf "$(GREEN)Running linter...$(NC)\n"
	golangci-lint run ./...

# Build SDK
sdk-build:
	@printf "$(GREEN)Building SDK...$(NC)\n"
	@go mod tidy
	@GOPATH="" GOCACHE="" go build ./...

# Test SDK
sdk-test:
	@printf "$(GREEN)Testing SDK...$(NC)\n"
	@GOPATH="" GOCACHE="" go test ./...

# Build development tools
tools-build:
	@printf "$(GREEN)Building development tools...$(NC)\n"
	@$(MAKE) -C tools/plugin-debug build

# Create new plugin from template
new-plugin:
	@if [ -z "$(NAME)" ]; then \
		printf "$(RED)Usage: make new-plugin NAME=my-plugin$(NC)\n"; \
		exit 1; \
	fi; \
	if [ -d "src/$(NAME)" ]; then \
		printf "$(RED)Error: Plugin '$(NAME)' already exists$(NC)\n"; \
		exit 1; \
	fi; \
	printf "$(GREEN)Creating new plugin: $(NAME)$(NC)\n"; \
	cp -r examples/simple-plugin src/$(NAME); \
	cd src/$(NAME) && \
	sed -i "s/simple-plugin/$(NAME)/g" go.mod && \
	sed -i "s/Simple Plugin Example/$(NAME)/g" config.yaml && \
	sed -i "s/simple-plugin/$(NAME)/g" Makefile && \
	printf "$(GREEN)Plugin '$(NAME)' created in src/$(NAME)/$(NC)\n"

# Check if all plugins and examples build successfully
check-all:
	@printf "$(GREEN)Checking all plugins and examples...$(NC)\n"
	@$(MAKE) all
	@$(MAKE) test
	@printf "$(GREEN)✅ All plugins and examples build and test successfully$(NC)\n"

# Update SDK dependencies
update-sdk-deps:
	@printf "$(GREEN)Updating SDK dependencies...$(NC)\n"
	@GOPATH="" GOCACHE="" go get -u ./...
	@GOPATH="" GOCACHE="" go mod tidy

# Development Container Commands

# Build development container
dev-build:
	@printf "$(GREEN)Building development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml build
	@printf "$(GREEN)Development container built successfully!$(NC)\n"

# Build devcontainer image for plugin compilation
docker-build-dev:
	@printf "$(GREEN)Building devcontainer image...$(NC)\n"
	docker build -f .devcontainer/Dockerfile.dev -t yapay-sdk:dev .
	@printf "$(GREEN)Devcontainer image built successfully!$(NC)\n"

# Run development container
dev-run: dev-build
	@printf "$(GREEN)Starting development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml up -d
	@printf "$(GREEN)Development container started successfully!$(NC)\n"
	@printf "$(BLUE)SDK Development Server: http://localhost:8080$(NC)\n"
	@printf "$(BLUE)Debug Port: 2345$(NC)\n"
	@printf "$(YELLOW)Use 'make dev-shell' to open shell in container$(NC)\n"

# Stop development container
dev-stop:
	@printf "$(YELLOW)Stopping development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml down
	@printf "$(GREEN)Development container stopped successfully!$(NC)\n"

# Open shell in development container
dev-shell:
	@printf "$(GREEN)Opening shell in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash

# Show development container logs
dev-logs:
	@printf "$(GREEN)Showing development container logs...$(NC)\n"
	docker compose -f docker-compose.dev.yml logs -f

# Show development container status
dev-status:
	@printf "$(GREEN)Development container status:$(NC)\n"
	docker compose -f docker-compose.dev.yml ps

# Clean development container and volumes
dev-clean:
	@printf "$(YELLOW)Cleaning development container and volumes...$(NC)\n"
	docker compose -f docker-compose.dev.yml down -v
	docker system prune -f
	@printf "$(GREEN)Development environment cleaned successfully!$(NC)\n"

# Setup development environment
dev-setup: dev-run
	@printf "$(GREEN)Setting up development environment...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && GOPATH=\"\" GOCACHE=\"\" go mod download && GOPATH=\"\" GOCACHE=\"\" go mod verify"
	@printf "$(GREEN)Development environment setup completed!$(NC)\n"

# Run tests in development container
dev-test:
	@printf "$(GREEN)Running tests in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make test"

# Start debug session in container
dev-debug:
	@printf "$(GREEN)Starting debug session...$(NC)\n"
	@printf "$(YELLOW)Debug port: 2345$(NC)\n"
	@printf "$(YELLOW)Use your IDE to connect to localhost:2345$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && dlv debug --headless --listen=:2345 --api-version=2"

# Build and test plugins in container
dev-plugins:
	@printf "$(GREEN)Building and testing plugins in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make plugins && make test"

# Start Yapay server for integration testing
dev-server:
	@printf "$(GREEN)Starting Yapay server for integration testing...$(NC)\n"
	docker compose -f docker-compose.dev.yml up -d yapay-server-dev
	@printf "$(BLUE)Yapay server started on http://localhost:8082$(NC)\n"
	@printf "$(YELLOW)Use 'make dev-plugins' to build plugins for testing$(NC)\n"

# Restart development container
dev-restart: dev-stop dev-run
	@printf "$(GREEN)Development container restarted successfully!$(NC)\n"

# Show development container health
dev-health:
	@printf "$(GREEN)Checking development container health...$(NC)\n"
	@curl -s http://localhost:8080/health | jq . || printf "$(RED)Health check failed$(NC)\n"

# Install development dependencies in container
dev-install-deps:
	@printf "$(GREEN)Installing development dependencies in container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make install-deps"

# Run linter in development container
dev-lint:
	@printf "$(GREEN)Running linter in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make lint"

# Format code in development container
dev-fmt:
	@printf "$(GREEN)Formatting code in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && go fmt ./..."

# Run security scan in development container
dev-security:
	@printf "$(GREEN)Running security scan in development container...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && gosec ./..."

# Run all checks in development container
dev-check: dev-fmt dev-lint dev-test dev-security
	@printf "$(GREEN)All checks completed in development container!$(NC)\n"

# Hot reload development (restart container with new code)
dev-reload: dev-stop dev-run
	@printf "$(GREEN)Development container reloaded with latest code!$(NC)\n"

# Show development container resource usage
dev-stats:
	@printf "$(GREEN)Development container resource usage:$(NC)\n"
	docker stats yapay-sdk-dev --no-stream

# Export development container logs
dev-export-logs:
	@printf "$(GREEN)Exporting development container logs...$(NC)\n"
	docker compose -f docker-compose.dev.yml logs > dev-logs-$(shell date +%Y%m%d-%H%M%S).log
	@printf "$(GREEN)Logs exported successfully!$(NC)\n"

# CloudPub Tunnel Commands

# Start CloudPub tunnel for webhook testing
dev-tunnel: dev-tunnel-start

# Start CloudPub tunnel
dev-tunnel-start:
	@printf "$(GREEN)Starting CloudPub tunnel for webhook testing...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh start"

# Stop CloudPub tunnel
dev-tunnel-stop:
	@printf "$(YELLOW)Stopping CloudPub tunnel...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh stop"

# Show CloudPub tunnel status
dev-tunnel-status:
	@printf "$(GREEN)Checking CloudPub tunnel status...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh status"

# Get CloudPub tunnel URL
dev-tunnel-url:
	@printf "$(GREEN)Getting CloudPub tunnel URL...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh url"

# Restart CloudPub tunnel
dev-tunnel-restart:
	@printf "$(GREEN)Restarting CloudPub tunnel...$(NC)\n"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh restart"
