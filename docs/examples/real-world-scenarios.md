# Реальные сценарии использования

## Сценарий 1: Онлайн-школа с курсами

### Описание

Онлайн-школа продает курсы программирования. Каждый курс имеет фиксированную цену, и после оплаты пользователь получает доступ к материалам.

### Конфигурация

```yaml
id: "programming-school"
name: "Programming School"
description: "Онлайн-школа программирования"
domain: "programming-school.com"
enabled: true
sandbox_mode: true
security:
  request_enforcement: strict  # strict | origin | monitor
  rate_limit: 1000
  cors:
    origins:
      - "https://programming-school.com"
      - "https://www.programming-school.com"

yandex:
  merchant_id: "your-yandex-merchant-id"
  secret_key: "your-yandex-secret-key"
  sandbox_mode: true
  currency: "RUB"

notifications:
  telegram:
    enabled: true
    chat_id: "your-telegram-chat-id"
    bot_token: "your-telegram-bot-token"

field_labels:
  course_id: "ID курса"
  user_id: "ID пользователя"
  course_name: "Название курса"
  user_email: "Email пользователя"
```

### Реализация плагина

```go
package main

import (
    "fmt"
    "time"
    
    "github.com/metalmon/yapay-sdk"
    "github.com/sirupsen/logrus"
)

// ProgrammingSchoolHandler обрабатывает платежи для онлайн-школы
type ProgrammingSchoolHandler struct {
    merchant *yapay.Merchant
    logger   *logrus.Logger
    db       *Database // Предполагаем наличие базы данных
}

// NewHandler создает новый обработчик
func NewHandler(merchant *yapay.Merchant) interface{} {
    return &ProgrammingSchoolHandler{
        merchant: merchant,
        logger:   logrus.New(),
        db:       NewDatabase(), // Инициализация БД
    }
}

// NewPaymentGenerator создает генератор платежей
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator {
    return &ProgrammingSchoolPaymentGenerator{
        merchant: merchant,
        logger:   logger,
        db:       NewDatabase(),
    }
}


// OnPaymentSuccess обрабатывает успешную оплату
func (h *ProgrammingSchoolHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    // Определяем среду для разной обработки
    environment := payment.Environment
    if environment == "" {
        environment = "unknown" // Fallback для старых webhook'ов
    }

    h.logger.WithFields(logrus.Fields{
        "payment_id":  payment.ID,
        "order_id":    payment.OrderID,
        "amount":      payment.Amount,
        "environment": environment,
    }).Info("Processing successful payment")
    
    // Извлекаем данные из метаданных
    courseID, exists := payment.Metadata["course_id"]
    if !exists {
        return fmt.Errorf("course_id not found in payment metadata")
    }
    
    userID, exists := payment.Metadata["user_id"]
    if !exists {
        return fmt.Errorf("user_id not found in payment metadata")
    }
    
    // Разная логика для разных сред
    switch environment {
    case "sandbox":
        h.logger.Info("Test payment - logging course access without granting real access")
        // Тестовая среда - только логируем, не предоставляем реальный доступ
        h.logTestCourseAccess(userID.(string), courseID.(string))
        
    case "production":
        h.logger.Info("Production payment - granting real course access")
        // Продакшн среда - предоставляем реальный доступ
        if err := h.db.GrantCourseAccess(userID.(string), courseID.(string)); err != nil {
            h.logger.WithError(err).Error("Failed to grant course access")
            return fmt.Errorf("failed to grant course access: %w", err)
        }
        
        // Отправляем реальное приветственное письмо
        if err := h.sendWelcomeEmail(userID.(string), courseID.(string)); err != nil {
            h.logger.WithError(err).Warn("Failed to send welcome email")
            // Не возвращаем ошибку, так как доступ уже предоставлен
        }
        
    default:
        h.logger.Warn("Unknown environment - using safe fallback")
        // Fallback для неизвестных сред - безопасное логирование
        h.logSafeCourseAccess(userID.(string), courseID.(string))
    }
    
    h.logger.WithFields(logrus.Fields{
        "user_id":     userID,
        "course_id":   courseID,
        "environment": environment,
    }).Info("Course access processed successfully")
    
    return nil
}

// OnPaymentFailed обрабатывает неудачную оплату
func (h *ProgrammingSchoolHandler) OnPaymentFailed(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "order_id":   payment.OrderID,
    }).Info("Payment failed")
    
    // Можно отправить уведомление пользователю
    // или сохранить информацию для повторной попытки
    
    return nil
}

// Остальные методы PaymentEventHandler...
func (h *ProgrammingSchoolHandler) OnPaymentCreated(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment created")
    return nil
}

func (h *ProgrammingSchoolHandler) OnPaymentCanceled(payment *yapay.Payment) error {
    h.logger.WithField("payment_id", payment.ID).Info("Payment canceled")
    return nil
}

// Реализация интерфейса VersionedPlugin (обязательно)
func (h *ProgrammingSchoolHandler) GetSDKVersion() string {
    return yapay.GetSDKVersion()
}

// ProgrammingSchoolPaymentGenerator генерирует данные для платежей
type ProgrammingSchoolPaymentGenerator struct {
    merchant *yapay.Merchant
    logger   *logrus.Logger
    db       *Database
}

// GeneratePaymentData генерирует данные для создания платежа
func (g *ProgrammingSchoolPaymentGenerator) GeneratePaymentData(req *yapay.PaymentRequest) (*yapay.PaymentGenerationResult, error) {
    // Генерируем уникальный order_id
    orderID := fmt.Sprintf("course_%d_%s", time.Now().Unix(), req.Metadata["course_id"])
    
    // Получаем информацию о курсе
    courseID := req.Metadata["course_id"].(string)
    course, err := g.db.GetCourse(courseID)
    if err != nil {
        return nil, fmt.Errorf("failed to get course: %w", err)
    }
    
    // Подготавливаем данные для Яндекс.Пей
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
        "metadata": map[string]interface{}{
            "course_id":   courseID,
            "course_name": course.Name,
            "user_id":     req.Metadata["user_id"],
            "user_email":  req.Metadata["user_email"],
        },
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

// ValidatePriceFromBackend валидирует цену с бэкенда
func (g *ProgrammingSchoolPaymentGenerator) ValidatePriceFromBackend(req *yapay.PaymentRequest) error {
    courseID, exists := req.Metadata["course_id"]
    if !exists {
        return nil // Пропускаем валидацию, если нет course_id
    }
    
    course, err := g.db.GetCourse(courseID.(string))
    if err != nil {
        return fmt.Errorf("failed to get course: %w", err)
    }
    
    if req.Amount != course.Price {
        return fmt.Errorf("price mismatch: expected %d, got %d", course.Price, req.Amount)
    }
    
    return nil
}

// GetPaymentSettings возвращает настройки платежа
func (g *ProgrammingSchoolPaymentGenerator) GetPaymentSettings() *yapay.PaymentSettings {
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

// CustomizeYandexPayload кастомизирует payload для Яндекс.Пей
func (g *ProgrammingSchoolPaymentGenerator) CustomizeYandexPayload(payload map[string]interface{}) error {
    // Добавляем информацию о курсе в receipt
    if courseID, exists := payload["metadata"].(map[string]interface{})["course_id"]; exists {
        course, err := g.db.GetCourse(courseID.(string))
        if err == nil {
            payload["receipt"] = map[string]interface{}{
                "customer": map[string]interface{}{
                    "email": payload["metadata"].(map[string]interface{})["user_email"],
                },
                "items": []map[string]interface{}{
                    {
                        "description": course.Name,
                        "amount":      payload["amount"],
                        "quantity":    "1",
                        "vat_code":    "1", // НДС 20%
                    },
                },
            }
        }
    }
    
    return nil
}

// Вспомогательные методы для работы с Environment
func (h *ProgrammingSchoolHandler) logTestCourseAccess(userID, courseID string) {
    h.logger.WithFields(logrus.Fields{
        "user_id":     userID,
        "course_id":   courseID,
        "environment": "test",
    }).Info("Test course access logged (no real access granted)")
}

func (h *ProgrammingSchoolHandler) logSafeCourseAccess(userID, courseID string) {
    h.logger.WithFields(logrus.Fields{
        "user_id":     userID,
        "course_id":   courseID,
        "environment": "unknown",
    }).Warn("Safe course access logged (unknown environment)")
}

func (h *ProgrammingSchoolHandler) sendWelcomeEmail(userID, courseID string) error {
    // Реализация отправки email
    return nil
}

// Database представляет интерфейс к базе данных
type Database struct {
    // Реализация подключения к БД
}

func NewDatabase() *Database {
    return &Database{}
}

func (db *Database) GetCourse(courseID string) (*Course, error) {
    // Реализация получения курса из БД
    return &Course{
        ID:    courseID,
        Name:  "Основы программирования",
        Price: 5000, // 50 рублей в копейках
    }, nil
}

func (db *Database) GrantCourseAccess(userID, courseID string) error {
    // Реализация предоставления доступа к курсу
    return nil
}

type Course struct {
    ID    string
    Name  string
    Price int
}
```

### Использование с фронтенда

```javascript
// Создание платежа
const createPayment = async (courseId, userId, userEmail) => {
    const response = await fetch('/api/v1/payments/create', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            merchant_id: 'programming-school',
            amount: 5000, // 50 рублей в копейках
            currency: 'RUB',
            description: 'Оплата курса "Основы программирования"',
            return_url: 'https://programming-school.com/payment/return',
            metadata: {
                course_id: courseId,
                user_id: userId,
                user_email: userEmail,
                course_name: 'Основы программирования'
            }
        })
    });
    
    const result = await response.json();
    
    if (result.success) {
        // Перенаправляем на страницу оплаты
        window.location.href = result.payment_url;
    } else {
        console.error('Payment creation failed:', result.error);
    }
};
```

## Сценарий 2: Магазин с корзиной

### Описание

Интернет-магазин с корзиной товаров. Пользователь может добавить несколько товаров в корзину и оплатить их одним платежом.

### Реализация

```go

// OnPaymentSuccess для магазина
func (h *ShopHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    items, exists := payment.Metadata["items"]
    if !exists {
        return fmt.Errorf("items not found in payment metadata")
    }
    
    itemsList := items.([]map[string]interface{})
    
    // Создаем заказ
    orderID := fmt.Sprintf("order_%d", time.Now().Unix())
    order := &Order{
        ID:        orderID,
        PaymentID: payment.ID,
        Items:     itemsList,
        Status:    "paid",
        CreatedAt: time.Now(),
    }
    
    // Сохраняем заказ
    if err := h.db.CreateOrder(order); err != nil {
        return fmt.Errorf("failed to create order: %w", err)
    }
    
    // Резервируем товары на складе
    for _, item := range itemsList {
        itemID := item["id"].(string)
        quantity := int(item["quantity"].(float64))
        
        if err := h.db.ReserveProduct(itemID, quantity); err != nil {
            h.logger.WithError(err).Error("Failed to reserve product")
            // Можно откатить заказ или отправить в очередь на обработку
        }
    }
    
    // Отправляем уведомление о заказе
    if err := h.sendOrderNotification(order); err != nil {
        h.logger.WithError(err).Warn("Failed to send order notification")
    }
    
    return nil
}
```

## Сценарий 3: Подписка на сервис

### Описание

Сервис с ежемесячной подпиской. Пользователь оплачивает подписку и получает доступ к функциям сервиса на месяц.

### Реализация

```go
// OnPaymentSuccess для подписки
func (h *SubscriptionHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    userID, exists := payment.Metadata["user_id"]
    if !exists {
        return fmt.Errorf("user_id not found in payment metadata")
    }
    
    planID, exists := payment.Metadata["plan_id"]
    if !exists {
        return fmt.Errorf("plan_id not found in payment metadata")
    }
    
    // Получаем план подписки
    plan, err := h.db.GetSubscriptionPlan(planID.(string))
    if err != nil {
        return fmt.Errorf("failed to get subscription plan: %w", err)
    }
    
    // Создаем или обновляем подписку
    subscription := &Subscription{
        UserID:    userID.(string),
        PlanID:    planID.(string),
        Status:    "active",
        StartDate: time.Now(),
        EndDate:   time.Now().AddDate(0, 1, 0), // +1 месяц
        PaymentID: payment.ID,
    }
    
    if err := h.db.CreateOrUpdateSubscription(subscription); err != nil {
        return fmt.Errorf("failed to create subscription: %w", err)
    }
    
    // Активируем функции сервиса для пользователя
    if err := h.activateUserFeatures(userID.(string), plan); err != nil {
        h.logger.WithError(err).Error("Failed to activate user features")
        return fmt.Errorf("failed to activate user features: %w", err)
    }
    
    // Отправляем уведомление о активации подписки
    if err := h.sendSubscriptionActivatedNotification(userID.(string), plan); err != nil {
        h.logger.WithError(err).Warn("Failed to send subscription notification")
    }
    
    return nil
}
```

## Лучшие практики

### 1. Идемпотентность

Обработчики должны быть идемпотентными - повторный вызов с теми же данными не должен вызывать побочных эффектов:

```go
func (h *MyHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    // Проверяем, не обработан ли уже этот платеж
    if h.isPaymentProcessed(payment.ID) {
        h.logger.WithField("payment_id", payment.ID).Info("Payment already processed")
        return nil
    }
    
    // Обрабатываем платеж
    // ...
    
    // Отмечаем как обработанный
    h.markPaymentAsProcessed(payment.ID)
    
    return nil
}
```

### 2. Обработка ошибок

Всегда логируйте ошибки и возвращайте их с контекстом:

```go
func (h *MyHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    if err := h.processPayment(payment); err != nil {
        h.logger.WithFields(logrus.Fields{
            "payment_id": payment.ID,
            "error":      err.Error(),
        }).Error("Failed to process payment")
        return fmt.Errorf("failed to process payment %s: %w", payment.ID, err)
    }
    return nil
}
```

### 3. Работа с Environment

Используйте поле `Environment` для безопасной обработки тестовых и реальных платежей:

```go
func (h *MyHandler) OnPaymentSuccess(payment *yapay.Payment) error {
    environment := payment.Environment
    if environment == "" {
        environment = "unknown" // Fallback для старых webhook'ов
    }

    switch environment {
    case "sandbox":
        // Тестовая среда - безопасная обработка
        h.logger.Info("Test payment - using safe handling")
        
        // Пример: логируем, но не активируем реальные сервисы
        h.logTestActivity(payment)
        
    case "production":
        // Продакшн среда - полная обработка
        h.logger.Info("Production payment - activating real services")
        
        // Пример: активируем реальные сервисы
        if err := h.activateRealServices(payment); err != nil {
            return fmt.Errorf("failed to activate services: %w", err)
        }
        
    default:
        // Неизвестная среда - безопасный fallback
        h.logger.Warn("Unknown environment - using safe fallback")
        h.logSafeActivity(payment)
    }
    
    return nil
}

// Вспомогательные методы
func (h *MyHandler) logTestActivity(payment *yapay.Payment) {
    h.logger.WithFields(logrus.Fields{
        "payment_id":  payment.ID,
        "environment": "test",
    }).Info("Test payment processed safely")
}

func (h *MyHandler) activateRealServices(payment *yapay.Payment) error {
    // Реальная активация сервисов для продакшн платежей
    return nil
}

func (h *MyHandler) logSafeActivity(payment *yapay.Payment) {
    h.logger.WithFields(logrus.Fields{
        "payment_id":  payment.ID,
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

Всегда валидируйте входящие данные:

