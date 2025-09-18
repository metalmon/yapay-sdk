.PHONY: help build examples all test clean install-deps lint dev-build dev-run dev-stop dev-shell dev-logs dev-status dev-clean dev-setup dev-test dev-debug dev-plugins dev-server dev-tunnel dev-tunnel-start dev-tunnel-stop dev-tunnel-status dev-tunnel-url plugins plugin-% build-plugins-alpine build-plugins-via-devcontainer build-plugin-alpine-% build-plugin-via-devcontainer-%

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
help:
	@echo "Yapay Plugin Development Kit"
	@echo ""
	@echo "Available targets:"
	@echo "  help         - Show this help message"
	@echo "  plugins      - Build all plugins (smart environment detection)"
	@echo "  plugin-NAME  - Build specific plugin (smart environment detection)"
	@echo "  build        - Build all plugins from src/ (legacy)"
	@echo "  examples     - Build all examples"
	@echo "  all          - Build everything"
	@echo "  test         - Run tests for all plugins and examples"
	@echo "  clean        - Clean build artifacts"
	@echo "  install-deps - Install development dependencies"
	@echo "  lint         - Run linter on all code"
	@echo "  sdk-build    - Build SDK"
	@echo "  sdk-test     - Test SDK"
	@echo "  tools-build  - Build development tools"
	@echo ""
	@echo "Development Container Commands:"
	@echo "  dev-build       - Build development container"
	@echo "  docker-build-dev - Build devcontainer image for plugin compilation"
	@echo "  dev-run         - Run development container"
	@echo "  dev-stop        - Stop development container"
	@echo "  dev-shell       - Open shell in development container"
	@echo "  dev-logs        - Show development container logs"
	@echo "  dev-status      - Show development container status"
	@echo "  dev-clean       - Clean development container and volumes"
	@echo "  dev-setup       - Setup development environment"
	@echo "  dev-test        - Run tests in development container"
	@echo "  dev-debug       - Start debug session in container"
	@echo "  dev-plugins     - Build and test plugins in container"
	@echo "  dev-server      - Start Yapay server for integration testing"
	@echo "  dev-tunnel      - Start CloudPub tunnel for webhook testing"
	@echo "  dev-tunnel-start  - Start CloudPub tunnel"
	@echo "  dev-tunnel-stop   - Stop CloudPub tunnel"
	@echo "  dev-tunnel-status - Show tunnel status"
	@echo "  dev-tunnel-url    - Get tunnel URL"
	@echo ""
	@echo "Examples:"
	@echo "  make plugins                  # Build all plugins (smart detection)"
	@echo "  make plugin-my-plugin         # Build specific plugin (smart detection)"
	@echo "  make examples                 # Build all examples"
	@echo "  make all                      # Build everything"
	@echo "  make test                     # Test all plugins and examples"
	@echo "  make -C src/my-plugin build   # Build specific plugin (legacy)"
	@echo "  make -C examples/simple-plugin build  # Build example plugin"
	@echo "  make dev-run                  # Start development container"
	@echo "  make dev-shell                # Open shell in container"

# Smart plugin build - detects environment and uses devcontainer if needed
plugins:
	@printf "$(GREEN)Building plugins (smart environment detection)...$(NC)\n"
	@if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - building plugins directly$(NC)\n"; \
		$(MAKE) build-plugins-alpine; \
	elif [ -f /.dockerenv ]; then \
		printf "$(YELLOW)Running in Docker container but not Alpine - using devcontainer$(NC)\n"; \
		$(MAKE) build-plugins-via-devcontainer; \
	else \
		printf "$(YELLOW)Running on host - using devcontainer for Alpine compatibility$(NC)\n"; \
		$(MAKE) build-plugins-via-devcontainer; \
	fi

# Build plugins directly in Alpine environment (when already in devcontainer)
build-plugins-alpine:
	@printf "$(GREEN)Building plugins in Alpine environment...$(NC)\n"
	@for plugin in src/*/; do \
		if [ -f "$$plugin/Makefile" ]; then \
			plugin_name=$$(basename "$$plugin"); \
			printf "$(YELLOW)Building plugin: $$plugin_name$(NC)\n"; \
			(cd "$$plugin" && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 $(MAKE) build); \
		fi; \
	done
	@printf "$(GREEN)All plugins built successfully in Alpine environment!$(NC)\n"

# Build plugins via devcontainer (when not in Alpine environment)
build-plugins-via-devcontainer:
	@printf "$(GREEN)Building plugins via devcontainer for Alpine compatibility...$(NC)\n"
	@if ! docker ps -q --filter name=yapay-sdk-devcontainer | grep -q .; then \
		printf "$(YELLOW)Devcontainer not running - starting it...$(NC)\n"; \
		docker run --rm -d --name yapay-sdk-devcontainer \
			-v $(PWD):/workspace \
			-w /workspace \
			yapay-sdk:dev \
			tail -f /dev/null; \
		sleep 2; \
	fi
	@printf "$(YELLOW)Building plugins in devcontainer...$(NC)\n"
	@docker exec yapay-sdk-devcontainer make build-plugins-alpine
	@printf "$(GREEN)Plugins built via devcontainer successfully!$(NC)\n"

# Build individual plugin (smart environment detection)
plugin-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name (smart environment detection)...$(NC)\n"; \
	if [ -f /.dockerenv ] && [ -f /etc/alpine-release ]; then \
		printf "$(YELLOW)Running in Alpine devcontainer - building plugin directly$(NC)\n"; \
		$(MAKE) build-plugin-alpine-$$plugin_name; \
	elif [ -f /.dockerenv ]; then \
		printf "$(YELLOW)Running in Docker container but not Alpine - using devcontainer$(NC)\n"; \
		$(MAKE) build-plugin-via-devcontainer-$$plugin_name; \
	else \
		printf "$(YELLOW)Running on host - using devcontainer for Alpine compatibility$(NC)\n"; \
		$(MAKE) build-plugin-via-devcontainer-$$plugin_name; \
	fi

# Build individual plugin directly in Alpine environment
build-plugin-alpine-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name in Alpine environment...$(NC)\n"; \
	if [ -f "src/$$plugin_name/Makefile" ]; then \
		(cd "src/$$plugin_name" && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 $(MAKE) build); \
		printf "$(GREEN)Plugin $$plugin_name built successfully in Alpine environment!$(NC)\n"; \
	elif [ -f "examples/$$plugin_name/Makefile" ]; then \
		(cd "examples/$$plugin_name" && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 $(MAKE) build); \
		printf "$(GREEN)Plugin $$plugin_name built successfully in Alpine environment!$(NC)\n"; \
	else \
		printf "$(RED)Error: Plugin $$plugin_name not found in src/ or examples/$(NC)\n"; \
		exit 1; \
	fi

# Build individual plugin via devcontainer
build-plugin-via-devcontainer-%:
	@plugin_name=$*; \
	printf "$(GREEN)Building plugin: $$plugin_name via devcontainer...$(NC)\n"; \
	if ! docker ps -q --filter name=yapay-sdk-devcontainer | grep -q .; then \
		printf "$(YELLOW)Devcontainer not running - starting it...$(NC)\n"; \
		docker run --rm -d --name yapay-sdk-devcontainer \
			-v $(PWD):/workspace \
			-w /workspace \
			yapay-sdk:dev \
			tail -f /dev/null; \
		sleep 2; \
	fi; \
	printf "$(YELLOW)Building plugin $$plugin_name in devcontainer...$(NC)\n"; \
	docker exec yapay-sdk-devcontainer make build-plugin-alpine-$$plugin_name; \
	printf "$(GREEN)Plugin $$plugin_name built via devcontainer successfully!$(NC)\n"

# Build everything (plugins + examples)
build: plugins examples

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
	@go build ./...

# Test SDK
sdk-test:
	@printf "$(GREEN)Testing SDK...$(NC)\n"
	@go test ./...

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
	@go get -u ./...
	@go mod tidy

# Development Container Commands

# Build development container
dev-build:
	@echo "Building development container..."
	docker compose -f docker-compose.dev.yml build
	@echo "Development container built successfully!"

# Build devcontainer image for plugin compilation
docker-build-dev:
	@echo "Building devcontainer image..."
	docker build -f .devcontainer/Dockerfile.dev -t yapay-sdk:dev .
	@echo "Devcontainer image built successfully!"

# Run development container
dev-run: dev-build
	@echo "Starting development container..."
	docker compose -f docker-compose.dev.yml up -d
	@echo "Development container started successfully!"
	@echo "SDK Development Server: http://localhost:8080"
	@echo "Debug Port: 2345"
	@echo "Use 'make dev-shell' to open shell in container"

# Stop development container
dev-stop:
	@echo "Stopping development container..."
	docker compose -f docker-compose.dev.yml down
	@echo "Development container stopped successfully!"

# Open shell in development container
dev-shell:
	@echo "Opening shell in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash

# Show development container logs
dev-logs:
	@echo "Showing development container logs..."
	docker compose -f docker-compose.dev.yml logs -f

# Show development container status
dev-status:
	@echo "Development container status:"
	docker compose -f docker-compose.dev.yml ps

# Clean development container and volumes
dev-clean:
	@echo "Cleaning development container and volumes..."
	docker compose -f docker-compose.dev.yml down -v
	docker system prune -f
	@echo "Development environment cleaned successfully!"

# Setup development environment
dev-setup: dev-run
	@echo "Setting up development environment..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && go mod download && go mod verify"
	@echo "Development environment setup completed!"

# Run tests in development container
dev-test:
	@echo "Running tests in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make test"

# Start debug session in container
dev-debug:
	@echo "Starting debug session..."
	@echo "Debug port: 2345"
	@echo "Use your IDE to connect to localhost:2345"
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && dlv debug --headless --listen=:2345 --api-version=2"

# Build and test plugins in container
dev-plugins:
	@echo "Building and testing plugins in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make plugins && make test"

# Start Yapay server for integration testing
dev-server:
	@echo "Starting Yapay server for integration testing..."
	docker compose -f docker-compose.dev.yml up -d yapay-server-dev
	@echo "Yapay server started on http://localhost:8082"
	@echo "Use 'make dev-plugins' to build plugins for testing"

# Restart development container
dev-restart: dev-stop dev-run
	@echo "Development container restarted successfully!"

# Show development container health
dev-health:
	@echo "Checking development container health..."
	@curl -s http://localhost:8080/health | jq . || echo "Health check failed"

# Install development dependencies in container
dev-install-deps:
	@echo "Installing development dependencies in container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make install-deps"

# Run linter in development container
dev-lint:
	@echo "Running linter in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && make lint"

# Format code in development container
dev-fmt:
	@echo "Formatting code in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && go fmt ./..."

# Run security scan in development container
dev-security:
	@echo "Running security scan in development container..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && gosec ./..."

# Run all checks in development container
dev-check: dev-fmt dev-lint dev-test dev-security
	@echo "All checks completed in development container!"

# Hot reload development (restart container with new code)
dev-reload: dev-stop dev-run
	@echo "Development container reloaded with latest code!"

# Show development container resource usage
dev-stats:
	@echo "Development container resource usage:"
	docker stats yapay-sdk-dev --no-stream

# Export development container logs
dev-export-logs:
	@echo "Exporting development container logs..."
	docker compose -f docker-compose.dev.yml logs > dev-logs-$(shell date +%Y%m%d-%H%M%S).log
	@echo "Logs exported successfully!"

# CloudPub Tunnel Commands

# Start CloudPub tunnel for webhook testing
dev-tunnel: dev-tunnel-start

# Start CloudPub tunnel
dev-tunnel-start:
	@echo "Starting CloudPub tunnel for webhook testing..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh start"

# Stop CloudPub tunnel
dev-tunnel-stop:
	@echo "Stopping CloudPub tunnel..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh stop"

# Show CloudPub tunnel status
dev-tunnel-status:
	@echo "Checking CloudPub tunnel status..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh status"

# Get CloudPub tunnel URL
dev-tunnel-url:
	@echo "Getting CloudPub tunnel URL..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh url"

# Restart CloudPub tunnel
dev-tunnel-restart:
	@echo "Restarting CloudPub tunnel..."
	docker compose -f docker-compose.dev.yml exec yapay-sdk-dev bash -c "cd /workspace/sdk && ./scripts/cloudpub-tunnel.sh restart"
