# YAPAY SDK Development Environment

Этот DevContainer предоставляет стабильную среду разработки для YAPAY SDK с автоматической настройкой всех инструментов.

## 🏗️ Архитектура контейнеров

- **yapay-sdk-dev** - основной контейнер разработки SDK
- **yandex-pay-mock** - мок сервис для Yandex Pay API
- **yapay-sdk-development-network** - изолированная сеть для сервисов

## 🚀 Быстрый старт

### Требования
- Docker Desktop
- VS Code с расширением Dev Containers
- Git

### Запуск
1. Откройте проект в VS Code
2. Нажмите `Ctrl+Shift+P` (или `Cmd+Shift+P` на Mac)
3. Выберите "Dev Containers: Reopen in Container"
4. Дождитесь загрузки готового образа `metalmon/yapay:dev` из Docker Hub

## 🛠️ Включенные инструменты

### Go инструменты
- **Go 1.21** - основная версия языка
- **golangci-lint** - линтер для Go
- **goimports** - форматирование импортов
- **air** - hot reload для разработки
- **delve** - отладчик для Go
- **gosec** - сканер безопасности

### Системные инструменты
- **curl, wget** - HTTP клиенты
- **git** - система контроля версий
- **make** - система сборки
- **vim, nano** - текстовые редакторы
- **htop, tree** - системные утилиты
- **jq, file** - утилиты для работы с данными
- **CloudPub tunnel** - для тестирования webhook'ов

## 🌐 Локальные сервисы

### Основные сервисы
- **YAPAY SDK Server** - `http://localhost:8080` (основное приложение)
- **YAPAY SDK Debug** - `http://localhost:8081` (отладочный порт)
- **Yandex Pay Mock** - `http://localhost:8083` (мок API)
- **Delve Debugger** - `localhost:2345` (отладчик Go)
- **Metrics Port** - `8080` (метрики Prometheus)

## 📋 Команды разработки

### Основные команды
```bash
make build              # Сборка SDK
make test               # Запуск тестов
make lint               # Проверка кода линтером
make security           # Проверка безопасности
make run                # Запуск SDK локально
make debug              # Запуск с отладчиком
```

### Разработка плагинов
```bash
make plugin-build       # Сборка плагинов
make plugin-test        # Тестирование плагинов
make plugin-lint        # Проверка плагинов
```

### CloudPub Tunnel
```bash
make tunnel             # Запуск CloudPub туннеля для webhook'ов
make tunnel-start       # Запуск туннеля
make tunnel-stop        # Остановка туннеля
make tunnel-status      # Статус туннеля
make tunnel-url         # Получение URL туннеля
```

## 🔧 Устранение проблем с DevContainer

### Проблема: Контейнеры не запускаются или работают нестабильно

**Решение:**
1. **Очистите старые контейнеры:**
   ```bash
   docker-compose -f .devcontainer/docker-compose.yml down --volumes --remove-orphans
   docker system prune -f
   ```

2. **Пересоберите контейнеры:**
   ```bash
   docker-compose -f .devcontainer/docker-compose.yml pull
   ```

3. **В VS Code:** `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Проблема: Конфликт портов

**Решение:**
- Убедитесь, что порты 8080, 8081, 8083 и 2345 свободны
- Проверьте запущенные контейнеры: `docker ps`
- Остановите конфликтующие сервисы

### Проблема: Сеть не работает между контейнерами

**Решение:**
- Проверьте сеть: `docker network ls | grep yapay-sdk`
- Пересоздайте сеть: `docker network rm yapay-sdk-development-network`
- Перезапустите контейнеры

## 🐳 Совместимость с Production

DevContainer использует ту же Alpine среду, что и production Dockerfile:
- **Base image**: `metalmon/yapay:dev` (из Docker Hub)
- **Runtime**: Alpine 3.18
- **Architecture**: linux/amd64
- **CGO**: Enabled (для плагинов)

## 📁 Структура проекта

```
/workspace/
├── src/                 # Исходный код плагинов
├── tools/               # Инструменты разработки
├── plugins/             # Собранные плагины
├── testing/             # Тестовые данные
└── Makefile             # Команды сборки
```

## 🔍 Отладка

### Логи SDK
```bash
# Просмотр логов SDK
make logs

# Отладка плагинов
make debug-plugins
```

### Проверка здоровья
```bash
# Проверка API
curl http://localhost:8080/api/v1/health

# Список плагинов
curl http://localhost:8080/api/v1/plugins/
```

## 🚨 Важные замечания

1. **Всегда используйте devcontainer** для разработки SDK
2. **Пересобирайте плагины** после изменений: `make plugin-build`
3. **Проверяйте совместимость** с production средой
4. **Не отключайте CGO** - плагины требуют его для работы
5. **Образ обновляется** через CI/CD и публикуется в Docker Hub

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `make logs`
2. Обновите образ: `docker pull metalmon/yapay:dev`
3. Перезапустите контейнер: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"