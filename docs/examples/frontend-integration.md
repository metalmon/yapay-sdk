# Интеграция фронтенда с Yapay API

Этот раздел содержит практические примеры интеграции фронтенда с Yapay API для создания платежей через Яндекс.Пей.

## Содержание

- [Загрузка Яндекс.Пей SDK](#загрузка-яндекспей-sdk)
- [Кнопки оплаты](#кнопки-оплаты)
- [Виджеты](#виджеты)
- [Бейджи](#бейджи)
- [Полный пример интеграции](#полный-пример-интеграции)
- [Обработка ошибок](#обработка-ошибок)
- [Безопасность](#безопасность)

## Загрузка Яндекс.Пей SDK

Перед использованием компонентов Яндекс.Пей необходимо загрузить SDK. Есть несколько способов:

### Способ 1: Прямая загрузка в HTML

```html
<!DOCTYPE html>
<html>
<head>
    <title>Оплата товара</title>
    <!-- Загрузка Яндекс.Пей SDK -->
    <script src="https://pay.yandex.ru/sdk/v1/pay.js"></script>
</head>
<body>
    <!-- Ваш контент -->
</body>
</html>
```

### Способ 2: Динамическая загрузка через JavaScript

```javascript
// Проверяем, загружен ли уже SDK
if (typeof window.YaPay !== 'undefined') {
    console.log('Yandex Pay SDK already loaded');
    initializeYandexPay();
} else {
    console.log('Loading Yandex Pay SDK...');
    
    // Создаем элемент script
    const script = document.createElement('script');
    script.src = 'https://pay.yandex.ru/sdk/v1/pay.js';
    script.async = true;
    
    // Обработчики загрузки
    script.onload = function() {
        console.log('Yandex Pay SDK loaded successfully');
        console.log('YaPay object available:', typeof window.YaPay);
        initializeYandexPay();
    };
    
    script.onerror = function(error) {
        console.error('Failed to load Yandex Pay SDK:', error);
        alert('Ошибка загрузки платежной системы. Попробуйте обновить страницу.');
    };
    
    // Добавляем скрипт в документ
    document.head.appendChild(script);
}
```

### Способ 3: Загрузка с ожиданием готовности DOM

```javascript
// Загрузка SDK с ожиданием готовности DOM
function loadYandexPaySDK() {
    if (typeof window.YaPay !== 'undefined') {
        console.log('Yandex Pay SDK already loaded');
        initializeYandexPay();
        return;
    }

    console.log('Loading Yandex Pay SDK...');
    
    const script = document.createElement('script');
    script.src = 'https://pay.yandex.ru/sdk/v1/pay.js';
    script.async = true;
    
    script.onload = function() {
        console.log('Yandex Pay SDK loaded successfully');
        initializeYandexPay();
    };
    
    script.onerror = function(error) {
        console.error('Failed to load Yandex Pay SDK:', error);
        alert('Ошибка загрузки платежной системы. Попробуйте обновить страницу.');
    };
    
    document.head.appendChild(script);
}

// Инициализация при загрузке страницы
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadYandexPaySDK);
} else {
    loadYandexPaySDK();
}
```

### Проверка загрузки SDK

```javascript
// Проверка доступности SDK
function checkSDKAvailability() {
    if (typeof window.YaPay === 'undefined') {
        console.error('YaPay SDK not loaded');
        return false;
    }
    
    // Проверяем необходимые методы
    const requiredMethods = ['createSession'];
    for (const method of requiredMethods) {
        if (typeof window.YaPay[method] !== 'function') {
            console.error(`YaPay.${method} is not available`);
            return false;
        }
    }
    
    console.log('YaPay SDK is ready');
    return true;
}

// Использование
if (checkSDKAvailability()) {
    initializeYandexPay();
} else {
    console.error('SDK is not ready, retrying...');
    setTimeout(checkSDKAvailability, 1000);
}
```

### Обработка ошибок загрузки

```javascript
// Расширенная обработка ошибок загрузки
function loadYandexPaySDKWithRetry(maxRetries = 3) {
    let attempts = 0;
    
    function attemptLoad() {
        attempts++;
        
        if (typeof window.YaPay !== 'undefined') {
            console.log('Yandex Pay SDK already loaded');
            initializeYandexPay();
            return;
        }
        
        console.log(`Loading Yandex Pay SDK... (attempt ${attempts}/${maxRetries})`);
        
        const script = document.createElement('script');
        script.src = 'https://pay.yandex.ru/sdk/v1/pay.js';
        script.async = true;
        
        script.onload = function() {
            console.log('Yandex Pay SDK loaded successfully');
            initializeYandexPay();
        };
        
        script.onerror = function(error) {
            console.error(`Failed to load Yandex Pay SDK (attempt ${attempts}):`, error);
            
            if (attempts < maxRetries) {
                console.log(`Retrying in ${attempts * 1000}ms...`);
                setTimeout(attemptLoad, attempts * 1000);
            } else {
                console.error('Max retries reached, giving up');
                alert('Не удалось загрузить платежную систему. Проверьте подключение к интернету.');
            }
        };
        
        document.head.appendChild(script);
    }
    
    attemptLoad();
}
```

## Кнопки оплаты

### Базовая кнопка оплаты

Создание простой кнопки оплаты с интеграцией через Yapay API:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Оплата товара</title>
    <!-- Загрузка Яндекс.Пей SDK -->
    <script src="https://pay.yandex.ru/sdk/v1/pay.js"></script>
</head>
<body>
    <!-- Информация о товаре -->
    <div class="product-info">
        <h1 class="product-title">Название товара</h1>
        <div class="product-price">15 000 руб.</div>
    </div>
    
    <!-- Контейнер для кнопки оплаты -->
    <div id="yandex-pay-button"></div>
    
    <!-- Скрытые поля с данными заказа (опционально) -->
    <input type="hidden" name="productId" value="product_123">
    <input type="hidden" name="returnUrl" value="https://example.com/payment/success">
    
    <script>
        // Конфигурация мерчанта
        const MERCHANT_CONFIG = {
            merchantId: 'your-merchant-id',
            apiServer: 'https://your-api-server.com'
        };

        // Извлечение данных заказа из DOM
        function getOrderData() {
            const priceElement = document.querySelector('.product-price');
            const productNameElement = document.querySelector('.product-title');
            
            let price = 0;
            if (priceElement) {
                // Очистка цены от валюты и пробелов
                const priceText = priceElement.textContent.replace(/руб\./gi, '').replace(/\s/g, '');
                price = parseInt(priceText) || 0;
            }
            
            const productName = productNameElement?.textContent || 'Товар';
            
            return {
                price: price,
                productName: productName,
                priceFormatted: price.toFixed(2)
            };
        }

        // Извлечение метаданных из скрытых полей
        function extractMetadata() {
            return {
                productId: document.querySelector('input[name="productId"]')?.value || '',
                returnUrl: document.querySelector('input[name="returnUrl"]')?.value || '',
                userId: document.body.getAttribute('data-user-id') || '',
                userEmail: document.body.getAttribute('data-user-email') || ''
            };
        }

        // Создание платежа через Yapay API
        async function createPaymentRequest(orderData) {
            const metadata = extractMetadata();
            
            const response = await fetch(`${MERCHANT_CONFIG.apiServer}/api/v1/payments/create`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Origin': window.location.origin
                },
                body: JSON.stringify({
                    merchant_id: MERCHANT_CONFIG.merchantId,
                    amount: Math.round(orderData.price * 100), // Конвертация в копейки
                    currency: 'RUB',
                    description: orderData.productName,
                    return_url: metadata.returnUrl,
                    metadata: {
                        product_id: metadata.productId,
                        user_id: metadata.userId,
                        user_email: metadata.userEmail,
                        product_name: orderData.productName,
                        platform: 'Custom',
                        business_type: 'retail',
                        domain: window.location.hostname
                    }
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.payment_url) {
                return result.payment_url;
            } else {
                throw new Error(result.error || 'Payment creation failed');
            }
        }

        // Инициализация Яндекс.Пей
        function initializeYandexPay() {
            const YaPay = window.YaPay;
            
            if (!YaPay) {
                console.error('YaPay SDK not loaded');
                return;
            }

            const orderData = getOrderData();
            
            // Конфигурация платежных данных
            const paymentData = {
                env: YaPay.PaymentEnv.Sandbox, // Для продакшена используйте YaPay.PaymentEnv.Production
                version: 4,
                currencyCode: YaPay.CurrencyCode.Rub,
                merchantId: MERCHANT_CONFIG.merchantId,
                totalAmount: orderData.priceFormatted,
                availablePaymentMethods: ['CARD', 'SPLIT'],
            };

            // Обработчик клика по кнопке
            async function onPayButtonClick() {
                try {
                    const paymentUrl = await createPaymentRequest(orderData);
                    return paymentUrl;
                } catch (error) {
                    console.error('Payment creation failed:', error);
                    alert('Ошибка при создании платежа. Попробуйте позже.');
                    throw error;
                }
            }

            // Обработчик ошибок
            function onFormOpenError(reason) {
                console.error(`Payment error — ${reason}`);
                alert('Ошибка при открытии формы оплаты. Попробуйте позже.');
            }

            // Создание платежной сессии
            YaPay.createSession(paymentData, {
                onPayButtonClick: onPayButtonClick,
                onFormOpenError: onFormOpenError,
            })
            .then(function (paymentSession) {
                // Монтирование кнопки
                paymentSession.mountButton(document.querySelector('#yandex-pay-button'), {
                    type: YaPay.ButtonType.Pay,
                    theme: YaPay.ButtonTheme.Black,
                    width: YaPay.ButtonWidth.Auto,
                });
                
                console.log('Yandex Pay button mounted successfully');
            })
            .catch(function (err) {
                console.error('Failed to create Yandex Pay session:', err);
                alert('Ошибка инициализации платежной системы.');
            });
        }

        // Загрузка SDK и инициализация
        if (typeof window.YaPay !== 'undefined') {
            initializeYandexPay();
        } else {
            window.addEventListener('load', initializeYandexPay);
        }
    </script>
</body>
</html>
```

### Кастомизация кнопки

```javascript
// Различные варианты кнопок
const buttonConfigs = {
    // Черная кнопка с фиксированной шириной
    blackFixed: {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.Black,
        width: YaPay.ButtonWidth.Auto,
    },
    
    // Белая кнопка с адаптивной шириной
    whiteAdaptive: {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.White,
        width: YaPay.ButtonWidth.Max,
    },
    
    // Белая кнопка с обводкой
    whiteOutlined: {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.WhiteOutlined,
        width: YaPay.ButtonWidth.Auto,
    }
};

// Применение конфигурации
paymentSession.mountButton(document.querySelector('#yandex-pay-button'), buttonConfigs.blackFixed);
```

### CSS стилизация

```css
<style>
  .ya-pay-button {
    height: 40px !important;
    border-radius: 10px !important;
    margin: 10px 0;
  }
  
  /* Адаптивная кнопка */
  .ya-pay-button.adaptive {
    width: 100% !important;
    max-width: 300px;
  }
</style>
```

## Виджеты

**⚠️ Важно:** Виджеты и бейджи Яндекс.Пей **только отображают информацию** о доступных способах оплаты. Они **НЕ создают платежи** сами по себе. 

Для создания платежей **обязательно нужен обработчик `onPayButtonClick`**, который вызывает наш Yapay API:

```javascript
// Этот обработчик ОБЯЗАТЕЛЬНО нужен для создания платежей
async function onPayButtonClick() {
    // ВЫЗОВ НАШЕГО API для создания платежа
    const paymentUrl = await createPaymentRequest(orderData);
    return paymentUrl; // Возвращаем URL для оплаты
}
```

### Поток взаимодействия

```
Пользователь кликает кнопку оплаты
           ↓
onPayButtonClick() вызывается
           ↓
createPaymentRequest() → Yapay API
           ↓
POST /api/v1/payments/create
           ↓
Получаем payment_url от Яндекс.Пей
           ↓
Возвращаем URL в onPayButtonClick()
           ↓
Яндекс.Пей открывает форму оплаты
```

**Компоненты:**
- **Бейдж** - показывает "Сплит доступен"
- **Виджет** - показывает способы оплаты + кнопку
- **Кнопка** - запускает процесс оплаты
- **onPayButtonClick** - вызывает наш API
- **Наш API** - создает платеж в Яндекс.Пей

### Ultimate виджет

Ultimate виджет предоставляет полную информацию о доступных способах оплаты, включая Сплит. **Важно:** виджет сам по себе не создает платежи - для этого нужен обработчик `onPayButtonClick`, который вызывает наш API:

```javascript
// Конфигурация Ultimate виджета с интеграцией API
function mountUltimateWidget(paymentSession, orderData) {
    paymentSession.mountWidget(document.querySelector('#yandex-pay-widget'), {
        widgetType: YaPay.WidgetType.Ultimate,
        customFields: {
            merchantName: 'Ваш магазин',
            merchantDomain: window.location.hostname
        }
    });
}

// Обработчик клика по кнопке оплаты в виджете
async function onPayButtonClick() {
    try {
        console.log('Payment button clicked in widget!');
        
        // ВЫЗОВ НАШЕГО API для создания платежа
        const paymentUrl = await createPaymentRequest(orderData);
        
        console.log('Payment URL received:', paymentUrl);
        return paymentUrl;
        
    } catch (error) {
        console.error('Payment creation failed:', error);
        alert('Ошибка при создании платежа. Попробуйте позже.');
        throw error;
    }
}

// Создание платежа через наш API
async function createPaymentRequest(orderData) {
    const metadata = extractMetadata();
    
    const response = await fetch(`${CONFIG.apiServer}/api/v1/payments/create`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': window.location.origin
        },
        body: JSON.stringify({
            merchant_id: CONFIG.merchantId,
            amount: Math.round(orderData.price * 100),
            currency: 'RUB',
            description: orderData.productName,
            return_url: metadata.returnUrl,
            metadata: {
                product_id: metadata.productId,
                user_id: metadata.userId,
                product_name: orderData.productName,
                platform: 'Custom',
                business_type: 'retail',
                domain: window.location.hostname
            }
        })
    });

    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();
    
    if (result.payment_url) {
        return result.payment_url;
    } else {
        throw new Error(result.error || 'Payment creation failed');
    }
}

// Использование в платежной сессии
YaPay.createSession(paymentData, {
    onPayButtonClick: onPayButtonClick, // ← Здесь вызывается наш API
    onFormOpenError: onFormOpenError,
})
.then(function (paymentSession) {
    // Монтирование виджета
    mountUltimateWidget(paymentSession, orderData);
})
.catch(function (err) {
    console.error('Failed to create session:', err);
});
```

### Миграция с других виджетов

```javascript
// Миграция с BnplPreview
// Старый код:
// widgetType: YaPay.WidgetType.BnplPreview

// Новый код:
widgetType: YaPay.WidgetType.Ultimate

// Миграция с Simple
// Старый код:
// widgetType: YaPay.WidgetType.Simple

// Новый код:
widgetType: YaPay.WidgetType.Ultimate

// Миграция с Info
// Старый код:
// widgetType: YaPay.WidgetType.Info

// Новый код:
widgetType: YaPay.WidgetType.Ultimate
```

## Бейджи

**⚠️ Напоминание:** Бейджи **только показывают информацию** о доступности Сплита или Яндекс.Пей. Они **НЕ создают платежи**.

Для создания платежей нужен обработчик `onPayButtonClick` + кнопка или виджет для оплаты.

### Бейдж доступности Сплита

Бейдж показывает информацию о доступности Сплита, но **не создает платежи**. Для создания платежей нужен обработчик `onPayButtonClick`, который вызывает наш API:

```javascript
// Создание бейджа для отображения информации о Сплите
function createSplitBadge(paymentSession) {
    paymentSession.mountBadge(document.querySelector('#split-badge'), {
        badgeType: YaPay.BadgeType.Split,
        theme: YaPay.BadgeTheme.Black,
        size: YaPay.BadgeSize.Medium
    });
}

// Обработчик клика по кнопке оплаты (вызывается при клике на кнопку в виджете или отдельной кнопке)
async function onPayButtonClick() {
    try {
        console.log('Payment button clicked!');
        
        // ВЫЗОВ НАШЕГО API для создания платежа
        const paymentUrl = await createPaymentRequest(orderData);
        
        console.log('Payment URL received:', paymentUrl);
        return paymentUrl;
        
    } catch (error) {
        console.error('Payment creation failed:', error);
        alert('Ошибка при создании платежа. Попробуйте позже.');
        throw error;
    }
}

// Создание платежа через наш API
async function createPaymentRequest(orderData) {
    const metadata = extractMetadata();
    
    const response = await fetch(`${CONFIG.apiServer}/api/v1/payments/create`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': window.location.origin
        },
        body: JSON.stringify({
            merchant_id: CONFIG.merchantId,
            amount: Math.round(orderData.price * 100),
            currency: 'RUB',
            description: orderData.productName,
            return_url: metadata.returnUrl,
            metadata: {
                product_id: metadata.productId,
                user_id: metadata.userId,
                product_name: orderData.productName,
                platform: 'Custom',
                business_type: 'retail',
                domain: window.location.hostname
            }
        })
    });

    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();
    
    if (result.payment_url) {
        return result.payment_url;
    } else {
        throw new Error(result.error || 'Payment creation failed');
    }
}

// Использование в платежной сессии
YaPay.createSession(paymentData, {
    onPayButtonClick: onPayButtonClick, // ← Здесь вызывается наш API
    onFormOpenError: onFormOpenError,
})
.then(function (paymentSession) {
    // Создание бейджа
    createSplitBadge(paymentSession);
    
    // Также можно добавить кнопку или виджет для оплаты
    paymentSession.mountButton(document.querySelector('#yandex-pay-button'), {
        type: YaPay.ButtonType.Pay,
        theme: YaPay.ButtonTheme.Black,
        width: YaPay.ButtonWidth.Auto,
    });
})
.catch(function (err) {
    console.error('Failed to create session:', err);
});
```

### Различные типы бейджей

```javascript
const badgeConfigs = {
    // Бейдж Сплита
    split: {
        badgeType: YaPay.BadgeType.Split,
        theme: YaPay.BadgeTheme.Black,
        size: YaPay.BadgeSize.Medium
    },
    
    // Бейдж Яндекс.Пей
    yandexPay: {
        badgeType: YaPay.BadgeType.YaPay,
        theme: YaPay.BadgeTheme.White,
        size: YaPay.BadgeSize.Small
    }
};
```

## Полный пример интеграции

### HTML структура

```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Оплата курса</title>
    <script src="https://pay.yandex.ru/sdk/v1/pay.js"></script>
    <style>
        .payment-container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            font-family: Arial, sans-serif;
        }
        
        .product-info {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .product-title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .product-price {
            font-size: 18px;
            color: #333;
            margin-bottom: 20px;
        }
        
        .payment-section {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
        }
        
        .payment-section h3 {
            margin-top: 0;
        }
        
        #yandex-pay-button {
            margin: 10px 0;
        }
        
        #yandex-pay-widget {
            margin: 10px 0;
        }
        
        #split-badge {
            margin: 10px 0;
        }
        
        .error-message {
            color: #d32f2f;
            background-color: #ffebee;
            border: 1px solid #ffcdd2;
            border-radius: 4px;
            padding: 10px;
            margin: 10px 0;
            display: none;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body data-user-id="user_123" data-user-email="user@example.com">
    <div class="payment-container">
        <!-- Информация о товаре -->
        <div class="product-info">
            <h1 class="product-title">Название товара</h1>
            <div class="product-price">15 000 руб.</div>
            <p>Описание товара или услуги.</p>
        </div>
        
        <!-- Скрытые поля с данными -->
        <input type="hidden" name="productId" value="product_123">
        <input type="hidden" name="returnUrl" value="https://example.com/payment/success">
        
        <!-- Сообщения об ошибках -->
        <div id="error-message" class="error-message"></div>
        
        <!-- Загрузка -->
        <div id="loading" class="loading">Загрузка платежной системы...</div>
        
        <!-- Секция оплаты -->
        <div class="payment-section" id="payment-section" style="display: none;">
            <h3>Способы оплаты</h3>
            
            <!-- Бейдж Сплита -->
            <div id="split-badge"></div>
            
            <!-- Виджет оплаты -->
            <div id="yandex-pay-widget"></div>
            
            <!-- Кнопка оплаты -->
            <div id="yandex-pay-button"></div>
        </div>
    </div>
    
    <script>
        // Конфигурация
        const CONFIG = {
            merchantId: 'your-merchant-id',
            apiServer: 'https://your-api-server.com',
            environment: 'sandbox' // 'sandbox' или 'production'
        };

        // Утилиты
        const Utils = {
            showError: (message) => {
                const errorDiv = document.getElementById('error-message');
                errorDiv.textContent = message;
                errorDiv.style.display = 'block';
            },
            
            hideError: () => {
                const errorDiv = document.getElementById('error-message');
                errorDiv.style.display = 'none';
            },
            
            showLoading: () => {
                document.getElementById('loading').style.display = 'block';
                document.getElementById('payment-section').style.display = 'none';
            },
            
            hideLoading: () => {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('payment-section').style.display = 'block';
            }
        };

        // Извлечение данных заказа
        function getOrderData() {
            const priceElement = document.querySelector('.product-price');
            const productNameElement = document.querySelector('.product-title');
            
            let price = 0;
            if (priceElement) {
                const priceText = priceElement.textContent.replace(/руб\./gi, '').replace(/\s/g, '');
                price = parseInt(priceText) || 0;
            }
            
            const productName = productNameElement?.textContent || 'Товар';
            
            return {
                price: price,
                productName: productName,
                priceFormatted: price.toFixed(2)
            };
        }

        // Извлечение метаданных
        function extractMetadata() {
            return {
                productId: document.querySelector('input[name="productId"]')?.value || '',
                returnUrl: document.querySelector('input[name="returnUrl"]')?.value || '',
                userId: document.body.getAttribute('data-user-id') || '',
                userEmail: document.body.getAttribute('data-user-email') || ''
            };
        }

        // Создание платежа
        async function createPaymentRequest(orderData) {
            const metadata = extractMetadata();
            
            try {
                const response = await fetch(`${CONFIG.apiServer}/api/v1/payments/create`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Origin': window.location.origin
                    },
                    body: JSON.stringify({
                        merchant_id: CONFIG.merchantId,
                        amount: Math.round(orderData.price * 100),
                        currency: 'RUB',
                        description: orderData.productName,
                        return_url: metadata.returnUrl,
                        metadata: {
                            product_id: metadata.productId,
                            user_id: metadata.userId,
                            user_email: metadata.userEmail,
                            product_name: orderData.productName,
                            platform: 'Custom',
                            business_type: 'retail',
                            domain: window.location.hostname
                        }
                    })
                });

                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
                }

                const result = await response.json();
                
                if (result.payment_url) {
                    return result.payment_url;
                } else {
                    throw new Error(result.error || 'Payment creation failed');
                }
            } catch (error) {
                console.error('Payment request failed:', error);
                
                if (error.name === 'TypeError' && error.message.includes('fetch')) {
                    throw new Error('Ошибка CORS: сервер не разрешает запросы с данного домена.');
                }
                
                throw error;
            }
        }

        // Инициализация Яндекс.Пей
        function initializeYandexPay() {
            const YaPay = window.YaPay;
            
            if (!YaPay) {
                Utils.showError('Ошибка инициализации платежной системы. Попробуйте обновить страницу.');
                return;
            }
            
            // Проверяем доступность необходимых методов
            if (typeof YaPay.createSession !== 'function') {
                Utils.showError('YaPay.createSession не доступен. Проверьте версию SDK.');
                return;
            }

            const orderData = getOrderData();
            
            // Конфигурация платежных данных
            const paymentData = {
                env: CONFIG.environment === 'production' ? YaPay.PaymentEnv.Production : YaPay.PaymentEnv.Sandbox,
                version: 4,
                currencyCode: YaPay.CurrencyCode.Rub,
                merchantId: CONFIG.merchantId,
                totalAmount: orderData.priceFormatted,
                availablePaymentMethods: ['CARD', 'SPLIT'],
            };

            // Обработчик клика по кнопке
            async function onPayButtonClick() {
                try {
                    Utils.hideError();
                    const paymentUrl = await createPaymentRequest(orderData);
                    return paymentUrl;
                } catch (error) {
                    Utils.showError('Ошибка при создании платежа. Попробуйте позже или обратитесь в поддержку.');
                    throw error;
                }
            }

            // Обработчик ошибок
            function onFormOpenError(reason) {
                console.error(`Payment error — ${reason}`);
                Utils.showError('Ошибка при открытии формы оплаты. Попробуйте позже или выберите другой способ оплаты.');
            }

            // Создание платежной сессии
            YaPay.createSession(paymentData, {
                onPayButtonClick: onPayButtonClick,
                onFormOpenError: onFormOpenError,
            })
            .then(function (paymentSession) {
                // Монтирование бейджа Сплита
                paymentSession.mountBadge(document.querySelector('#split-badge'), {
                    badgeType: YaPay.BadgeType.Split,
                    theme: YaPay.BadgeTheme.Black,
                    size: YaPay.BadgeSize.Medium
                });
                
                // Монтирование Ultimate виджета
                paymentSession.mountWidget(document.querySelector('#yandex-pay-widget'), {
                    widgetType: YaPay.WidgetType.Ultimate
                });
                
                // Монтирование кнопки оплаты
                paymentSession.mountButton(document.querySelector('#yandex-pay-button'), {
                    type: YaPay.ButtonType.Pay,
                    theme: YaPay.ButtonTheme.Black,
                    width: YaPay.ButtonWidth.Max,
                });
                
                Utils.hideLoading();
                console.log('Yandex Pay components mounted successfully');
            })
            .catch(function (err) {
                console.error('Failed to create Yandex Pay session:', err);
                Utils.showError('Ошибка инициализации платежной системы. Попробуйте обновить страницу.');
            });
        }

        // Загрузка Яндекс.Пей SDK
        function loadYandexPaySDK() {
            if (typeof window.YaPay !== 'undefined') {
                console.log('Yandex Pay SDK already loaded');
                initializeYandexPay();
                return;
            }

            console.log('Loading Yandex Pay SDK...');
            
            // Создаем элемент script
            const script = document.createElement('script');
            script.src = 'https://pay.yandex.ru/sdk/v1/pay.js';
            script.async = true;
            
            // Обработчики загрузки
            script.onload = function() {
                console.log('Yandex Pay SDK loaded successfully');
                console.log('YaPay object available:', typeof window.YaPay);
                initializeYandexPay();
            };
            
            script.onerror = function(error) {
                console.error('Failed to load Yandex Pay SDK:', error);
                console.error('Script src:', script.src);
                Utils.showError('Ошибка загрузки платежной системы. Попробуйте обновить страницу.');
            };
            
            // Добавляем скрипт в документ
            document.head.appendChild(script);
        }

        // Инициализация при загрузке страницы
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', loadYandexPaySDK);
        } else {
            loadYandexPaySDK();
        }
    </script>
</body>
</html>
```

## Обработка ошибок

### Типы ошибок и их обработка

```javascript
// Обработка различных типов ошибок
function handlePaymentError(error, context) {
    console.error(`Payment error in ${context}:`, error);
    
    if (error.name === 'TypeError' && error.message.includes('fetch')) {
        // CORS ошибка
        Utils.showError('Ошибка подключения к серверу. Проверьте настройки CORS.');
    } else if (error.message.includes('HTTP error')) {
        // HTTP ошибка
        Utils.showError('Ошибка сервера. Попробуйте позже.');
    } else if (error.message.includes('Payment creation failed')) {
        // Ошибка создания платежа
        Utils.showError('Не удалось создать платеж. Проверьте данные и попробуйте снова.');
    } else {
        // Общая ошибка
        Utils.showError('Произошла ошибка. Попробуйте позже или обратитесь в поддержку.');
    }
}

// Использование в обработчиках
async function onPayButtonClick() {
    try {
        const paymentUrl = await createPaymentRequest(orderData);
        return paymentUrl;
    } catch (error) {
        handlePaymentError(error, 'payment creation');
        throw error;
    }
}

function onFormOpenError(reason) {
    handlePaymentError(new Error(reason), 'form opening');
}
```

### Retry механизм

```javascript
// Повторные попытки создания платежа
async function createPaymentWithRetry(orderData, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await createPaymentRequest(orderData);
        } catch (error) {
            console.log(`Payment attempt ${attempt} failed:`, error);
            
            if (attempt === maxRetries) {
                throw error;
            }
            
            // Экспоненциальная задержка
            const delay = Math.pow(2, attempt) * 1000;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}
```

## Безопасность

### Валидация данных

```javascript
// Валидация данных заказа
function validateOrderData(orderData) {
    const errors = [];
    
    if (!orderData.price || orderData.price <= 0) {
        errors.push('Некорректная цена товара');
    }
    
    if (!orderData.productName || orderData.productName.trim() === '') {
        errors.push('Название товара обязательно');
    }
    
    if (orderData.price > 1000000) { // Максимальная сумма
        errors.push('Сумма превышает максимально допустимую');
    }
    
    return errors;
}

// Использование валидации
function getOrderData() {
    const orderData = {
        price: parseInt(document.querySelector('.course-price')?.textContent.replace(/руб\./gi, '').replace(/\s/g, '') || '0'),
        productName: document.querySelector('.course-title')?.textContent || 'Курс',
        priceFormatted: '0.00'
    };
    
    orderData.priceFormatted = orderData.price.toFixed(2);
    
    const validationErrors = validateOrderData(orderData);
    if (validationErrors.length > 0) {
        throw new Error(`Ошибки валидации: ${validationErrors.join(', ')}`);
    }
    
    return orderData;
}
```

### CORS настройки

```javascript
// Проверка CORS настроек
function checkCORSConfiguration() {
    const origin = window.location.origin;
    const apiServer = CONFIG.apiServer;
    
    console.log('Checking CORS configuration:');
    console.log('Origin:', origin);
    console.log('API Server:', apiServer);
    
    // Предварительная проверка CORS
    fetch(`${apiServer}/api/v1/health`, {
        method: 'GET',
        headers: {
            'Origin': origin
        }
    })
    .then(response => {
        if (response.ok) {
            console.log('CORS configuration is correct');
        } else {
            console.warn('CORS check failed:', response.status);
        }
    })
    .catch(error => {
        console.error('CORS check error:', error);
    });
}
```

### Защита от CSRF

```javascript
// Генерация CSRF токена
function generateCSRFToken() {
    const array = new Uint8Array(16);
    crypto.getRandomValues(array);
    return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

// Добавление CSRF токена к запросам
async function createPaymentRequest(orderData) {
    const csrfToken = generateCSRFToken();
    
    const response = await fetch(`${CONFIG.apiServer}/api/v1/payments/create`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Origin': window.location.origin,
            'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
            // ... данные платежа
            csrf_token: csrfToken
        })
    });
    
    // ... обработка ответа
}
```

## Заключение

Этот пример демонстрирует полную интеграцию фронтенда с Yapay API для создания платежей через Яндекс.Пей. Код включает:

- ✅ Извлечение данных заказа из DOM
- ✅ Создание платежей через Yapay API
- ✅ Интеграцию с Яндекс.Пей SDK
- ✅ Поддержку кнопок, виджетов и бейджей
- ✅ Обработку ошибок и retry механизмы
- ✅ Валидацию данных и безопасность
- ✅ Адаптивный дизайн

Для продакшена не забудьте:
1. Изменить `environment` на `'production'`
2. Обновить `merchantId` на реальный
3. Настроить CORS на сервере
4. Добавить мониторинг и логирование
5. Протестировать на различных устройствах и браузерах
