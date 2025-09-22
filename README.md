<div align="center">

# Yapay SDK 🚀

[![Version](https://img.shields.io/badge/version-1.0.10-blue.svg)](https://github.com/metalmon/yapay-sdk)
[![Status](https://img.shields.io/badge/status-ready-green.svg)](https://github.com/metalmon/yapay-sdk)
[![Go Version](https://img.shields.io/badge/go-1.24+-00ADD8.svg)](https://golang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**SDK для создания плагинов бекенд прокси платежной системы Яндекс Пэй**

*Создавайте индивидуальную логику обработки платежей для каждого клиента*

[Документация](docs/README.md) • [Быстрый старт](QUICK_START.md) • [Дорожная карта](ROADMAP.md) • [Ручное развертывание](docs/development/manual-deployment.md) • [Поддержка](https://t.me/metal_monkey)

</div>

---

## ✨ Что делает Yapay SDK?

🔌 **Плагинная архитектура** - каждый клиент = отдельный плагин  
🛡️ **Полная изоляция** - ошибка одного клиента не влияет на других  
⚡ **Готовые инструменты** - отладка, тестирование, туннели для webhook'ов  
🔧 **ABI совместимость** - плагины и сервер используют одинаковые зависимости

## 🚀 Быстрый старт

### 1️⃣ DevContainer (рекомендуется)
```bash
# Откройте в VS Code → Ctrl+Shift+P → "Dev Containers: Reopen in Container"
# Все готово к работе! 🎉
```

### 2️⃣ Ручная настройка
```bash
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk
make check-compatibility  # Проверка готовности
```

### 3️⃣ Создание первого плагина
```bash
make new-plugin-my-plugin   # Создать плагин в src/
make build-plugins          # Собрать все плагины из src/
make test-plugins           # Протестировать
```

> 💡 **Совет**: Используйте DevContainer для максимального удобства разработки!

## 📚 Документация

- 📖 **[Полное руководство](docs/README.md)** - Детальная документация
- ⚡ **[Быстрый старт](QUICK_START.md)** - Создание плагина за 5 минут
- 🔄 **[Workflow разработки](docs/development/workflow.md)** - Процесс разработки плагинов
- 🐳 **[DevContainer](docs/development/dev-container.md)** - Среда разработки
- 💡 **[Примеры](examples/)** - Готовые шаблоны плагинов
- 🏷️ **[Версионирование SDK](docs/VERSIONING.md)** - Система версий и совместимость

## 🛠️ Основные команды

<table>
<tr>
<td>

**🔧 Плагины**
```bash
make new-plugin-NAME          # Создать новый плагин
make build-plugins            # Собрать все плагины
make build-plugin-NAME        # Собрать конкретный плагин
make test-plugins             # Протестировать плагины
```

</td>
<td>

**🚀 Разработка**
```bash
make update-dev-image         # Обновить dev-образ (рекомендуется)
make check-compatibility      # Проверка окружения
make build-plugins            # Сборка плагинов
make debug-plugin-NAME        # Отладка плагина
make tunnel-start             # Туннель для webhook'ов
```

</td>
</tr>
</table>

## 🔗 Полезные ссылки

- 📚 [Яндекс.Пей API](https://pay.yandex.ru/docs/ru/custom/backend/merchant-api/index) - Официальная документация
- 💡 [Примеры плагинов](examples/) - Готовые шаблоны для изучения
- 💬 [Telegram поддержка](https://t.me/metal_monkey) - Помощь и обсуждения

---

<div align="center">

### 🤝 Поддержка проекта

⭐ **Поставьте звезду**, если проект был полезен!

[![GitHub stars](https://img.shields.io/github/stars/metalmon/yapay-sdk?style=social)](https://github.com/metalmon/yapay-sdk)
[![GitHub forks](https://img.shields.io/github/forks/metalmon/yapay-sdk?style=social)](https://github.com/metalmon/yapay-sdk)

**Версия**: 1.0.10 | **Статус**: ✅ Готов к использованию
</div>
