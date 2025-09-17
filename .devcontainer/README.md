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

### Системные инструменты
- **curl, wget** - HTTP клиенты
- **git** - система контроля версий
- **make** - система сборки
- **vim, nano** - текстовые редакторы
- **htop, tree** - системные утилиты

### CloudPub туннель
- **CloudPub клиент** - для тестирования webhook'ов
- **Автоматическая настройка** туннеля

## 🌐 Локальные сервисы

### Основные сервисы
- **SDK Development Server** - `http://localhost:8080`
- **Debug Port** - `2345` (для IDE подключения)
- **Yapay Server** - `http://localhost:8082` (интеграционные тесты)
- **CloudPub Tunnel** - `https://xxx.cloudpub.ru` (для webhook'ов)

## 📋 Команды разработки

### Основные команды
```bash
make dev-run          # Запуск контейнера разработчика
make dev-shell         # Открыть shell в контейнере
make dev-test          # Запустить тесты в контейнере
make dev-debug         # Начать отладку (порт 2345)
make dev-logs          # Показать логи контейнера
make dev-stop          # Остановить контейнер
make dev-clean         # Очистить контейнер и volumes
```

### Туннель команды
```bash
make dev-tunnel        # Запустить CloudPub туннель
make dev-tunnel-start  # Запустить CloudPub туннель
make dev-tunnel-stop   # Остановить CloudPub туннель
make dev-tunnel-status # Показать статус туннеля
make dev-tunnel-url    # Получить URL туннеля
```

### Make команды (в контейнере)
```bash
make build             # Сборка всех примеров
make test              # Запуск тестов
make lint              # Проверка кода
make fmt               # Форматирование
make clean             # Очистка артефактов
make sdk-build         # Сборка SDK
make sdk-test          # Тестирование SDK
make tools-build       # Сборка инструментов разработки
```

## 🔧 Конфигурация

### Переменные окружения
```bash
GO111MODULE=on
CGO_ENABLED=1
LOG_LEVEL=debug
GIN_MODE=debug
AIR_WORKSPACE=/workspace/sdk
AIR_TMP_DIR=/tmp
```

### VS Code настройки
- Автоформатирование при сохранении
- Автоматическая организация импортов
- Линтинг при сохранении
- Покрытие тестами
- Отладка с Delve
- Bash как терминал по умолчанию

## 🧪 Тестирование

### Unit тесты
```bash
make test
# или
go test ./...
```

### Интеграционные тесты
```bash
make dev-test
# или
go test -v -tags=integration ./...
```

### Покрытие кода
```bash
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## 🐛 Отладка

### Запуск с отладчиком
```bash
dlv debug --headless --listen=:2345 --api-version=2
```

### Отладка в VS Code
1. Установите breakpoints
2. Нажмите F5
3. Выберите "Go: Launch Package"
4. Или подключитесь к debug порту 2345

## 🌐 CloudPub туннель

### Запуск туннеля
```bash
make dev-tunnel-start
```

### Получение URL
```bash
TUNNEL_URL=$(make dev-tunnel-url)
echo "Туннель: $TUNNEL_URL"
```

### Тестирование webhook'ов
```bash
curl -X POST "$TUNNEL_URL/api/v1/webhook" \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

## 🔄 Hot Reload

### Air
```bash
air
# или
make dev-run
```

### Настройка
- Автоматическая пересборка при изменении файлов
- Исключение тестовых файлов
- Работает в контейнере разработчика

## 🐳 Docker

### Сборка образа
```bash
make dev-build
```

### Запуск с Docker Compose
```bash
make dev-run
```

### Просмотр логов
```bash
make dev-logs
```

## 🚀 Развертывание

### Локальное развертывание
```bash
make dev-run
```

### Production развертывание
```bash
make build
make deploy
```

## 🆘 Troubleshooting

### Проблемы с портами
```bash
# Проверка занятых портов
netstat -tulpn | grep :8080
```

### Проблемы с Docker
```bash
# Перезапуск Docker
sudo systemctl restart docker
```

### Проблемы с зависимостями
```bash
# Очистка модулей Go
go clean -modcache
go mod download
```

### Проблемы с туннелем
```bash
# Проверка статуса туннеля
make dev-tunnel-status

# Перезапуск туннеля
make dev-tunnel-restart
```

## 📚 Полезные ссылки

- [Go Documentation](https://golang.org/doc/)
- [VS Code Go Extension](https://marketplace.visualstudio.com/items?itemName=golang.Go)
- [Docker Documentation](https://docs.docker.com/)
- [CloudPub Documentation](https://cloudpub.ru/)
- [Yapay SDK Documentation](../docs/README.md)

## 🔗 Интерактивные скрипты

- **`./scripts/dev-setup.sh`** - Автоматическая настройка среды
- **`./scripts/dev-debug.sh`** - Интерактивная отладка
- **`./scripts/dev-test.sh`** - Комплексное тестирование
- **`./scripts/cloudpub-tunnel.sh`** - Управление CloudPub туннелем

---

**Версия DevContainer**: 1.0.0  
**Последнее обновление**: 2025  
**Статус**: ✅ Готов к использованию
