# Примеры конфигурации фронтенда

Этот файл содержит примеры конфигураций для различных сценариев интеграции фронтенда с Yapay API.

## Базовые конфигурации

### Sandbox режим (для разработки)

```javascript
const CONFIG = {
    merchantId: 'your-sandbox-merchant-id',
    apiServer: 'https://your-api-server.com',
    environment: 'sandbox'
};

const paymentData = {
    env: YaPay.PaymentEnv.Sandbox,
    version: 4,
    currencyCode: YaPay.CurrencyCode.Rub,
    merchantId: CONFIG.merchantId,
    totalAmount: '1000.00',
    availablePaymentMethods: ['CARD', 'SPLIT'],
};
```

### Production режим (для продакшена)

```javascript
const CONFIG = {
    merchantId: 'your-production-merchant-id',
    apiServer: 'https://your-api-server.com',
    environment: 'production'
};

const paymentData = {
    env: YaPay.PaymentEnv.Production,
    version: 4,
    currencyCode: YaPay.CurrencyCode.Rub,
    merchantId: CONFIG.merchantId,
    totalAmount: '1000.00',
    availablePaymentMethods: ['CARD', 'SPLIT'],
};
```

## Конфигурации кнопок

### Черная кнопка (фиксированная ширина)

```javascript
const buttonConfig = {
    type: YaPay.ButtonType.Pay,
    theme: YaPay.ButtonTheme.Black,
    width: YaPay.ButtonWidth.Auto,
};
```

### Белая кнопка (адаптивная ширина)

```javascript
const buttonConfig = {
    type: YaPay.ButtonType.Pay,
    theme: YaPay.ButtonTheme.White,
    width: YaPay.ButtonWidth.Max,
};
```

### Белая кнопка с обводкой

```javascript
const buttonConfig = {
    type: YaPay.ButtonType.Pay,
    theme: YaPay.ButtonTheme.WhiteOutlined,
    width: YaPay.ButtonWidth.Auto,
};
```

## Конфигурации виджетов

### Ultimate виджет (рекомендуемый)

```javascript
const widgetConfig = {
    widgetType: YaPay.WidgetType.Ultimate,
    customFields: {
        merchantName: 'Ваш магазин',
        merchantDomain: window.location.hostname
    }
};
```

### Миграция с других виджетов

```javascript
// С BnplPreview
const widgetConfig = {
    widgetType: YaPay.WidgetType.Ultimate, // было: YaPay.WidgetType.BnplPreview
};

// С Simple
const widgetConfig = {
    widgetType: YaPay.WidgetType.Ultimate, // было: YaPay.WidgetType.Simple
};

// С Info
const widgetConfig = {
    widgetType: YaPay.WidgetType.Ultimate, // было: YaPay.WidgetType.Info
};
```

## Конфигурации бейджей

### Бейдж Сплита

```javascript
const badgeConfig = {
    badgeType: YaPay.BadgeType.Split,
    theme: YaPay.BadgeTheme.Black,
    size: YaPay.BadgeSize.Medium
};
```

### Бейдж Яндекс.Пей

```javascript
const badgeConfig = {
    badgeType: YaPay.BadgeType.YaPay,
    theme: YaPay.BadgeTheme.White,
    size: YaPay.BadgeSize.Small
};
```

## Конфигурации для разных типов бизнеса

### Образовательная платформа

```javascript
const educationConfig = {
    merchantId: 'education-merchant-id',
    apiServer: 'https://api.education-platform.com',
    environment: 'production',
    metadata: {
        platform: 'Education',
        business_type: 'education',
        course_type: 'online',
        duration: '3 months'
    }
};
```

### Интернет-магазин

```javascript
const ecommerceConfig = {
    merchantId: 'ecommerce-merchant-id',
    apiServer: 'https://api.shop.com',
    environment: 'production',
    metadata: {
        platform: 'E-commerce',
        business_type: 'retail',
        product_category: 'electronics',
        shipping_method: 'express'
    }
};
```

### Подписочный сервис

```javascript
const subscriptionConfig = {
    merchantId: 'subscription-merchant-id',
    apiServer: 'https://api.subscription-service.com',
    environment: 'production',
    metadata: {
        platform: 'Subscription',
        business_type: 'subscription',
        billing_period: 'monthly',
        auto_renewal: true
    }
};
```

## Конфигурации безопасности

### CORS настройки

```javascript
// Проверка CORS
const corsConfig = {
    allowedOrigins: [
        'https://your-domain.com',
        'https://www.your-domain.com',
        'https://shop.your-domain.com'
    ],
    allowedMethods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Accept', 'Origin']
};
```

### CSRF защита

```javascript
const csrfConfig = {
    tokenHeader: 'X-CSRF-Token',
    tokenField: 'csrf_token',
    generateToken: () => {
        const array = new Uint8Array(16);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }
};
```

## Конфигурации для разных устройств

### Мобильные устройства

```javascript
const mobileConfig = {
    buttonConfig: {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.Black,
        width: YaPay.ButtonWidth.Max, // Адаптивная ширина для мобильных
    },
    widgetConfig: {
        widgetType: YaPay.WidgetType.Ultimate,
        // Оптимизация для мобильных
        customFields: {
            mobileOptimized: true,
            touchFriendly: true
        }
    }
};
```

### Десктоп

```javascript
const desktopConfig = {
    buttonConfig: {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.White,
        width: YaPay.ButtonWidth.Auto, // Фиксированная ширина для десктопа
    },
    widgetConfig: {
        widgetType: YaPay.WidgetType.Ultimate,
        customFields: {
            desktopOptimized: true,
            hoverEffects: true
        }
    }
};
```

## Конфигурации для разных валют

### Российские рубли (RUB)

```javascript
const rubConfig = {
    currencyCode: YaPay.CurrencyCode.Rub,
    currency: 'RUB',
    amountFormat: (amount) => `${amount.toFixed(2)} руб.`,
    locale: 'ru-RU'
};
```

### Узбекские сумы (UZS)

```javascript
const uzsConfig = {
    currencyCode: YaPay.CurrencyCode.Uzs,
    currency: 'UZS',
    amountFormat: (amount) => `${amount.toFixed(2)} сум`,
    locale: 'uz-UZ'
};
```

## Конфигурации для тестирования

### Тестовая среда

```javascript
const testConfig = {
    merchantId: 'test-merchant-id',
    apiServer: 'https://test-api.your-domain.com',
    environment: 'sandbox',
    debugMode: true,
    testData: {
        testUserId: 'test_user_123',
        testCourseId: 'test_course_456',
        testAmount: 1000
    }
};
```

### Локальная разработка

```javascript
const localConfig = {
    merchantId: 'local-merchant-id',
    apiServer: 'http://localhost:8080',
    environment: 'sandbox',
    debugMode: true,
    localTunnel: 'https://your-tunnel.ngrok.io' // Для webhook'ов
};
```

## Конфигурации мониторинга

### Логирование

```javascript
const loggingConfig = {
    level: 'info', // debug, info, warn, error
    console: true,
    remote: {
        enabled: true,
        endpoint: 'https://logs.your-domain.com/api/logs',
        batchSize: 10,
        flushInterval: 5000
    }
};
```

### Метрики

```javascript
const metricsConfig = {
    enabled: true,
    endpoint: 'https://metrics.your-domain.com/api/metrics',
    interval: 30000, // 30 секунд
    events: [
        'payment_created',
        'payment_success',
        'payment_failed',
        'button_clicked',
        'widget_mounted'
    ]
};
```

## Полная конфигурация

### Продакшен конфигурация

```javascript
const productionConfig = {
    // Основные настройки
    merchantId: 'your-production-merchant-id',
    apiServer: 'https://api.your-domain.com',
    environment: 'production',
    
    // Платежные данные
    paymentData: {
        env: YaPay.PaymentEnv.Production,
        version: 4,
        currencyCode: YaPay.CurrencyCode.Rub,
        availablePaymentMethods: ['CARD', 'SPLIT'],
    },
    
    // UI компоненты
    ui: {
        button: {
            type: YaPay.ButtonType.Pay,
            theme: YaPay.ButtonTheme.Black,
            width: YaPay.ButtonWidth.Max,
        },
        widget: {
            widgetType: YaPay.WidgetType.Ultimate,
            customFields: {
                merchantName: 'Ваш магазин',
                merchantDomain: window.location.hostname
            }
        },
        badge: {
            badgeType: YaPay.BadgeType.Split,
            theme: YaPay.BadgeTheme.Black,
            size: YaPay.BadgeSize.Medium
        }
    },
    
    // Безопасность
    security: {
        cors: {
            allowedOrigins: ['https://your-domain.com'],
            allowedMethods: ['GET', 'POST'],
            allowedHeaders: ['Content-Type', 'Accept', 'Origin']
        },
        csrf: {
            enabled: true,
            tokenHeader: 'X-CSRF-Token'
        }
    },
    
    // Мониторинг
    monitoring: {
        logging: {
            level: 'info',
            console: false,
            remote: {
                enabled: true,
                endpoint: 'https://logs.your-domain.com/api/logs'
            }
        },
        metrics: {
            enabled: true,
            endpoint: 'https://metrics.your-domain.com/api/metrics'
        }
    },
    
    // Обработка ошибок
    errorHandling: {
        retryAttempts: 3,
        retryDelay: 1000,
        fallbackEnabled: true,
        userFriendlyMessages: true
    }
};
```

Эта конфигурация может быть использована как основа для вашего проекта. Адаптируйте её под ваши конкретные потребности.
