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
name: "Simple Plugin Example"
enabled: true
yandex:
  merchant_id: "your-merchant-id" # Замените на ваш ID
  secret_key: "your-secret-key" # Замените на ваш ключ
  sandbox_mode: true # true для тестирования
cors_origins:
  - "https://yourdomain.com" # Ваши домены
notifications:
  telegram:
    enabled: false # Включите при необходимости
    bot_token: "your-bot-token"
    chat_id: "your-chat-id"
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
    "amount": 1000,
    "description": "Test payment",
    "return_url": "https://yourdomain.com/return"
  }'
```

## Функциональность

### Обработка платежей

Плагин обрабатывает все этапы жизненного цикла платежа:

1. **Создание** (`HandlePaymentCreated`) - логирование, сохранение в БД
2. **Успех** (`HandlePaymentSuccess`) - обновление статуса, уведомления
3. **Ошибка** (`HandlePaymentFailed`) - логирование ошибки, уведомления
4. **Отмена** (`HandlePaymentCanceled`) - освобождение ресурсов

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
    // Отправка уведомления в ваш API
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

## Поддержка

- **Документация SDK**: https://docs.metalmon.com/yapay
- **Примеры**: https://github.com/metalmon/yapay-examples
- **Поддержка**: support@metalmon.com
