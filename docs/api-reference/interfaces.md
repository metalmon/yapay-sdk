# Справочник по интерфейсам SDK

## ClientHandler

Основной интерфейс для обработки платежей клиента.

### Методы

#### HandlePaymentCreated(payment *Payment) error

Вызывается при создании нового платежа.

**Параметры:**
- `payment` - объект платежа с базовой информацией

**Пример:**
```go
func (h *MyHandler) HandlePaymentCreated(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "amount":     payment.Amount,
        "order_id":   payment.OrderID,
    }).Info("New payment created")
    
    // Дополнительная логика обработки
    return nil
}
```

#### HandlePaymentSuccess(payment *Payment) error

Вызывается при успешной оплате.

**Параметры:**
- `payment` - объект платежа с обновленным статусом

**Пример:**
```go
func (h *MyHandler) HandlePaymentSuccess(payment *yapay.Payment) error {
    // Активация курса, отправка уведомлений и т.д.
    if err := h.activateCourse(payment); err != nil {
        return fmt.Errorf("failed to activate course: %w", err)
    }
    return nil
}
```

#### HandlePaymentFailed(payment *Payment) error

Вызывается при неудачной оплате.

**Параметры:**
- `payment` - объект платежа с статусом "failed"

#### HandlePaymentCanceled(payment *Payment) error

Вызывается при отмене платежа.

**Параметры:**
- `payment` - объект платежа с статусом "canceled"

#### ValidateRequest(req *PaymentRequest) error

Валидирует входящий запрос на создание платежа.

**Параметры:**
- `req` - запрос на создание платежа

**Возвращает:**
- `error` - ошибка валидации или nil

**Пример:**
```go
func (h *MyHandler) ValidateRequest(req *yapay.PaymentRequest) error {
    // Проверка суммы
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive, got: %d", req.Amount)
    }
    
    // Проверка описания
    if req.Description == "" {
        return fmt.Errorf("description is required")
    }
    
    // Проверка метаданных
    if courseID, exists := req.Metadata["course_id"]; exists {
        if courseID == "" {
            return fmt.Errorf("course_id cannot be empty")
        }
    }
    
    return nil
}
```

#### GetMerchantConfig() *Merchant

Возвращает конфигурацию мерчанта.

**Возвращает:**
- `*Merchant` - объект конфигурации

#### GetMerchantID() string

Возвращает ID мерчанта.

**Возвращает:**
- `string` - ID мерчанта

#### GetMerchantName() string

Возвращает название мерчанта.

**Возвращает:**
- `string` - название мерчанта

#### GetPaymentLinkGenerator() interface{}

Возвращает генератор платежных ссылок.

**Возвращает:**
- `interface{}` - объект, реализующий PaymentLinkGenerator

#### SetPaymentLinkGenerator(generator interface{})

Устанавливает генератор платежных ссылок.

**Параметры:**
- `generator` - объект, реализующий PaymentLinkGenerator

## PaymentLinkGenerator

Интерфейс для генерации данных платежа.

### Методы

#### GeneratePaymentData(req *PaymentRequest) (*PaymentGenerationResult, error)

Генерирует данные для создания платежа.

**Параметры:**
- `req` - запрос на создание платежа

**Возвращает:**
- `*PaymentGenerationResult` - результат генерации
- `error` - ошибка генерации

**Пример:**
```go
func (g *MyPaymentGenerator) GeneratePaymentData(req *yapay.PaymentRequest) (*yapay.PaymentGenerationResult, error) {
    // Генерация уникального order_id
    orderID := fmt.Sprintf("my_plugin_%d_%d", time.Now().Unix(), req.Amount)
    
    // Подготовка данных для Яндекс.Пей
    paymentData := map[string]interface{}{
        "amount": map[string]interface{}{
            "value":    fmt.Sprintf("%.2f", float64(req.Amount)/100),
            "currency": req.Currency,
        },
        "confirmation": map[string]interface{}{
            "type":      "redirect",
            "return_url": req.ReturnURL,
        },
        "description": req.Description,
        "metadata":    req.Metadata,
    }
    
    return &yapay.PaymentGenerationResult{
        PaymentData: paymentData,
        OrderID:     orderID,
        Amount:      req.Amount,
        Currency:    req.Currency,
        Description: req.Description,
        ReturnURL:   req.ReturnURL,
        Metadata:    req.Metadata,
    }, nil
}
```

#### ValidatePriceFromBackend(req *PaymentRequest) error

Валидирует цену с бэкенда (опционально).

**Параметры:**
- `req` - запрос на создание платежа

**Возвращает:**
- `error` - ошибка валидации или nil

**Пример:**
```go
func (g *MyPaymentGenerator) ValidatePriceFromBackend(req *yapay.PaymentRequest) error {
    // Проверка цены курса в базе данных
    courseID, exists := req.Metadata["course_id"]
    if !exists {
        return nil // Пропускаем валидацию, если нет course_id
    }
    
    expectedPrice, err := g.getCoursePrice(courseID.(string))
    if err != nil {
        return fmt.Errorf("failed to get course price: %w", err)
    }
    
    if req.Amount != expectedPrice {
        return fmt.Errorf("price mismatch: expected %d, got %d", expectedPrice, req.Amount)
    }
    
    return nil
}
```

#### GetPaymentSettings() *PaymentSettings

Возвращает настройки платежа.

**Возвращает:**
- `*PaymentSettings` - настройки платежа

**Пример:**
```go
func (g *MyPaymentGenerator) GetPaymentSettings() *yapay.PaymentSettings {
    return &yapay.PaymentSettings{
        Currency:           g.merchant.Yandex.Currency,
        SandboxMode:        g.merchant.Yandex.SandboxMode,
        AutoConfirmTimeout: 1800, // 30 минут
        CustomFields: map[string]interface{}{
            "merchant_name": g.merchant.Name,
            "domain":        g.merchant.Domain,
        },
    }
}
```

#### CustomizeYandexPayload(payload map[string]interface{}) error

Кастомизирует payload для Яндекс.Пей (опционально).

**Параметры:**
- `payload` - payload для Яндекс.Пей

**Возвращает:**
- `error` - ошибка кастомизации или nil

**Пример:**
```go
func (g *MyPaymentGenerator) CustomizeYandexPayload(payload map[string]interface{}) error {
    // Добавляем дополнительные поля
    payload["receipt"] = map[string]interface{}{
        "customer": map[string]interface{}{
            "email": g.getCustomerEmail(),
        },
        "items": []map[string]interface{}{
            {
                "description": payload["description"],
                "amount":      payload["amount"],
                "quantity":   "1",
            },
        },
    }
    
    return nil
}
```

## Структуры данных

### PaymentRequest

```go
type PaymentRequest struct {
    Amount      int                    `json:"amount" yaml:"amount"`
    Currency    string                 `json:"currency" yaml:"currency"`
    Description string                 `json:"description" yaml:"description"`
    ReturnURL   string                 `json:"return_url" yaml:"return_url"`
    Metadata    map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
}
```

### Payment

```go
type Payment struct {
    ID          string                 `json:"id" yaml:"id"`
    OrderID     string                 `json:"order_id" yaml:"order_id"`
    MerchantID  string                 `json:"merchant_id" yaml:"merchant_id"`
    Amount      int                    `json:"amount" yaml:"amount"`
    Currency    string                 `json:"currency" yaml:"currency"`
    Description string                 `json:"description" yaml:"description"`
    Status      string                 `json:"status" yaml:"status"`
    ReturnURL   string                 `json:"return_url" yaml:"return_url"`
    PaymentURL  string                 `json:"payment_url,omitempty" yaml:"payment_url,omitempty"`
    Metadata    map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
    CreatedAt   string                 `json:"created_at,omitempty" yaml:"created_at,omitempty"`
    UpdatedAt   string                 `json:"updated_at,omitempty" yaml:"updated_at,omitempty"`
}
```

### Merchant

```go
type Merchant struct {
    ID            string                 `json:"id" yaml:"id"`
    Name          string                 `json:"name" yaml:"name"`
    Description   string                 `json:"description" yaml:"description"`
    Domain        string                 `json:"domain" yaml:"domain"`
    Enabled       bool                   `json:"enabled" yaml:"enabled"`
    SandboxMode   bool                   `json:"sandbox_mode" yaml:"sandbox_mode"`
    CORSOrigins   []string               `json:"cors_origins" yaml:"cors_origins"`
    RateLimit     int                    `json:"rate_limit" yaml:"rate_limit"`
    Metadata      map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
    Yandex        YandexConfig           `json:"yandex" yaml:"yandex"`
    Notifications NotificationConfig     `json:"notifications" yaml:"notifications"`
    FieldLabels   FieldLabels            `json:"field_labels,omitempty" yaml:"field_labels,omitempty"`
}
```

### PaymentGenerationResult

```go
type PaymentGenerationResult struct {
    PaymentData map[string]interface{} `json:"payment_data" yaml:"payment_data"`
    OrderID     string                 `json:"order_id" yaml:"order_id"`
    Amount      int                    `json:"amount" yaml:"amount"`
    Currency    string                 `json:"currency" yaml:"currency"`
    Description string                 `json:"description" yaml:"description"`
    ReturnURL   string                 `json:"return_url" yaml:"return_url"`
    Metadata    map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
}
```

## Константы

### NotificationType

```go
const (
    NotificationTypePaymentCreated NotificationType = "payment_created"
    NotificationTypePaymentSuccess NotificationType = "payment_success"
    NotificationTypePaymentFailed  NotificationType = "payment_failed"
    NotificationTypeSystemError    NotificationType = "system_error"
)
```

## Лучшие практики

### 1. Обработка ошибок

Всегда возвращайте ошибки с контекстом:

```go
if err != nil {
    return fmt.Errorf("failed to process payment %s: %w", payment.ID, err)
}
```

### 2. Логирование

Используйте структурированные логи:

```go
h.logger.WithFields(logrus.Fields{
    "payment_id": payment.ID,
    "amount":     payment.Amount,
    "status":     payment.Status,
}).Info("Processing payment")
```

### 3. Валидация

Валидируйте данные на входе:

```go
func (h *MyHandler) ValidateRequest(req *yapay.PaymentRequest) error {
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive, got: %d", req.Amount)
    }
    // ... другие проверки
    return nil
}
```

### 4. Безопасность

Никогда не логируйте секретные данные:

```go
// Хорошо
h.logger.WithField("merchant_id", merchant.ID).Info("Processing payment")

// Плохо
h.logger.WithField("secret_key", merchant.Yandex.SecretKey).Info("Processing payment")
```
