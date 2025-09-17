# Yapay SDK

SDK и инструменты для разработки плагинов для Yapay Payment Gateway.

## 🚀 Быстрый старт

### Вариант 1: DevContainer (Рекомендуется)

**Требования:**
- Docker Desktop
- VS Code с расширением Dev Containers

**Установка:**
1. Откройте проект в VS Code
2. Нажмите `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Дождитесь сборки контейнера
4. Начните разработку!

### Вариант 2: Контейнер разработчика

```bash
# Клонируем репозиторий
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk

# Запускаем автоматическую настройку
./scripts/dev-setup.sh

# Или используем Make команды
make dev-setup
make dev-shell
```

**Преимущества контейнера разработчика:**
- 🐳 **Изолированная среда** на базе Yapay сервера
- 🛠️ **Все инструменты** уже установлены
- 🔧 **Готовые команды** для разработки и отладки
- 🧪 **Интеграционное тестирование** с Yapay сервером

### Вариант 2: Локальная разработка

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

### Разработка плагина

```bash
# В контейнере разработчика
make dev-shell
cd /workspace/sdk
make build
make test

# Или локально
make build
make test
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

## 🐳 Контейнер разработчика

### Быстрый старт

```bash
# Автоматическая настройка
./scripts/dev-setup.sh

# Или пошагово
make dev-run          # Запуск контейнера
make dev-shell         # Открыть shell в контейнере
make dev-test          # Запустить тесты
make dev-debug         # Начать отладку
```

### Основные команды

| Команда | Описание |
|---------|----------|
| `make dev-run` | Запуск контейнера разработчика |
| `make dev-shell` | Открыть shell в контейнере |
| `make dev-test` | Запустить тесты в контейнере |
| `make dev-debug` | Начать отладку (порт 2345) |
| `make dev-logs` | Показать логи контейнера |
| `make dev-stop` | Остановить контейнер |
| `make dev-clean` | Очистить контейнер и volumes |
| `make dev-tunnel` | Запустить CloudPub туннель для webhook'ов |
| `make dev-tunnel-status` | Показать статус туннеля |
| `make dev-tunnel-url` | Получить URL туннеля |

### Интерактивные скрипты

- **`./scripts/dev-setup.sh`** - Автоматическая настройка среды
- **`./scripts/dev-debug.sh`** - Интерактивная отладка
- **`./scripts/dev-test.sh`** - Комплексное тестирование

### URLs разработки

- **SDK Server**: http://localhost:8080
- **Debug Port**: 2345 (для IDE)
- **Yapay Server**: http://localhost:8082 (интеграционные тесты)
- **CloudPub Tunnel**: https://xxx.cloudpub.ru (для webhook'ов)

📖 **[Подробная документация](docs/README.md)** - Полное руководство по SDK  
📖 **[Контейнер разработчика](docs/development/dev-container.md)** - Руководство по контейнеру разработчика  
📖 **[Развертывание плагинов](docs/development/deployment.md)** - Руководство по развертыванию

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
├── Makefile                # Команды сборки и разработки
├── Dockerfile.dev          # Контейнер разработчика
├── docker-compose.dev.yml  # Docker Compose для разработки
├── .devcontainer/          # DevContainer для VS Code
│   ├── devcontainer.json   # Конфигурация DevContainer
│   └── README.md           # Документация DevContainer
├── .gitignore.dev          # Исключения для разработки
├── examples/               # Примеры плагинов
│   └── simple-plugin/      # Базовый шаблон плагина
├── tools/                  # Инструменты разработки
│   └── plugin-debug/       # Инструмент отладки
├── scripts/                # Скрипты разработки
│   ├── dev-setup.sh        # Автоматическая настройка
│   ├── dev-debug.sh        # Интерактивная отладка
│   ├── dev-test.sh         # Комплексное тестирование
│   └── cloudpub-tunnel.sh  # Управление CloudPub туннелем
├── docs/                   # 📚 Полная документация
│   ├── README.md           # Главная страница документации
│   ├── development/        # Руководства по разработке
│   │   ├── getting-started.md  # Быстрый старт
│   │   ├── dev-container.md    # Контейнер разработчика
│   │   └── deployment.md       # Развертывание плагинов
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

## 🗺️ Roadmap

### 🎯 Текущая версия (v1.0.x)
- ✅ Базовые интерфейсы для плагинов
- ✅ Инструмент отладки `plugin-debug`
- ✅ Примеры плагинов (`simple-plugin`)
- ✅ Полная документация
- ✅ Тестирование и моки

### 🚀 Ближайшие планы (v1.1.x)

#### 🔧 Инструменты разработки
- [ ] **CLI генератор плагинов** - `yapay-cli create plugin`
- [ ] **Валидатор конфигураций** - проверка `config.yaml`
- [ ] **Профилировщик производительности** - анализ узких мест
- [ ] **Генератор тестов** - автоматическое создание unit-тестов

#### 📚 Документация и примеры
- [ ] **Интерактивные туториалы** - пошаговые руководства
- [ ] **Видео-документация** - скринкасты разработки
- [ ] **Больше примеров плагинов**:
  - [ ] E-commerce магазин
  - [ ] Подписочный сервис
  - [ ] Образовательная платформа
  - [ ] SaaS приложение

#### 🛠️ Улучшения SDK
- [ ] **Кэширование** - встроенное кэширование данных для плагинов
- [ ] **Валидация данных** - улучшенная валидация входных параметров
- [ ] **Типизированные ошибки** - структурированные ошибки с кодами
- [ ] **Шаблоны плагинов** - готовые шаблоны для разных типов бизнеса

### 🌟 Среднесрочные планы (v1.2.x - v1.5.x)

#### 🔌 Расширенная функциональность
- [ ] **Webhook система** - обработка внешних событий
- [ ] **Планировщик задач** - cron-подобные задачи
- [ ] **Очереди сообщений** - асинхронная обработка
- [ ] **База данных** - встроенная ORM для плагинов

#### 🏢 Интеграции с 1С и онлайн кассами
- [ ] **1С-Фреш** - интеграция через OData API
- [ ] **Онлайн кассы** - формирование электронных чеков и отправка клиентам
- [ ] **Синхронизация товаров** - получение каталога из 1С-Фреш
- [ ] **Создание заказов** - отправка заказов в 1С-Фреш
- [ ] **Внешние API** - OData, REST API для синхронизации данных
- [ ] **Периодическая синхронизация** - автоматическое обновление данных

#### 🔐 Безопасность и мониторинг
- [ ] **Шифрование данных** - защита чувствительной информации в плагинах
- [ ] **Валидация подписей** - проверка подписей от внешних API
- [ ] **Безопасное хранение секретов** - защищенное хранение ключей в плагинах
- [ ] **Аудит действий плагинов** - детальное логирование операций плагинов

### 🚀 Долгосрочные планы (v2.0.x+)

#### 🏗️ Архитектурные улучшения
- [ ] **Плагин-менеджер** - установка/обновление плагинов через CLI
- [ ] **Версионирование плагинов** - поддержка нескольких версий

#### 🌍 Экосистема
- [ ] **Каталог плагинов** - централизованный репозиторий примеров
- [ ] **Шаблоны плагинов** - готовые заготовки для разных типов бизнеса
- [ ] **Сообщество разработчиков** - форум, документация, примеры

### 📊 Метрики успеха

#### v1.1.x цели:
- 🎯 **10+ примеров плагинов**
- 🎯 **CLI инструменты** для быстрой разработки
- 🎯 **100% покрытие тестами** критических компонентов

#### v1.2.x цели:
- 🎯 **1С-Фреш интеграция** через OData API
- 🎯 **Онлайн кассы** - формирование электронных чеков
- 🎯 **Внешние API интеграции** - OData, REST API для синхронизации данных

#### v2.0.x цели:
- 🎯 **Marketplace** с 50+ плагинами
- 🎯 **Расширенные интеграции** - CRM, ERP, кассовое ПО
- 🎯 **Продвинутые шаблоны** - готовые решения для разных отраслей

### 🤝 Участие в разработке

Хотите помочь с roadmap? Мы приветствуем:

- 💡 **Предложения функций** - создавайте issues с идеями
- 🔧 **Pull requests** - реализуйте новые возможности
- 📚 **Документация** - улучшайте существующие руководства
- 🧪 **Тестирование** - находите и сообщайте об ошибках
- 💬 **Обратная связь** - делитесь опытом использования

## Поддержка

- 📚 **Документация**: [docs/README.md](docs/README.md) - Полное руководство
- 💡 **Примеры**: [examples/](examples/) - Готовые плагины
- 🛠️ **Инструменты**: [tools/](tools/) - Отладка и разработка
- ❓ **Помощь**: https://t.me/metal_monkey
