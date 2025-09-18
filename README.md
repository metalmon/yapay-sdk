# Yapay SDK

SDK для создания плагинов бекенд прокси платежной системы Яндекс Пэй.

Создавайте индивидуальную логику обработки платежей для каждого клиента.

## ⚡ Быстрый старт

### DevContainer (рекомендуется)
```bash
# Откройте в VS Code → Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

### Ручная настройка
```bash
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk
make check-compatibility  # Проверка готовности
make build-plugins        # Сборка примеров
```

## 🎯 Что вы получите

- **Плагинная архитектура** - каждый клиент = отдельный плагин
- **100% совместимость** - сборка с официальным builder-образом
- **Полная изоляция** - ошибка одного клиента не влияет на других
- **Готовые инструменты** - отладка, тестирование, туннели для webhook'ов

## 🚀 Быстрый старт

```bash
make new-plugin-my-plugin   # Создать плагин в src/
make build-plugins          # Собрать все плагины из src/
make test-plugins           # Протестировать
```

## 📚 Документация

- 📖 **[Полное руководство](docs/README.md)** - Детальная документация
- ⚡ **[Быстрый старт](QUICK_START.md)** - Создание плагина за 5 минут
- 🔄 **[Workflow разработки](docs/development/workflow.md)** - Процесс разработки плагинов
- 🐳 **[DevContainer](docs/development/dev-container.md)** - Среда разработки
- 💡 **[Примеры](examples/)** - Готовые шаблоны плагинов

## 🛠️ Основные команды

```bash
make check-compatibility       # Проверка готовности к разработке
make build-plugins             # Сборка всех плагинов из src/
make build-examples            # Сборка примеров (для тестирования)
make build-plugin-NAME         # Сборка конкретного плагина
make test                      # Тестирование
make debug-plugin-NAME         # Отладка плагина
make tunnel-start              # Туннель для webhook'ов
make help                      # Все доступные команды
```

## 🔗 Полезные ссылки

- [Яндекс.Пей API](https://pay.yandex.ru/docs/ru/custom/backend/merchant-api/index)
- [Примеры плагинов](examples/)
- [Telegram поддержка](https://t.me/metal_monkey)

---

**Версия**: 1.0.6 | **Статус**: ✅ Готов к использованию