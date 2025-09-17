# Development Container для Yapay SDK

Этот DevContainer предоставляет полную среду разработки для Yapay SDK с автоматической настройкой всех инструментов.

## 🚀 Быстрый старт

### Требования
- Docker Desktop
- VS Code с расширением Dev Containers
- Git

### Запуск
1. Откройте проект в VS Code
2. Нажмите `Ctrl+Shift+P` (или `Cmd+Shift+P` на Mac)
3. Выберите "Dev Containers: Reopen in Container"
4. Дождитесь сборки контейнера

## 🛠️ Включенные инструменты

### Go инструменты
- **Go 1.21** - основная версия языка
- **golangci-lint** - линтер для Go
- **goimports** - форматирование импортов
- **air** - hot reload для разработки
- **delve** - отладчик для Go
- **gosec** - security scanner

### Системные инструменты
- **curl, wget** - HTTP клиенты
- **git** - система контроля версий
- **make** - система сборки
- **vim, nano** - текстовые редакторы
- **htop, tree** - системные утилиты
- **jq** - JSON processor
- **CloudPub tunnel** - для webhook тестирования

## 🌐 Локальные сервисы

### Основные сервисы
- **SDK Development Server** - `http://localhost:8080`
- **Debug Port** - `2345` (для IDE подключения)
- **Yapay Server** - `http://localhost:8082` (интеграционные тесты)
- **CloudPub Tunnel** - `https://xxx.cloudpub.ru` (для webhook'ов)

## 📋 Команды разработки

### Основные команды
```bash
make plugins              # Умная сборка всех плагинов (автоопределение среды)
make plugin-my-plugin     # Умная сборка конкретного плагина
make examples             # Сборка всех примеров
make test                 # Запуск тестов
make all                  # Сборка всего
```

### Плагины
```bash
make plugins              # Умная сборка всех плагинов (Alpine совместимость)
make plugin-my-plugin     # Умная сборка конкретного плагина
make examples             # Сборка примеров плагинов
make test                 # Тестирование плагинов
```

### Development Container
```bash
make dev-run              # Запуск контейнера разработчика
make dev-shell            # Открыть shell в контейнере
make dev-plugins          # Сборка и тестирование плагинов
make dev-server           # Запуск Yapay сервера для интеграционных тестов
make dev-tunnel           # Запуск CloudPub туннеля
```

## 🔧 Решение проблем с плагинами

### Проблема: `__fprintf_chk: symbol not found`

Эта ошибка возникает из-за несовместимости между средами сборки и выполнения плагинов.

**Решение:**
1. Используйте умную команду: `make plugins` (автоматически определит среду)
2. Команда автоматически использует devcontainer для Alpine совместимости
3. Убедитесь, что `CGO_ENABLED=1` в переменных окружения

### Проверка совместимости
```bash
# Проверить архитектуру плагина
file src/my-plugin/my-plugin.so

# Должно показать: ELF 64-bit LSB shared object, x86-64
```

## 🐳 Совместимость с Production

DevContainer использует ту же Alpine среду, что и production:
- **Base image**: `golang:1.21-alpine`
- **Runtime**: Alpine 3.18
- **Architecture**: linux/amd64
- **CGO**: Enabled (для плагинов)

## 📁 Структура проекта

```
/workspace/
├── src/                  # Исходный код плагинов
├── examples/             # Примеры плагинов
├── tools/                # Инструменты разработки
├── testing/              # Тестовые данные
├── docs/                 # Документация
└── Makefile              # Команды сборки
```

## 🔍 Отладка

### Логи плагинов
```bash
# Просмотр логов сервера
make dev-logs

# Отладка плагинов
make dev-plugins
```

### Проверка здоровья
```bash
# Проверка SDK API
curl http://localhost:8080/health

# Проверка Yapay сервера
curl http://localhost:8082/api/v1/health
```

## 🚨 Важные замечания

1. **Всегда используйте devcontainer** для разработки плагинов
2. **Пересобирайте плагины** после изменений: `make plugins`
3. **Проверяйте совместимость** с production средой
4. **Не отключайте CGO** - плагины требуют его для работы

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `make dev-logs`
2. Пересоберите плагины: `make plugins`
3. Перезапустите контейнер: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

## 🔗 Интеграция с Yapay Server

SDK автоматически интегрируется с Yapay сервером для тестирования:

```bash
# Запуск Yapay сервера для интеграционных тестов
make dev-server

# Сборка плагинов для тестирования
make plugins

# Проверка интеграции
curl http://localhost:8082/api/v1/plugins/
```

## 🌐 CloudPub Tunnel

Для тестирования webhook'ов используется CloudPub tunnel:

```bash
# Запуск туннеля
make dev-tunnel-start

# Получение URL туннеля
make dev-tunnel-url

# Остановка туннеля
make dev-tunnel-stop
```