# Быстрый старт Yapay SDK

## 🚀 Создайте первый плагин за 5 минут

```bash
# 1. Форк и клонирование
# Сделайте форк репозитория в своей организации
git clone https://github.com/YOUR_ORG/yapay-sdk.git
cd yapay-sdk
git remote add upstream https://github.com/metalmon/yapay-sdk.git
make check-compatibility

# 2. Создание плагина
make new-plugin-my-plugin

# 3. Отредактировать код
# Файлы: src/my-plugin/main.go и src/my-plugin/config.yaml

# 4. Сборка и тестирование
make build-plugins
make test-plugins
```

## 📚 Полная документация

- **[Workflow разработки](docs/development/workflow.md)** - Процесс разработки в команде
- **[Руководство по разработке](docs/development/getting-started.md)** - Подробное руководство
- **[Развертывание](docs/development/deployment.md)** - Варианты развертывания
- **[Контейнер разработчика](docs/development/dev-container.md)** - Настройка среды разработки
- **[API Reference](docs/api-reference/)** - Справочник API

## 🔧 Основные команды

```bash
make check-compatibility        # Проверка готовности (умное определение окружения)
make build-plugins             # Сборка всех плагинов из src/
make build-plugin-NAME         # Сборка конкретного плагина (умная сборка)
make test                      # Тестирование
make debug-plugin-NAME         # Отладка плагина
make tunnel-start              # Запуск туннеля для webhook'ов
make help                      # Справка по всем командам
```

## ❓ Нужна помощь?

1. Изучите [полную документацию](docs/README.md)
2. Посмотрите [примеры плагинов](examples/)
3. Обратитесь за помощью: https://t.me/metal_monkey

---

**Важно**: Всегда используйте `make build-plugin-NAME` для сборки плагинов с официальным builder-образом для обеспечения совместимости с production сервером.

## ⚙️ Конфигурация плагинов

### Структура go.mod
Каждый плагин должен иметь собственный `go.mod` файл с правильной структурой:

```go
module my-plugin

go 1.24.0
toolchain go1.24.7

require (
    github.com/metalmon/yapay-sdk v1.0.10
    github.com/sirupsen/logrus v1.9.3
)

// Replace директива для синхронизации версии golang.org/x/sys
replace golang.org/x/sys => golang.org/x/sys v0.36.0

require golang.org/x/sys v0.36.0 // indirect
```

### Конфигурация плагина
Плагин настраивается через файл `config.yaml` в директории плагина:

```yaml
# plugins/my-plugin/config.yaml
name: "My Plugin"           # Обязательно: название плагина
domain: "example.com"       # Обязательно: домен клиента
enabled: true               # Обязательно: включен ли плагин

yandex:
  merchant_id: "YOUR_MERCHANT_ID"  # Обязательно: ID мерчанта (используется как client ID)
  secret_key: "YOUR_SECRET_KEY"    # Обязательно: секретный ключ
  sandbox_mode: true               # Опционально: режим песочницы

security:
  request_enforcement: monitor     # Обязательно: политика валидации
  rate_limit: 1000                # Обязательно: лимит запросов
  cors:
    origins:                      # Обязательно: CORS домены
      - "https://example.com"
      - "https://www.example.com"

plugin:
  type: "so"                      # Обязательно для .so плагинов: тип плагина ("builtin", "so", "grpc")
  path: "my-plugin.so"            # Обязательно для .so плагинов: путь до .so файла
```

### Типы плагинов
- **`builtin`** (по умолчанию) - встроенный обработчик без кастомной логики
- **`so`** - скомпилированный Go плагин (.so файл) с кастомной бизнес-логикой
- **`grpc`** - gRPC плагин (планируется в будущих версиях)

### Автоматическая загрузка
Сервер автоматически:
- Сканирует директорию `plugins/` на наличие `.so` файлов
- Загружает конфигурацию из `plugins/{plugin-name}/config.yaml`
- Определяет тип плагина (по умолчанию `builtin`)
- Регистрирует плагин по имени `.so` файла

**Важно:** Для SDK плагинов с кастомной логикой **обязательно** указать `plugin.type: "so"` и `plugin.path`, иначе будет использоваться встроенный обработчик `builtin`.
