#!/bin/bash

# Development setup script
set -e

echo "🚀 Setting up Yandex Payment Gateway development environment..."

# Download dependencies
echo "📥 Downloading dependencies..."
go mod download
go mod tidy

# Run tests
echo "🧪 Running tests..."
go test ./...

# Build application
echo "🔨 Building application..."
go build -o bin/yapay ./cmd/server

# Create development aliases
echo "⚙️ Setting up development aliases..."
cat >> ~/.bashrc << 'EOF'

# Yandex Payment Gateway development aliases
alias dev-run='make run'
alias dev-test='make test'
alias dev-lint='make lint'
alias dev-fmt='make fmt'
alias dev-build='make build'
alias dev-clean='make clean'
alias dev-hot='make dev-hot'

EOF

echo "✅ Development environment setup complete!"
echo ""
echo "🔧 Available commands:"
echo "  dev-run      - Run the application"
echo "  dev-test     - Run tests"
echo "  dev-lint     - Run linter"
echo "  dev-fmt      - Format code"
echo "  dev-build    - Build application"
echo "  dev-clean    - Clean build artifacts"
echo "  dev-hot      - Hot reload development"
echo ""
echo "🌐 Services:"
echo "  Application: http://localhost:8080"
echo "  Yandex Mock: http://localhost:8082"
echo ""
echo "🎯 Next steps:"
echo "  1. Run 'dev-hot' for hot reload development"
echo "  2. Open http://localhost:8080/api/v1/health to check health"
