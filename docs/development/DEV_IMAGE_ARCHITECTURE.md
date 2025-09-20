# Архитектура Development Image

## Обзор

Development Image (`metalmon/yapay:dev`) - это предварительно собранный Docker образ для разработки YAPAY SDK, который создается через GitHub Actions в проекте yapay и публикуется в DockerHub.

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    yapay Project                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              GitHub Actions                         │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │         docker-publish.yml                 │   │    │
│  │  │  1. Build builder image                    │   │    │
│  │  │  2. Build production server                │   │    │
│  │  │  3. Build dev image (uses server binary)   │   │    │
│  │  │  4. Run security scans                      │   │    │
│  │  │  5. Publish both images                     │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Dockerfile.dev                         │    │
│  │  • Based on metalmon/yapay:builder                 │    │
│  │  • Includes all dev tools                          │    │
│  │  • Copies yapay-server from production image      │    │
│  │  • Sets up workspace structure                     │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    DockerHub                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              metalmon/yapay:latest                   │    │
│  │  • Production server image                          │    │
│  │  • Contains yapay-server binary                     │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              metalmon/yapay:dev                     │    │
│  │  • Development image                                │    │
│  │  • Uses binary from production image                │    │
│  │  • Tagged with SHA and run number                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  yapay-sdk Project                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           .devcontainer/docker-compose.yml          │    │
│  │  • Uses metalmon/yapay:dev                          │    │
│  │  • Fallback to local build                          │    │
│  │  • Mounts workspace and volumes                     │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              scripts/update-dev-image.sh            │    │
│  │  • Pulls latest dev image                           │    │
│  │  • Provides update instructions                     │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Преимущества

### 🚀 Производительность
- **Быстрый запуск**: Нет необходимости в локальной сборке
- **Кэширование**: GitHub Actions кэширует Docker слои
- **Оптимизация**: Образ оптимизирован для разработки

### 🔒 Надежность
- **Стабильная сборка**: CI/CD среда без сетевых проблем
- **Гарантия совместимости**: Dev-образ использует тот же бинарник, что и продакшн
- **Версионирование**: Теги с SHA и номером сборки
- **Безопасность**: Автоматические security scans

### 🔄 Удобство
- **Умное обновление**: Только при security updates в Alpine LTS
- **Экономия ресурсов**: Нет пересборки без критических обновлений
- **Эталонная стабильность**: Builder образ фиксирует Go и зависимости
- **LTS подход**: Alpine 3.18 + фиксированная Go версия = стабильность
- **Консистентность**: Все разработчики используют одинаковый образ
- **Fallback**: Локальная сборка при недоступности образа

## Workflow обновления

### Последовательность сборки
```yaml
# В yapay/.github/workflows/docker-publish.yml
1. check-updates     # Проверка необходимости обновления (только для schedule)
2. build-builder     # Сборка builder образа (если нужно обновление)
3. build-and-push    # Сборка production сервера (если нужно обновление)
4. build-dev-image   # Сборка dev образа (если нужно обновление)
5. security-scan     # Сканирование безопасности (если нужно обновление)
6. notify            # Уведомления
```

### Умная логика обновления
```bash
# При еженедельном запуске (schedule):
1. Проверяет security updates в Alpine 3.18 (LTS)
2. Проверяет возраст builder образа (информационно)
3. Только если есть security updates - запускает сборку
4. Если security updates нет - пропускает сборку и уведомляет

# Логика основана на:
- Alpine 3.18 - LTS версия, стабильная
- Go версия фиксирована в builder образе
- Builder образ - эталон для фиксации зависимостей
- Обновления только при критических security patches
```

### Триггеры сборки
- **Push в main/develop** только при изменении критических файлов:
  - `Dockerfile`, `Dockerfile.builder`
  - `cmd/`, `internal/` (код сервера)
  - `go.mod`, `go.sum` (зависимости)
- **Еженедельное обновление** по понедельникам в 2 AM UTC
- **Ручной запуск** через workflow_dispatch в GitHub Actions

### Ручное обновление

#### Через GitHub Actions (рекомендуется)
1. Перейти в проект yapay на GitHub
2. Открыть вкладку "Actions"
3. Выбрать workflow "Build and Push Docker Image"
4. Нажать "Run workflow"
5. Выбрать ветку и нажать "Run workflow"

#### Через yapay-sdk
```bash
# В yapay-sdk
make update-dev-image
```

## Теги образов

- `metalmon/yapay:dev` - Latest development image
- `metalmon/yapay:dev-{SHA}` - Specific commit
- `metalmon/yapay:dev-{RUN_NUMBER}` - Build number

## Использование

### В yapay-sdk
```bash
# Обновить образ
make update-dev-image

# Запустить контейнер
docker-compose -f .devcontainer/docker-compose.yml up -d

# Подключиться
docker exec -it yapay-sdk_devcontainer-yapay-sdk-dev-1 bash
```

### Прямое использование
```bash
# Pull образа
docker pull metalmon/yapay:dev

# Запуск
docker run -it --rm metalmon/yapay:dev bash
```

## Мониторинг

### GitHub Actions
- Статус сборки в yapay project
- Security scan результаты
- Уведомления об успехе/неудаче

### DockerHub
- Размер образа
- Последнее обновление
- Уязвимости (если есть)

## Troubleshooting

### Образ недоступен
```bash
# Использовать fallback к локальной сборке
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
```

### Проблемы с обновлением
```bash
# Принудительное обновление
docker pull metalmon/yapay:dev --force
```

### Старый образ
```bash
# Проверить дату образа
docker images metalmon/yapay:dev

# Обновить вручную
make update-dev-image
```
