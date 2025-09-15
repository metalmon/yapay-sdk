# Changelog

All notable changes to the Yapay Plugin SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of Yapay Plugin SDK
- Plugin development tools and examples
- Comprehensive documentation

## [1.0.0] - 2025-09-15

### Added

- **SDK Package** (`github.com/metalmon/yapay-sdk`)

  - `ClientHandler` interface for plugin development
  - `PaymentLinkGenerator` interface for payment generation
  - Data models: `Payment`, `Merchant`, `PaymentRequest`
  - Testing utilities: `MockClientHandler`, `MockPaymentGenerator`
  - Test data generators

- **Development Tools**

  - Plugin debug tool for standalone testing
  - Make commands for building and testing
  - Hot-reload support for development

- **Examples**

  - Simple plugin template with full implementation
  - Unit tests with comprehensive coverage
  - Configuration examples

- **Documentation**
  - SDK usage guide
  - Plugin development tutorial
  - Debugging and testing guide
  - CI/CD setup instructions

### Features

- Support for payment lifecycle events (created, success, failed, canceled)
- Request validation with customizable rules
- Payment link generation with Yandex Pay integration
- Configurable notifications (Telegram, Email)
- CORS and security validation
- Hot-reload for development workflow

### Security

- Secure plugin loading with interface validation
- Input validation and sanitization
- No exposure of internal server logic in SDK
