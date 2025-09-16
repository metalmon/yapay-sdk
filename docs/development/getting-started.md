# Руководство по разработке плагинов

## Обзор

Плагины в Yapay SDK позволяют создавать индивидуальную логику обработки платежей для каждого клиента. Каждый плагин представляет собой отдельный Go модуль, который реализует стандартные интерфейсы SDK.

## Структура плагина

### Обязательные файлы

```
my-plugin/
├── go.mod                 # Go модуль
├── main.go               # Основная логика плагина
├── config.yaml          # Конфигурация клиента
├── Makefile             # Сборка плагина
└── README.md           # Документация плагина
```

### Обязательные функции

Каждый плагин должен экспортировать две функции:

```go
// NewHandler создает обработчик клиента
func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler

// NewPaymentGenerator создает генератор платежных данных
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator
```

## Создание нового плагина

### 1. Инициализация проекта

```bash
# Создаем директорию плагина
mkdir my-plugin
cd my-plugin

# Инициализируем Go модуль
go mod init my-plugin

# Добавляем зависимость на SDK
go get github.com/metalmon/yapay-sdk@latest
```

### 2. Базовая структура main.go

```go
package main

import (
    "fmt"
    "github.com/metalmon/yapay-sdk"
    "github.com/sirupsen/logrus"
)

// MyPluginHandler реализует интерфейс ClientHandler
type MyPluginHandler struct {
    merchant *yapay.Merchant
    logger   *logrus.Logger
}

// NewHandler создает новый обработчик клиента
func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler {
    return &MyPluginHandler{
        merchant: merchant,
        logger:   logrus.New(),
    }
}

// NewPaymentGenerator создает генератор платежных данных
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator {
    return &MyPaymentGenerator{
        merchant: merchant,
        logger:   logger,
    }
}

// Реализация методов ClientHandler
func (h *MyPluginHandler) HandlePaymentCreated(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment created")
    return nil
}

func (h *MyPluginHandler) HandlePaymentSuccess(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment succeeded")
    return nil
}

func (h *MyPluginHandler) HandlePaymentFailed(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment failed")
    return nil
}

func (h *MyPluginHandler) HandlePaymentCanceled(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment canceled")
    return nil
}

func (h *MyPluginHandler) ValidateRequest(req *yapay.PaymentRequest) error {
    // Валидация запроса
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive")
    }
    if req.Description == "" {
        return fmt.Errorf("description is required")
    }
    return nil
}

func (h *MyPluginHandler) GetMerchantConfig() *yapay.Merchant {
    return h.merchant
}

func (h *MyPluginHandler) GetMerchantID() string {
    return h.merchant.ID
}

func (h *MyPluginHandler) GetMerchantName() string {
    return h.merchant.Name
}

func (h *MyPluginHandler) GetPaymentLinkGenerator() interface{} {
    return NewPaymentGenerator(h.merchant, h.logger)
}

func (h *MyPluginHandler) SetPaymentLinkGenerator(generator interface{}) {
    // Реализация по необходимости
}
```

### 3. Конфигурация config.yaml

```yaml
id: "my-plugin-client"
name: "My Plugin Client"
description: "Описание клиента"
domain: "my-site.com"
enabled: true
sandbox_mode: true
cors_origins:
  - "https://my-site.com"
  - "https://www.my-site.com"
rate_limit: 100
metadata:
  custom_field: "custom_value"

yandex:
  merchant_id: "your-yandex-merchant-id"
  secret_key: "your-yandex-secret-key"
  sandbox_mode: true
  currency: "RUB"
  api_base_url: "https://sandbox.pay.yandex.ru"
  orders_endpoint: "/api/merchant/v1/orders"
  jwks_endpoint: "/api/jwks"

notifications:
  telegram:
    enabled: true
    chat_id: "your-telegram-chat-id"
    bot_token: "your-telegram-bot-token"
  email:
    enabled: false
    smtp_host: ""
    smtp_port: 587
    username: ""
    password: ""
    from: ""

field_labels:
  course_id: "ID курса"
  user_id: "ID пользователя"
  course_name: "Название курса"
```

### 4. Makefile для сборки

```makefile
PLUGIN_NAME := my-plugin
PLUGIN_DIR := ../../plugins/$(PLUGIN_NAME)

.PHONY: build clean test

build:
	@echo "Building plugin $(PLUGIN_NAME)..."
	@mkdir -p $(PLUGIN_DIR)
	@CGO_ENABLED=1 go build -buildmode=plugin -o $(PLUGIN_DIR)/$(PLUGIN_NAME).so .
	@cp config.yaml $(PLUGIN_DIR)/
	@echo "Plugin built successfully: $(PLUGIN_DIR)/$(PLUGIN_NAME).so"

clean:
	@echo "Cleaning plugin $(PLUGIN_NAME)..."
	@rm -rf $(PLUGIN_DIR)
	@echo "Plugin cleaned"

test:
	@echo "Running tests for plugin $(PLUGIN_NAME)..."
	@go test -v ./...

debug:
	@echo "Debug mode for plugin $(PLUGIN_NAME)..."
	@LOG_LEVEL=debug go run .
```

## Сборка и развертывание

### Локальная разработка

```bash
# Сборка плагина
make build

# Запуск тестов
make test

# Очистка
make clean
```

### Проверка плагина

После сборки плагин будет доступен в директории `plugins/my-plugin/`. Сервер автоматически обнаружит и загрузит плагин при запуске.

## Лучшие практики

### 1. Обработка ошибок

```go
func (h *MyPluginHandler) HandlePaymentSuccess(payment *yapay.Payment) error {
    if err := h.processPayment(payment); err != nil {
        h.logger.WithError(err).Error("Failed to process payment")
        return fmt.Errorf("failed to process payment: %w", err)
    }
    return nil
}
```

### 2. Логирование

```go
func (h *MyPluginHandler) ValidateRequest(req *yapay.PaymentRequest) error {
    h.logger.WithFields(logrus.Fields{
        "amount":      req.Amount,
        "description": req.Description,
        "merchant_id": h.merchant.ID,
    }).Debug("Validating payment request")
    
    // Валидация...
    
    h.logger.Info("Payment request validated successfully")
    return nil
}
```

### 3. Валидация данных

```go
func (h *MyPluginHandler) ValidateRequest(req *yapay.PaymentRequest) error {
    // Проверка обязательных полей
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive, got: %d", req.Amount)
    }
    
    if req.Description == "" {
        return fmt.Errorf("description is required")
    }
    
    // Проверка лимитов
    if req.Amount > h.merchant.Metadata["max_amount"].(int) {
        return fmt.Errorf("amount exceeds maximum allowed: %d", req.Amount)
    }
    
    return nil
}
```

## Отладка

### Включение debug логов

```bash
LOG_LEVEL=debug go run cmd/server/main.go
```

### Проверка загрузки плагина

В логах сервера ищите сообщения:
- `Plugin loaded successfully`
- `Client loaded from plugin configuration`
- `Client handler registered`

### Частые проблемы

1. **Плагин не загружается**: Проверьте, что функции `NewHandler` и `NewPaymentGenerator` экспортированы
2. **Ошибки компиляции**: Убедитесь, что версия SDK совпадает с версией сервера
3. **Конфигурация не загружается**: Проверьте формат YAML файла и обязательные поля
