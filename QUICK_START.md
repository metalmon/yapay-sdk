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
