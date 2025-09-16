# Отладка плагинов

## Инструмент plugin-debug

SDK включает мощный инструмент для отладки плагинов `plugin-debug`. Он позволяет тестировать плагины без запуска всего сервера.

### Установка инструмента

```bash
cd tools/plugin-debug
go build -o plugin-debug .
```

### Использование

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

### Параметры командной строки

- `-plugin <name>` - Имя плагина (обязательный параметр)
- `-config <path>` - Путь к файлу конфигурации (опционально)
- `-test <mode>` - Режим тестирования: `validate`, `simulate`, `benchmark`
- `-verbose` - Подробный вывод
- `-plugins-dir <dir>` - Директория с плагинами (по умолчанию: `plugins`)

### Режимы тестирования

#### 1. validate - Валидация плагина

Проверяет корректность реализации интерфейсов:

- ✅ Валидация запросов (валидные и невалидные данные)
- ✅ Проверка методов жизненного цикла платежей
- ✅ Тестирование генератора платежей
- ✅ Проверка обязательных методов

**Пример вывода:**
```bash
$ ./plugin-debug -plugin simple-plugin -test validate -verbose

Loading plugin: simple-plugin
Loading plugin from: plugins/simple-plugin/simple-plugin.so
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

#### 2. simulate - Симуляция платежа

Симулирует полный цикл платежа:

- 🎭 Создание платежа
- 🎭 Обработка успешной оплаты
- 🔗 Тестирование генератора платежей
- ⚙️ Проверка настроек платежа

**Пример вывода:**
```bash
$ ./plugin-debug -plugin simple-plugin -test simulate -verbose

🎭 Running simulation tests...
1. Payment created...
   Waiting 100ms...
2. Payment successful...
✅ Payment simulation completed successfully

🔗 Testing payment generator...
   Generating payment data...
✅ Payment data generated: OrderID=simple_1694857890_1000, Amount=1000
   Getting payment settings...
✅ Payment settings: Currency=RUB, Sandbox=true
```

#### 3. benchmark - Бенчмарк производительности

Измеряет производительность плагина:

- ⚡ Скорость обработки платежей
- ⚡ Производительность валидации
- ⚡ Скорость генерации данных

**Пример вывода:**
```bash
$ ./plugin-debug -plugin simple-plugin -test benchmark

⚡ Running benchmark tests...
Benchmarking HandlePaymentCreated...
✅ 1000 operations in 2.5ms (400000 ops/sec)
Benchmarking ValidateRequest...
✅ 1000 operations in 1.2ms (833333 ops/sec)
Benchmarking GeneratePaymentData...
✅ 1000 operations in 3.1ms (322580 ops/sec)
```

## Отладка в IDE

### VS Code

Создайте файл `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Plugin",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "program": "${workspaceFolder}/tools/plugin-debug",
            "args": [
                "-plugin", "simple-plugin",
                "-config", "examples/simple-plugin/config.yaml",
                "-test", "simulate",
                "-verbose"
            ],
            "cwd": "${workspaceFolder}/tools/plugin-debug"
        }
    ]
}
```

### GoLand

1. Создайте новую конфигурацию "Go Build"
2. Установите:
   - **Run kind**: File
   - **Files**: `tools/plugin-debug/main.go`
   - **Working directory**: `tools/plugin-debug`
   - **Program arguments**: `-plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test simulate -verbose`

## Отладка в коде

### Создание debug.go

Создайте файл `debug.go` в директории плагина:

```go
package main

import (
    "fmt"
    "log"
    
    "github.com/metalmon/yapay-sdk"
    "github.com/metalmon/yapay-sdk/testing"
    "gopkg.in/yaml.v3"
)

func main() {
    // Загружаем конфигурацию
    data, err := os.ReadFile("config.yaml")
    if err != nil {
        log.Fatalf("Failed to read config: %v", err)
    }
    
    var merchant yapay.Merchant
    if err := yaml.Unmarshal(data, &merchant); err != nil {
        log.Fatalf("Failed to parse config: %v", err)
    }
    
    // Создаем обработчик
    handler := NewHandler(&merchant)
    
    // Тестируем валидацию
    testData := testing.NewTestData()
    request := testData.CreateTestPaymentRequest()
    
    fmt.Println("Testing validation...")
    if err := handler.ValidateRequest(request); err != nil {
        log.Printf("Validation failed: %v", err)
    } else {
        fmt.Println("✅ Validation passed")
    }
    
    // Тестируем жизненный цикл платежа
    payment := testData.CreateTestPayment()
    
    fmt.Println("Testing payment lifecycle...")
    if err := handler.HandlePaymentCreated(payment); err != nil {
        log.Printf("HandlePaymentCreated failed: %v", err)
    } else {
        fmt.Println("✅ HandlePaymentCreated passed")
    }
    
    if err := handler.HandlePaymentSuccess(payment); err != nil {
        log.Printf("HandlePaymentSuccess failed: %v", err)
    } else {
        fmt.Println("✅ HandlePaymentSuccess passed")
    }
}
```

Запуск:
```bash
go run debug.go
```

## Отладка с реальными данными

### Тестирование с реальной конфигурацией

```bash
# Используйте реальную конфигурацию
./plugin-debug -plugin my-plugin -config /path/to/real/config.yaml -test simulate
```

### Тестирование с разными данными

Создайте файл `test-data.yaml`:

```yaml
id: "test-client"
name: "Test Client"
description: "Test configuration"
domain: "test.example.com"
enabled: true
sandbox_mode: true
cors_origins:
  - "https://test.example.com"
rate_limit: 100

yandex:
  merchant_id: "test-merchant-id"
  secret_key: "test-secret-key"
  sandbox_mode: true
  currency: "RUB"

notifications:
  telegram:
    enabled: true
    chat_id: "test-chat-id"
    bot_token: "test-bot-token"
  email:
    enabled: false

field_labels:
  product_id: "ID товара"
  user_id: "ID пользователя"
```

```bash
./plugin-debug -plugin my-plugin -config test-data.yaml -test validate
```

## Частые проблемы при отладке

### Плагин не загружается

```bash
# Проверьте, что плагин собран
ls -la plugins/my-plugin/my-plugin.so

# Проверьте права доступа
chmod +x plugins/my-plugin/my-plugin.so

# Проверьте зависимости
ldd plugins/my-plugin/my-plugin.so
```

### Ошибки конфигурации

```bash
# Проверьте синтаксис YAML
python -c "import yaml; yaml.safe_load(open('config.yaml'))"

# Проверьте обязательные поля
./plugin-debug -plugin my-plugin -config config.yaml -test validate
```

### Проблемы с производительностью

```bash
# Запустите бенчмарк
./plugin-debug -plugin my-plugin -test benchmark

# Проверьте профилирование
go tool pprof http://localhost:6060/debug/pprof/profile
```

## Интеграция с CI/CD

### GitHub Actions

```yaml
name: Test Plugin
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v3
        with:
          go-version: 1.21
      
      - name: Build plugin
        run: |
          cd examples/simple-plugin
          make build
      
      - name: Test plugin
        run: |
          cd tools/plugin-debug
          go build -o plugin-debug .
          ./plugin-debug -plugin simple-plugin -config ../../examples/simple-plugin/config.yaml -test validate
```

### Makefile

```makefile
.PHONY: test-plugin debug-plugin

test-plugin:
	@echo "Testing plugin..."
	@cd tools/plugin-debug && go build -o plugin-debug .
	@cd tools/plugin-debug && ./plugin-debug -plugin $(PLUGIN_NAME) -config $(CONFIG_PATH) -test validate

debug-plugin:
	@echo "Debugging plugin..."
	@cd tools/plugin-debug && go build -o plugin-debug .
	@cd tools/plugin-debug && ./plugin-debug -plugin $(PLUGIN_NAME) -config $(CONFIG_PATH) -test simulate -verbose

benchmark-plugin:
	@echo "Benchmarking plugin..."
	@cd tools/plugin-debug && go build -o plugin-debug .
	@cd tools/plugin-debug && ./plugin-debug -plugin $(PLUGIN_NAME) -config $(CONFIG_PATH) -test benchmark
```

Использование:
```bash
make test-plugin PLUGIN_NAME=simple-plugin CONFIG_PATH=../../examples/simple-plugin/config.yaml
make debug-plugin PLUGIN_NAME=simple-plugin CONFIG_PATH=../../examples/simple-plugin/config.yaml
make benchmark-plugin PLUGIN_NAME=simple-plugin CONFIG_PATH=../../examples/simple-plugin/config.yaml
```

## Лучшие практики отладки

### 1. Используйте структурированные логи

```go
func (h *Handler) HandlePaymentSuccess(payment *yapay.Payment) error {
    h.logger.WithFields(logrus.Fields{
        "payment_id": payment.ID,
        "order_id":   payment.OrderID,
        "amount":     payment.Amount,
        "status":     payment.Status,
    }).Info("Processing successful payment")
    
    // Ваша логика...
    
    return nil
}
```

### 2. Добавляйте контекст в ошибки

```go
func (h *Handler) ValidateRequest(req *yapay.PaymentRequest) error {
    if req.Amount <= 0 {
        return fmt.Errorf("amount must be positive, got: %d", req.Amount)
    }
    
    if err := h.validateBusinessRules(req); err != nil {
        return fmt.Errorf("business validation failed for amount %d: %w", req.Amount, err)
    }
    
    return nil
}
```

### 3. Тестируйте граничные случаи

```go
func TestEdgeCases(t *testing.T) {
    handler := NewHandler(testMerchant)
    
    // Тест с минимальной суммой
    req := &yapay.PaymentRequest{
        Amount:      1, // 1 копейка
        Currency:    "RUB",
        Description: "Test",
        ReturnURL:   "https://example.com",
    }
    
    if err := handler.ValidateRequest(req); err != nil {
        t.Errorf("Minimal amount should be valid: %v", err)
    }
    
    // Тест с максимальной суммой
    req.Amount = 100000000 // 1 миллион рублей
    if err := handler.ValidateRequest(req); err != nil {
        t.Errorf("Large amount should be valid: %v", err)
    }
}
```

### 4. Мониторинг производительности

```go
func (h *Handler) HandlePaymentSuccess(payment *yapay.Payment) error {
    start := time.Now()
    defer func() {
        duration := time.Since(start)
        h.logger.WithFields(logrus.Fields{
            "payment_id": payment.ID,
            "duration":   duration,
        }).Debug("HandlePaymentSuccess completed")
    }()
    
    // Ваша логика...
    
    return nil
}
```
