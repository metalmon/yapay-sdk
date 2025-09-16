# Частые проблемы и их решения

## Проблемы с загрузкой плагинов

### Ошибка: "plugin was built with a different version of package"

**Симптомы:**
```
Failed to load plugin: plugin.Open("plugins/my-plugin/my-plugin"): plugin was built with a different version of package github.com/metalmon/yapay-sdk
```

**Причина:** Плагин был собран с другой версией SDK, чем та, что используется на сервере.

**Решение:**
1. Проверьте версии SDK в `go.mod` файлах:
   ```bash
   # В директории плагина
   cd plugins/my-plugin
   cat go.mod | grep yapay-sdk
   
   # В директории сервера
   cd yapay
   cat go.mod | grep yapay-sdk
   ```

2. Обновите версию SDK в плагине:
   ```bash
   cd plugins/my-plugin
   go get github.com/metalmon/yapay-sdk@latest
   go mod tidy
   ```

3. Пересоберите плагин:
   ```bash
   make build
   ```

### Ошибка: "plugin not found"

**Симптомы:**
```
Plugin discovery completed: loaded_plugins=0
```

**Причина:** Плагин не найден в директории `plugins/`.

**Решение:**
1. Проверьте структуру директорий:
   ```
   plugins/
   └── my-plugin/
       ├── my-plugin.so
       └── config.yaml
   ```

2. Убедитесь, что плагин собран:
   ```bash
   cd plugins/my-plugin
   ls -la my-plugin.so
   ```

3. Проверьте права доступа:
   ```bash
   chmod +x my-plugin.so
   ```

### Ошибка: "failed to open plugin"

**Симптомы:**
```
Failed to load plugin: failed to open plugin my-plugin: plugin.Open("plugins/my-plugin/my-plugin"): plugin: not a Go plugin
```

**Причина:** Файл плагина поврежден или не является Go плагином.

**Решение:**
1. Пересоберите плагин:
   ```bash
   cd plugins/my-plugin
   make clean
   make build
   ```

2. Проверьте, что используется правильный флаг сборки:
   ```bash
   CGO_ENABLED=1 go build -buildmode=plugin -o my-plugin.so .
   ```

## Проблемы с конфигурацией

### Ошибка: "client not found"

**Симптомы:**
```
Unauthorized: merchant_id required and domain must be allowed
```

**Причина:** Клиент не найден в конфигурации или неправильно настроен CORS.

**Решение:**
1. Проверьте конфигурацию в `config.yaml`:
   ```yaml
   id: "your-merchant-id"
   domain: "your-domain.com"
   cors_origins:
     - "https://your-domain.com"
     - "https://www.your-domain.com"
   ```

2. Убедитесь, что `merchant_id` в запросе совпадает с `id` в конфигурации.

3. Проверьте, что домен в `cors_origins` совпадает с доменом, с которого делается запрос.

### Ошибка: "Invalid notification format"

**Симптомы:**
```
Invalid notification format
Failed to send webhook notification: invalid notification format
```

**Причина:** Неправильный формат уведомления в коде плагина.

**Решение:**
1. Убедитесь, что используете правильную структуру:
   ```go
   notification := &yapay.NotificationRequest{
       Type:      yapay.NotificationTypePaymentCreated,
       ClientID:  clientID,
       PaymentID: paymentID,
       Message:   message,
   }
   ```

2. Не используйте старый формат `map[string]interface{}`.

### Ошибка: "Yandex Pay API error: status 400"

**Симптомы:**
```
Yandex Pay API error: status 400, body: {"status":"fail","reasonCode":"BAD_REQUEST","details":{"currencyCode":["Must be one of: RUB, UZS."]}}
```

**Причина:** Неправильные данные в запросе к Яндекс.Пей API.

**Решение:**
1. Проверьте валюту в запросе:
   ```go
   // Правильно
   Currency: "RUB"
   
   // Неправильно
   Currency: "rub" // или пустая строка
   ```

2. Проверьте сумму (должна быть в копейках):
   ```go
   // Правильно
   Amount: 1000 // 10 рублей
   
   // Неправильно
   Amount: 10 // 10 копеек
   ```

## Проблемы с webhook'ами

### Ошибка: "Invalid JWT token"

**Симптомы:**
```
JWT token validation failed
Invalid JWT token
```

**Причина:** Неправильная валидация JWT токена от Яндекс.Пей.

**Решение:**
1. Проверьте настройки sandbox/production режима:
   ```yaml
   yandex:
     sandbox_mode: true  # для тестирования
     # или
     sandbox_mode: false # для продакшена
   ```

2. Убедитесь, что используете правильные ключи:
   - Sandbox: тестовые ключи
   - Production: продакшн ключи

### Ошибка: "Webhook body does not contain JWT token"

**Симптомы:**
```
Webhook body does not contain JWT token
```

**Причина:** Webhook от Яндекс.Пей приходит не в том формате, который ожидается.

**Решение:**
1. Проверьте, что webhook настроен правильно в консоли Яндекс.Пей
2. Убедитесь, что URL webhook'а правильный: `https://your-domain.com/v1/webhook`

## Проблемы с тестированием

### Ошибка: "No client handlers registered"

**Симптомы:**
```
No client handlers registered
```

**Причина:** Плагины не загрузились или не зарегистрировались.

**Решение:**
1. Проверьте логи загрузки плагинов:
   ```
   Plugin loaded successfully: plugin=my-plugin
   Client loaded from plugin configuration: client_id=my-client
   Client handler registered: client_id=my-client
   ```

2. Убедитесь, что функции экспортированы правильно:
   ```go
   // Правильно
   func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler
   func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator
   ```

### Ошибка: "Failed to create payment"

**Симптомы:**
```
Failed to create payment: failed to create payment with Yandex: Yandex Pay API error
```

**Причина:** Ошибка при вызове API Яндекс.Пей.

**Решение:**
1. Проверьте настройки в конфигурации:
   ```yaml
   yandex:
     merchant_id: "your-merchant-id"
     secret_key: "your-secret-key"
     sandbox_mode: true
   ```

2. Проверьте доступность API:
   ```bash
   curl -I https://sandbox.pay.yandex.ru/api/jwks
   ```

## Проблемы с производительностью

### Медленная загрузка плагинов

**Симптомы:** Сервер долго запускается из-за загрузки плагинов.

**Решение:**
1. Оптимизируйте инициализацию плагина:
   ```go
   func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler {
       // Минимальная инициализация
       return &MyHandler{
           merchant: merchant,
           logger:   logrus.New(),
       }
   }
   ```

2. Используйте lazy loading для тяжелых ресурсов:
   ```go
   func (h *MyHandler) getDatabase() *Database {
       if h.db == nil {
           h.db = NewDatabase()
       }
       return h.db
   }
   ```

### Высокое потребление памяти

**Симптомы:** Плагин потребляет много памяти.

**Решение:**
1. Освобождайте ресурсы:
   ```go
   func (h *MyHandler) HandlePaymentSuccess(payment *yapay.Payment) error {
       defer func() {
           // Освобождение ресурсов
           h.cleanup()
       }()
       
       // Обработка платежа
       return nil
   }
   ```

2. Используйте пулы соединений для БД.

## Отладка

### Включение debug логов

```bash
LOG_LEVEL=debug go run cmd/server/main.go
```

### Проверка состояния плагинов

```bash
curl http://localhost:8080/api/v1/health/
```

Ответ должен содержать информацию о загруженных плагинах:
```json
{
  "status": "healthy",
  "services": {
    "payment": {
      "status": "healthy",
      "clients": 1
    }
  }
}
```

### Тестирование плагина

```bash
cd plugins/my-plugin
go test -v ./...
```

### Проверка конфигурации

```bash
# Проверка синтаксиса YAML
python -c "import yaml; yaml.safe_load(open('config.yaml'))"
```

## Получение помощи

### Логи для диагностики

При обращении за помощью предоставьте:

1. Логи сервера при запуске
2. Логи при создании платежа
3. Конфигурацию плагина (без секретных данных)
4. Версии Go и SDK:
   ```bash
   go version
   cat go.mod | grep yapay-sdk
   ```

### Полезные команды

```bash
# Проверка версий
go version
go mod why github.com/metalmon/yapay-sdk

# Очистка кэша
go clean -modcache

# Пересборка плагина
cd plugins/my-plugin
make clean && make build

# Проверка зависимостей
go mod verify
```
