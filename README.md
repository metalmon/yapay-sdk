# Yapay SDK

SDK и инструменты для разработки плагинов для Yapay Payment Gateway.

## 🚀 Быстрый старт

### DevContainer (рекомендуется)

1. Откройте проект в VS Code
2. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Дождитесь сборки и начните разработку!

### Ручная настройка

```bash
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk
make dev-setup
make dev-shell
```

## 📚 Документация

- 📖 **[Полная документация](docs/README.md)** - Руководство по SDK
- 🐳 **[Контейнер разработчика](docs/development/dev-container.md)** - DevContainer и инструменты
- 🚀 **[Развертывание](docs/development/deployment.md)** - CI/CD и развертывание плагинов
- 💡 **[Примеры](docs/examples/)** - Реальные сценарии использования
- 🔧 **[Решение проблем](docs/troubleshooting/)** - Отладка и troubleshooting
- 🗺️ **[Roadmap](ROADMAP.md)** - Планы развития SDK

## 🛠️ Основные команды

```bash
# Разработка
make dev-run          # Запуск контейнера разработчика
make dev-shell         # Shell в контейнере
make dev-test          # Тесты
make dev-tunnel        # CloudPub туннель для webhook'ов

# SDK
make build             # Сборка всех плагинов из src/
make examples          # Сборка всех примеров
make all               # Сборка всего
make test              # Тесты SDK
make lint              # Линтинг
make new-plugin NAME=my-plugin  # Создать новый плагин в src/
```

## 📁 Структура

```
yapay-sdk/
├── .devcontainer/          # DevContainer для VS Code
├── docs/                   # 📚 Документация
├── src/                    # Рабочие плагины (исключена из Git)
├── examples/               # Примеры плагинов (шаблоны)
├── tools/                  # Инструменты разработки
├── scripts/                # Скрипты разработки
├── testing/                # Моки для тестирования
└── ROADMAP.md              # 🗺️ Планы развития SDK
```

## 🔗 URLs разработки

- **SDK Server**: http://localhost:8080
- **Debug Port**: 2345 (для IDE)
- **Yapay Server**: http://localhost:8082 (интеграционные тесты)
- **CloudPub Tunnel**: https://xxx.cloudpub.ru (для webhook'ов)

## 📋 Что нужно знать

### Обязательные функции плагина
```go
func NewHandler(merchant *yapay.Merchant) yapay.ClientHandler
func NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator
```

### Конфигурация
```yaml
# config.yaml
id: "my-plugin"
yandex:
  merchant_id: "your-merchant-id"
  secret_key: "your-secret-key"
cors_origins:
  - "https://yourdomain.com"
```

## 🚀 Создание плагина

```bash
# Создать новый плагин
make new-plugin NAME=my-plugin

# Собрать плагин
cd examples/my-plugin
make build

# Тестировать
make test
```

## 📞 Поддержка

- 📚 **Документация**: [docs/README.md](docs/README.md)
- 💡 **Примеры**: [examples/](examples/)
- 🛠️ **Инструменты**: [tools/](tools/)
- ❓ **Помощь**: https://t.me/metal_monkey

---

**Версия**: 1.0.3  
**Статус**: ✅ Готов к использованию