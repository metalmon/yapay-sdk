# Changelog

All notable changes to the Yapay Plugin SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-10-01

### Added

- **Request API** - новый API для обработки заявок без создания платежей
- **RequestData, RequestResult, RequestSettings** - новые типы для работы с заявками
- **Extended PaymentLinkGenerator interface** - добавлены методы `ProcessRequest()`, `ValidateRequestData()`, `GetRequestSettings()`
- **Support for consultation/callback requests** - поддержка сценариев "оплата после консультации"

### Changed

- **PaymentLinkGenerator interface** - расширен для поддержки заявок (breaking change)
- **SDK version bumped to 1.1.0** - major version update

### Breaking Changes

- All plugins must implement new methods: `ProcessRequest()`, `ValidateRequestData()`, `GetRequestSettings()`
- Existing plugins need to be updated to satisfy the extended interface

## [1.0.11] - 2025-09-23

### Added

- **Support for SDK version 1.0.11** - добавлена поддержка новой версии SDK
- **Version compatibility detection** - автоматическое определение версии SDK в плагинах
- **Enhanced version adapter** - улучшенный адаптер версий для совместимости

### Changed

- **Updated all projects to v1.0.11** - все проекты обновлены на версию 1.0.11
- **Fixed checksum mismatch issues** - исправлены проблемы с несовпадением хешей
- **Improved Dockerfile.builder** - улучшен builder образ для стабильной сборки

### Fixed

- **Checksum verification errors** - исправлены ошибки проверки контрольных сумм
- **Version detection in plugins** - корректное определение версии SDK в плагинах
- **Builder image consistency** - обеспечена консистентность builder образа

## [1.0.10] - 2025-09-23

### Added

- **Modules-only builds with shared module cache** - новая архитектура сборки
- **ABI совместимость** - плагины и сервер используют одинаковые зависимости
- **Replace директивы** - синхронизация версий общих зависимостей
- **Документация по modules-only архитектуре** - подробное руководство
- **Автоматическая загрузка плагинов** - сервер автоматически обнаруживает плагины в директории `plugins/`

### Changed

- **Удален vendor/** - переход на modules-only сборку
- **Обновлены go.mod файлы** - каждый плагин имеет собственный модуль
- **Синхронизированы версии зависимостей** - `golang.org/x/sys v0.36.0`
- **Улучшена конфигурация кеша** - разделение для сборки и инструментов разработки
- **Обновлены команды сборки** - консистентность между проектами

### Fixed

- **Права файлов в Docker** - файлы создаются с правами пользователя хоста
- **Консистентность Makefile** - одинаковые подходы в обоих проектах
- **Очистка артефактов** - `make clean` больше не удаляет go.mod файлы
- **Команды линтера** - корректная работа с локальным кешем

### Security

- **Детерминированная сборка** - исключены различия в зависимостях
- **Изоляция плагинов** - каждый плагин имеет собственную конфигурацию модулей

### Documentation

- **Обновлена версия SDK** - с 1.0.8 на 1.0.10
- **Исправлена документация конфигурации** - убраны выдуманные поля, добавлены реальные требования
- **Примеры go.mod структуры** - правильная настройка плагинов
- **Руководство по миграции** - переход с vendor-based сборки

## [1.0.8] - 2025-09-21

### Changed

- Updated `ClientHandler` interface to `PaymentEventHandler` for better clarity
- Renamed payment event methods:
  - `HandlePaymentCreated` → `OnPaymentCreated`
  - `HandlePaymentSuccess` → `OnPaymentSuccess`
  - `HandlePaymentFailed` → `OnPaymentFailed`
  - `HandlePaymentCanceled` → `OnPaymentCanceled`
- Removed deprecated methods from `PaymentEventHandler`:
  - `ValidateRequest` (now handled by server)
  - `GetMerchantConfig`, `GetMerchantID`, `GetMerchantName` (moved to server)
  - `GetPaymentLinkGenerator`, `SetPaymentLinkGenerator` (no longer needed)

### Updated

- All documentation updated to reflect new interface structure
- Examples and templates updated to use new method names
- Version references updated throughout documentation

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
