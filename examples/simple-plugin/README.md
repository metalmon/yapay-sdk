# Simple Plugin Example

Пример простого плагина для Yapay Payment Gateway, использующего SDK.

## Описание

Этот плагин демонстрирует:

- ✅ Базовую реализацию интерфейса `ClientHandler`
- ✅ Обработку жизненного цикла платежей
- ✅ Валидацию запросов
- ✅ Опциональную реализацию `PaymentLinkGenerator`
- ✅ Логирование событий
- ✅ Конфигурацию через YAML

## Структура

```
simple-plugin/
├── main.go          # Основной код плагина
├── go.mod           # Go модуль с зависимостями
├── config.yaml      # Конфигурация плагина
├── Makefile         # Сборка и установка
└── README.md        # Эта документация
```

## Установка

### 1. Установка зависимостей

```bash
go mod tidy
```

### 2. Сборка плагина

```bash
make build
```

### 3. Установка в Yapay

```bash
make install
```

### 4. Или все сразу

```bash
make dev
```

## Конфигурация

Отредактируйте `config.yaml`:

```yaml
id: "simple-plugin-client"
name: "Simple Plugin Example"
description: "Простой пример плагина для Yapay SDK"
domain: "your-domain.com"
enabled: true
security:
  request_enforcement: monitor  # strict | origin | monitor
  rate_limit: 100
  cors:
    origins:
      - "https://your-domain.com"
      - "https://www.your-domain.com"
      - "http://localhost:3000"

yandex:
  merchant_id: "your-yandex-merchant-id" # Замените на ваш ID
  secret_key: "your-yandex-secret-key" # Замените на ваш ключ
  sandbox_mode: true # true для тестирования
  currency: "RUB"

notifications:
  telegram:
    enabled: false # Включите при необходимости
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
  product_id: "ID товара"
  user_id: "ID пользователя"
  product_name: "Название товара"
```

## Разработка


### Логирование

Плагин логирует все события:

```go
h.logger.WithFields(logrus.Fields{
    "payment_id": payment.ID,
    "amount":     payment.Amount,
}).Info("Payment processed")
```

### Тестирование

```bash
# Запуск тестов
make test

# Проверка здоровья Yapay
curl http://localhost:8080/api/v1/health/

# Создание тестового платежа
curl -X POST http://localhost:8080/api/v1/payments/create \
  -H "Content-Type: application/json" \
  -d '{
    "merchant_id": "simple-plugin-client",
    "amount": 1000,
    "currency": "RUB",
    "description": "Test payment",
    "return_url": "https://your-domain.com/return",
    "metadata": {
      "product_id": "test_product_123",
      "user_id": "user_456",
      "product_name": "Test Product"
    }
  }'
```

## Функциональность

### Обработка платежей

Плагин обрабатывает все этапы жизненного цикла платежа:

1. **Создание** (`HandlePaymentCreated`) - логирование события
2. **Успех** (`HandlePaymentSuccess`) - обновление статуса, бизнес-логика
3. **Ошибка** (`HandlePaymentFailed`) - логирование ошибки
4. **Отмена** (`HandlePaymentCanceled`) - освобождение ресурсов

**Примечание:** Уведомления (Telegram, Email) создаются автоматически сервером на основе настроек в `config.yaml`.

### Валидация

Плагин валидирует входящие запросы:

- ✅ Сумма должна быть положительной
- ✅ Описание обязательно
- ✅ Return URL обязателен

### Генерация ссылок (опционально)

Плагин может генерировать данные для оплаты:

- ✅ Уникальный Order ID
- ✅ Настройки платежа
- ✅ Кастомизация payload для Yandex Pay

## Расширение

### Добавление новых методов

```go
func (h *Handler) CustomBusinessLogic() error {
    // Ваша бизнес-логика
    return nil
}
```

### Интеграция с внешними API

```go
func (h *Handler) HandlePaymentSuccess(payment *yapay.Payment) error {
    // Отправка данных в ваш API
    resp, err := http.Post("https://your-api.com/webhook",
        "application/json",
        bytes.NewBuffer(paymentData))

    if err != nil {
        return err
    }

    // Обработка ответа
    return nil
}
```

### Уведомления

Уведомления настраиваются в `config.yaml` и отправляются автоматически сервером:

```yaml
notifications:
  telegram:
    enabled: true
    chat_id: "your-telegram-chat-id"
    bot_token: "your-telegram-bot-token"
  email:
    enabled: true
    smtp_host: "smtp.gmail.com"
    smtp_port: 587
    username: "your-email@gmail.com"
    password: "your-password"
    from: "your-email@gmail.com"
```

Сервер автоматически отправляет уведомления при:
- Создании платежа
- Успешной оплате
- Ошибке оплаты
- Получении webhook от Яндекс.Пей

### Работа с базой данных

```go
func (h *Handler) HandlePaymentCreated(payment *yapay.Payment) error {
    // Сохранение в БД
    _, err := h.db.Exec(`
        INSERT INTO payments (id, amount, status, created_at)
        VALUES ($1, $2, $3, $4)
    `, payment.ID, payment.Amount, "created", time.Now())

    return err
}
```

## Отладка

### Инструмент plugin-debug

SDK включает мощный инструмент для отладки плагинов. Он позволяет тестировать плагины без запуска всего сервера.

#### Установка инструмента

```bash
cd ../../tools/plugin-debug
go build -o plugin-debug .
```

#### Использование

```bash
# Базовая проверка плагина
./plugin-debug -plugin simple-plugin -config config.yaml

# Валидация плагина
./plugin-debug -plugin simple-plugin -config config.yaml -test validate

# Симуляция платежа
./plugin-debug -plugin simple-plugin -config config.yaml -test simulate -verbose

# Бенчмарк производительности
./plugin-debug -plugin simple-plugin -config config.yaml -test benchmark
```

#### Режимы тестирования

1. **validate** - Проверяет корректность реализации интерфейсов
2. **simulate** - Симулирует полный цикл платежа
3. **benchmark** - Измеряет производительность

#### Пример вывода

```bash
$ ./plugin-debug -plugin simple-plugin -test validate -verbose

Loading plugin: simple-plugin
Loading plugin from: plugins/simple-plugin/simple-plugin.so
Loading config: config.yaml
Creating handler...
Validating handler...
✅ Handler validation passed

🧪 Running validation tests...
✅ Valid request passed
✅ negative amount correctly rejected: amount must be positive, got: -100
✅ empty description correctly rejected: description is required
✅ empty return URL correctly rejected: return URL is required
✅ HandlePaymentCreated passed
✅ HandlePaymentSuccess passed
✅ HandlePaymentFailed passed
✅ HandlePaymentCanceled passed
```

### Включение debug логирования

```go
logger := logrus.New()
logger.SetLevel(logrus.DebugLevel)
```

### Проверка конфигурации

```go
func (h *Handler) GetMerchantConfig() *yapay.Merchant {
    h.logger.WithFields(logrus.Fields{
        "merchant_id": h.merchant.Yandex.MerchantID,
        "sandbox_mode": h.merchant.Yandex.SandboxMode,
    }).Debug("Merchant configuration")

    return h.merchant
}
```

> **Подробная документация по отладке**: [Отладка плагинов](../../docs/troubleshooting/debugging.md)

## Поддержка

- **Документация SDK**: https://docs.metalmon.com/yapay
- **Примеры**: https://github.com/metalmon/yapay-examples
- **Поддержка**: support@metalmon.com
