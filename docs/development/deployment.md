# Руководство по развертыванию плагинов

## Варианты развертывания

### Вариант A: GitHub Actions (Автоматическое развертывание)

Если у вас есть доступ к серверу Yapay, настройте автоматическое развертывание через GitHub Actions.

#### 1. Настройка секретов

В настройках репозитория добавьте секреты:

- `YAPAY_SERVER_HOST` - хост сервера Yapay
- `YAPAY_SERVER_USER` - пользователь для SSH
- `YAPAY_SERVER_KEY` - приватный ключ SSH
- `YAPAY_PLUGINS_PATH` - путь к папке плагинов на сервере

#### 2. GitHub Actions workflow

Создайте `.github/workflows/deploy.yml`:

```yaml
name: Deploy Plugin

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: "1.21"

      - name: Build Plugin
        run: |
          CGO_ENABLED=1 go build -buildmode=plugin -o my-plugin.so .

      - name: Deploy to Server
        uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.YAPAY_SERVER_HOST }}
          username: ${{ secrets.YAPAY_SERVER_USER }}
          key: ${{ secrets.YAPAY_SERVER_KEY }}
          script: |
            # Создаем папку для плагина
            mkdir -p ${{ secrets.YAPAY_PLUGINS_PATH }}/my-plugin

            # Останавливаем сервер для обновления
            sudo systemctl stop yapay

            # Копируем файлы
            # (файлы будут скопированы в следующем шаге)

      - name: Copy Files
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.YAPAY_SERVER_HOST }}
          username: ${{ secrets.YAPAY_SERVER_USER }}
          key: ${{ secrets.YAPAY_SERVER_KEY }}
          source: "my-plugin.so,config.yaml"
          target: ${{ secrets.YAPAY_PLUGINS_PATH }}/my-plugin/

      - name: Restart Server
        uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.YAPAY_SERVER_HOST }}
          username: ${{ secrets.YAPAY_SERVER_USER }}
          key: ${{ secrets.YAPAY_SERVER_KEY }}
          script: |
            # Проверяем конфигурацию
            sudo /opt/yapay/bin/yapay config-check

            # Запускаем сервер
            sudo systemctl start yapay

            # Проверяем статус
            sudo systemctl status yapay
```

#### 3. Использование

```bash
# Развертывание происходит автоматически при push в main
git add .
git commit -m "Update plugin"
git push origin main
```

### Вариант B: Ручное развертывание

Если у вас нет доступа к серверу, передайте файлы администратору.

#### 1. Подготовка файлов

```bash
# Сборка плагина
make build

# Создание архива
tar -czf my-plugin.tar.gz my-plugin.so config.yaml README.md
```

#### 2. Передача файлов

Отправьте архив администратору сервера с инструкциями:

```
Файлы для развертывания:
- my-plugin.so (скомпилированный плагин)
- config.yaml (конфигурация)
- README.md (документация)

Инструкции:
1. Скопировать файлы в /opt/yapay/plugins/my-plugin/
2. Проверить права доступа (chmod 755)
3. Перезапустить сервис yapay
4. Проверить логи на наличие ошибок
```

#### 3. Проверка развертывания

```bash
# Проверить, что плагин загружен
curl http://yapay-server:8080/api/v1/health/

# Проверить логи
sudo journalctl -u yapay -f
```

### Вариант C: Docker развертывание

Если сервер использует Docker.

#### 1. Dockerfile для плагина

```dockerfile
FROM alpine:latest

# Устанавливаем необходимые пакеты
RUN apk add --no-cache ca-certificates

# Копируем плагин
COPY my-plugin.so /plugins/my-plugin/
COPY config.yaml /plugins/my-plugin/

# Устанавливаем права
RUN chmod 755 /plugins/my-plugin/my-plugin.so
```

#### 2. Docker Compose

```yaml
version: "3.8"
services:
  my-plugin:
    build: .
    volumes:
      - ./plugins/my-plugin:/opt/yapay/plugins/my-plugin
    depends_on:
      - yapay-server
```

## Проверка развертывания

### 1. Health Check

```bash
curl -s http://yapay-server:8080/api/v1/health/ | jq .
```

Ожидаемый ответ:

```json
{
  "status": "healthy",
  "plugins": ["my-plugin"],
  "timestamp": "2025-09-15T22:00:00Z"
}
```

### 2. Проверка логов

```bash
# Логи сервера
sudo journalctl -u yapay -f

# Логи плагина (если настроено отдельное логирование)
tail -f /var/log/yapay/plugins/my-plugin.log
```

### 3. Тестирование функциональности

```bash
# Создание тестового платежа
curl -X POST http://yapay-server:8080/api/v1/payments/create \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "description": "Test payment",
    "return_url": "https://example.com/return"
  }'
```

## Troubleshooting

### Плагин не загружается

1. Проверить права доступа:

```bash
ls -la /opt/yapay/plugins/my-plugin/
# Должно быть: -rwxr-xr-x my-plugin.so
```

2. Проверить зависимости:

```bash
ldd /opt/yapay/plugins/my-plugin/my-plugin.so
```

3. Проверить логи сервера:

```bash
sudo journalctl -u yapay | grep -i "my-plugin"
```

### Ошибки конфигурации

1. Проверить YAML синтаксис:

```bash
yaml-lint /opt/yapay/plugins/my-plugin/config.yaml
```

2. Проверить обязательные поля:

```yaml
name: "My Plugin" # Обязательно
enabled: true # Обязательно
yandex:
  merchant_id: "..." # Обязательно
  secret_key: "..." # Обязательно
```

### Проблемы с производительностью

1. Мониторинг ресурсов:

```bash
top -p $(pgrep yapay)
```

2. Профилирование:

```bash
# Включить профилирование в конфиге сервера
curl http://yapay-server:6060/debug/pprof/profile
```

## Откат плагина

### 1. Отключение плагина

```yaml
# config.yaml
enabled: false
```

### 2. Удаление плагина

```bash
# Остановить сервер
sudo systemctl stop yapay

# Удалить файлы
rm -rf /opt/yapay/plugins/my-plugin

# Запустить сервер
sudo systemctl start yapay
```

### 3. Восстановление из бэкапа

```bash
# Остановить сервер
sudo systemctl stop yapay

# Восстановить из бэкапа
cp -r /opt/yapay/backup/plugins/my-plugin /opt/yapay/plugins/

# Запустить сервер
sudo systemctl start yapay
```

## Мониторинг

### 1. Метрики

```bash
# Prometheus метрики
curl http://yapay-server:8080/metrics
```

### 2. Алерты

Настройте алерты на:

- Ошибки загрузки плагинов
- Высокое потребление ресурсов
- Медленные ответы API

### 3. Логирование

Рекомендуется настроить централизованное логирование (ELK, Fluentd, etc.) для анализа работы плагинов.
