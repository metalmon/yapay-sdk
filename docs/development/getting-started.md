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
func NewHandler(merchant *yapay.Merchant) interface{}

// NewPaymentGenerator создает генератор платежных данных (опционально)
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator
```

## Создание нового плагина

### 1. Инициализация проекта

```bash
# Создаем плагин из шаблона
make new-plugin-my-plugin
cd src/my-plugin

# Плагин уже настроен с правильными зависимостями
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

// MyPluginHandler реализует интерфейсы PaymentEventHandler и VersionedPlugin
type MyPluginHandler struct {
    merchant *yapay.Merchant
    logger   *logrus.Logger
}

// NewHandler создает новый обработчик клиента
func NewHandler(merchant *yapay.Merchant) interface{} {
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

// Реализация методов PaymentEventHandler
func (h *MyPluginHandler) OnPaymentCreated(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment created")
    return nil
}

func (h *MyPluginHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    // Определяем среду для разной обработки
    environment := payment.Environment
    if environment == "" {
        environment = "unknown" // Fallback для старых webhook'ов
    }

    h.logger.WithFields(logrus.Fields{
        "payment_id":  payment.ID,
        "amount":      payment.Amount,
        "environment": environment,
    }).Info("Payment succeeded")

    // Разная логика для разных сред
    switch environment {
    case "sandbox":
        h.logger.Info("Test payment - skipping service activation")
        // Тестовая среда - только логируем, не активируем реальные сервисы
        
    case "production":
        h.logger.Info("Production payment - activating services")
        // Продакшн среда - активируем реальные сервисы
        if err := h.activateServices(payment); err != nil {
            return fmt.Errorf("failed to activate services: %w", err)
        }
        
    default:
        h.logger.Warn("Unknown environment - using safe fallback")
        // Fallback для неизвестных сред
    }
    
    return nil
}

func (h *MyPluginHandler) OnPaymentFailed(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment failed")
    return nil
}

func (h *MyPluginHandler) OnPaymentCanceled(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
    }).Info("Payment canceled")
    return nil
}

// Реализация интерфейса VersionedPlugin (обязательно)
func (h *MyPluginHandler) GetSDKVersion() string {
    return yapay.GetSDKVersion()
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

### 4. Сборка и тестирование

**Используйте команды из корневого Makefile SDK:**

```bash
# Из корня yapay-sdk проекта
make build-plugin-my-plugin    # Умная сборка (автоматически определяет окружение)
make test-plugins             # Тестирование всех плагинов
make debug-plugin-my-plugin   # Отладка плагина
make clean                    # Очистка артефактов
```

## Сборка плагинов для совместимости

### Важность совместимости

**Критически важно**: Плагины должны быть собраны с использованием того же builder-образа, что и основной Yapay сервер, для обеспечения 100% совместимости. У разработчика плагина нет доступа к исходному коду сервера - только к готовому образу с бинарником.

### Система сборки

Yapay SDK использует **официальный builder-образ** `metalmon/yapay:builder`, который содержит:
- **Тот же Go 1.21** - как в production сервере
- **Тот же Alpine Linux** - как в production среде  
- **Те же зависимости** - предзагружены из основного проекта
- **Идентичные build flags** - для полной совместимости

### Команды сборки

```bash
# Проверить доступность builder-образа
make check-compatibility

# Собрать все примеры плагинов
make build-plugins

# Собрать конкретный плагин
make build-plugin-my-plugin

# Запустить тесты
make test

# Очистить артефакты сборки
make clean
```

### Процесс сборки

Каждый плагин собирается в Docker контейнере с официальным builder-образом:

1. **Монтирование исходников** в контейнер
2. **Компиляция с идентичными параметрами**:
   - `CGO_ENABLED=1`
   - `GOOS=linux GOARCH=amd64`
   - `-buildmode=plugin`
   - `GOPRIVATE=github.com/metalmon/yapay-sdk`
3. **Копирование результата** в `plugins/` директорию

### Проверка совместимости

```bash
make check-compatibility
```

Эта команда автоматически определяет:
- **Окружение разработки** (хост, Docker, Alpine devcontainer)
- **Доступность Docker** (если нужен)
- **Наличие builder-образа** (будет подгружен автоматически при необходимости)

### Умная сборка

SDK автоматически определяет окружение и выбирает оптимальный способ сборки:
- **В Alpine devcontainer** → прямая сборка
- **В другом Docker контейнере** → использование builder-образа
- **На хосте** → автоматическая подгрузка builder-образа

## Сборка и развертывание

### Локальная разработка

```bash
# Проверка совместимости
make check-compatibility

# Сборка плагина для совместимости
make build-plugin-my-plugin

# Запуск тестов
make test

# Очистка
make clean
```

### Проверка плагина

После сборки плагин будет доступен в директории `plugins/my-plugin/`. Плагин собран с использованием официального builder-образа и гарантированно совместим с production сервером.

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

### 3. Работа с Environment

Используйте поле `Environment` для определения среды платежа:

```go
func (h *MyPluginHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    environment := payment.Environment
    if environment == "" {
        environment = "unknown" // Fallback для старых webhook'ов
    }

    switch environment {
    case "sandbox":
        // Тестовая среда - безопасная обработка
        h.logger.Info("Test payment received - using safe handling")
        
        // Пример: логируем, но не активируем реальные сервисы
        h.logTestPayment(payment)
        
    case "production":
        // Продакшн среда - полная обработка
        h.logger.Info("Production payment received - activating services")
        
        // Пример: активируем реальные сервисы
        if err := h.activateRealServices(payment); err != nil {
            return fmt.Errorf("failed to activate services: %w", err)
        }
        
        // Отправляем реальные уведомления
        if err := h.sendRealNotifications(payment); err != nil {
            h.logger.WithError(err).Warn("Failed to send notifications")
        }
        
    default:
        // Неизвестная среда - безопасный fallback
        h.logger.Warn("Unknown environment - using safe fallback")
        h.logSafePayment(payment)
    }
    
    return nil
}

// Вспомогательные методы
func (h *MyPluginHandler) logTestPayment(payment *yapay.Payment) {
    h.logger.WithFields(logrus.Fields{
        "payment_id":  payment.ID,
        "amount":      payment.Amount,
        "environment": "test",
    }).Info("Test payment processed safely")
}

func (h *MyPluginHandler) activateRealServices(payment *yapay.Payment) error {
    // Реальная активация сервисов для продакшн платежей
    return nil
}

func (h *MyPluginHandler) sendRealNotifications(payment *yapay.Payment) error {
    // Отправка реальных уведомлений для продакшн платежей
    return nil
}

func (h *MyPluginHandler) logSafePayment(payment *yapay.Payment) {
    // Безопасное логирование для неизвестных сред
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "environment": "unknown",
    }).Info("Payment processed with safe fallback")
}
```

**Преимущества использования Environment:**
- **Безопасность**: Тестовые платежи не активируют реальные сервисы
- **Отладка**: Легко отличить тестовые и реальные платежи в логах
- **Гибкость**: Разная логика для разных сред
- **Совместимость**: Fallback для старых webhook'ов

### 4. Валидация данных

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
