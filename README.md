# Yapay SDK

SDK и инструменты для разработки плагинов для Yapay Payment Gateway.

## 🚀 Быстрый старт

### 1. Создание нового плагина

```bash
# Клонируем репозиторий
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk

# Копируем шаблон
cp -r examples/simple-plugin my-plugin
cd my-plugin

# Настраиваем зависимости
go mod init my-plugin
go mod tidy
```

### 2. Разработка плагина

```bash
# Сборка плагина
make build

# Запуск тестов
make test

# Отладка (если есть доступ к серверу)
make debug
```

### 3. Развертывание

#### Вариант A: GitHub Actions (если есть доступ к серверу)

```yaml
# .github/workflows/deploy.yml
name: Deploy Plugin
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Plugin
        run: make build
      - name: Deploy to Server
        run: |
          # Ваша логика развертывания
          scp my-plugin.so server:/path/to/plugins/
```

#### Вариант B: Ручное развертывание

```bash
# Сборка плагина
make build

# Передача файлов на сервер
scp my-plugin.so config.yaml server:/path/to/plugins/my-plugin/
```

## 📚 Документация

### Полная документация SDK

📖 **[Документация Yapay SDK](docs/README.md)** - Полное руководство по разработке плагинов

#### Основные разделы:

- 🚀 **[Быстрый старт](docs/development/getting-started.md)** - Создание первого плагина
- 📖 **[Справочник API](docs/api-reference/)** - Интерфейсы и OpenAPI спецификация
- 💡 **[Примеры использования](docs/examples/)** - Реальные сценарии (онлайн-школа, магазин)
- 🔧 **[Решение проблем](docs/troubleshooting/)** - Частые ошибки и отладка

#### Инструменты разработки:

- 🛠️ **[Отладка плагинов](docs/troubleshooting/debugging.md)** - Инструмент `plugin-debug`
- 📋 **[OpenAPI спецификация](docs/api-reference/payment-api.yaml)** - API для фронтенда

## 📁 Структура репозитория

```
yapay-sdk/
├── interfaces.go           # Интерфейсы и модели SDK
├── testing/                # Моки для тестирования
├── go.mod                  # Зависимости SDK
├── go.sum                  # Checksums зависимостей
├── examples/               # Примеры плагинов
│   └── simple-plugin/      # Базовый шаблон плагина
├── tools/                  # Инструменты разработки
│   └── plugin-debug/       # Инструмент отладки
├── docs/                   # 📚 Полная документация
│   ├── README.md           # Главная страница документации
│   ├── development/        # Руководства по разработке
│   ├── api-reference/      # Справочник API
│   ├── examples/           # Примеры использования
│   └── troubleshooting/   # Решение проблем
└── README.md               # Этот файл
```

## Создание плагина

### 1. Структура плагина

```
your-plugin/
├── main.go
├── go.mod
├── config.yaml
└── README.md
```

### 2. Пример main.go

```go
package main

import (
    "fmt"
    "github.com/metalmon/yapay-sdk"
    "github.com/sirupsen/logrus"
)

// Handler represents your plugin handler
type Handler struct {
    merchant *yapay.Merchant
    logger   *logrus.Logger
}

// NewHandler creates a new handler (обязательная функция)
func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler {
    return &Handler{
        merchant: merchant,
        logger:   logrus.New(),
    }
}

// Implement all required methods from yapay.ClientHandler interface
func (h *Handler) HandlePaymentCreated(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment created")
    return nil
}

func (h *Handler) HandlePaymentSuccess(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment successful")
    return nil
}

func (h *Handler) HandlePaymentFailed(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment failed")
    return nil
}

func (h *Handler) HandlePaymentCanceled(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment canceled")
    return nil
}

func (h *Handler) ValidateRequest(req *yapay.PaymentRequest) error {
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive")
    }
    return nil
}

func (h *Handler) GetMerchantConfig() *yapay.Merchant {
    return h.merchant
}

func (h *Handler) GetMerchantID() string {
    return h.merchant.Yandex.MerchantID
}

func (h *Handler) GetMerchantName() string {
    return h.merchant.Name
}

func (h *Handler) GetPaymentLinkGenerator() interface{} {
    return nil
}

func (h *Handler) SetPaymentLinkGenerator(generator interface{}) {
    // Optional: implement if you need payment link generation
}
```

### 3. Пример config.yaml

```yaml
name: "Your Plugin Name"
enabled: true
yandex:
  merchant_id: "your-merchant-id"
  secret_key: "your-secret-key"
  sandbox_mode: true
cors_origins:
  - "https://yourdomain.com"
notifications:
  telegram:
    enabled: true
    bot_token: "your-bot-token"
    chat_id: "your-chat-id"
  email:
    enabled: false
description: "Your plugin description"
domain: "yourdomain.com"
```

### 4. go.mod

```go
module your-plugin

go 1.21

require (
    github.com/metalmon/yapay-sdk v1.0.0
    github.com/sirupsen/logrus v1.9.3
)
```

## Сборка плагина

```bash
# Сборка плагина
CGO_ENABLED=1 go build -buildmode=plugin -o your-plugin.so .

# Копирование в папку плагинов
mkdir -p plugins/your-plugin
cp your-plugin.so plugins/your-plugin/
cp config.yaml plugins/your-plugin/
```

## Отладка

### 1. Инструмент отладки плагинов

```bash
# Сборка инструмента отладки
cd tools/plugin-debug
go build -o plugin-debug .

# Валидация плагина
./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test validate

# Симуляция платежа
./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test simulate -verbose

# Бенчмарк производительности
./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test benchmark
```

> 📖 **Подробная документация**: [Отладка плагинов](docs/troubleshooting/debugging.md)

### 2. Локальная разработка

```bash
# Запуск сервера в режиме разработки
make run

# Hot-reload при изменении файлов
# Конфиг файлы - автоматически
# .so файлы - при полной перезаписи (mv/cp)
```

### 3. Логирование

```go
h.logger.WithFields(logrus.Fields{
    "payment_id": payment.ID,
    "amount": payment.Amount,
}).Info("Payment processed")
```

### 4. Тестирование

```bash
# Проверка здоровья сервера
curl http://localhost:8080/api/v1/health/

# Создание платежа
curl -X POST http://localhost:8080/api/v1/payments/create \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "description": "Test payment",
    "return_url": "https://yourdomain.com/return"
  }'
```

## Версионирование

SDK следует семантическому версионированию:

- `v1.0.0` - первая стабильная версия
- `v1.1.0` - новые функции (обратная совместимость)
- `v2.0.0` - breaking changes

## Поддержка

- 📚 **Документация**: [docs/README.md](docs/README.md) - Полное руководство
- 💡 **Примеры**: [examples/](examples/) - Готовые плагины
- 🛠️ **Инструменты**: [tools/](tools/) - Отладка и разработка
- ❓ **Помощь**: https://t.me/metal_monkey
