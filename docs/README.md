# Документация Yapay SDK

Добро пожаловать в документацию Yapay SDK! Здесь вы найдете всю необходимую информацию для разработки плагинов платежной системы.

## 📚 Структура документации

### 🚀 [Разработка плагинов](development/getting-started.md)
- Быстрый старт
- Структура плагина
- Создание нового плагина
- Сборка плагинов для совместимости
- Развертывание
- Лучшие практики

### 🐳 [Контейнер разработчика](development/dev-container.md)
- Настройка среды разработки
- Команды контейнера разработчика
- CloudPub туннель для webhook'ов
- Интеграция с IDE
- Устранение неполадок

### 🔄 [Workflow разработки](development/workflow.md)
- Процесс разработки в команде
- Настройка репозитория
- Автоматическое развертывание
- Безопасность и ограничения доступа

### 🚀 [Развертывание плагинов](development/deployment.md)
- Автоматическое развертывание через GitHub Actions
- Ручное развертывание
- Настройка CI/CD
- Мониторинг и откат изменений

### 📖 [Справочник API](api-reference/)
- [Интерфейсы SDK](api-reference/interfaces.md) - Подробное описание всех интерфейсов
- [OpenAPI спецификация](api-reference/payment-api.yaml) - API для создания платежей

### 💡 [Примеры использования](examples/)
- [Реальные сценарии](examples/real-world-scenarios.md) - Онлайн-школа, магазин, подписки
- [Интеграция фронтенда](examples/frontend-integration.md) - Кнопки, виджеты, бейджи Яндекс.Пей
- [Конфигурации фронтенда](examples/frontend-config-examples.md) - Примеры настроек для разных сценариев

### 🔧 [Решение проблем](troubleshooting/)
- [Частые проблемы](troubleshooting/common-issues.md) - Ошибки загрузки, конфигурации, webhook'ов
- [Отладка плагинов](troubleshooting/debugging.md) - Инструменты отладки, тестирование, профилирование

## 🎯 Быстрый старт

1. **Создайте новый плагин:**
   ```bash
   make new-plugin-my-plugin
   # Плагин создается в src/my-plugin/ (отслеживается Git)
   ```

2. **Соберите плагин:**
   ```bash
   # Проверить совместимость builder-образа
   make check-compatibility
   
   # Собрать плагин с правильным образом
   make build-plugin-my-plugin
   ```

3. **Для командной разработки:**
   ```bash
   # Сделайте форк репозитория в своей организации
   # Затем клонируйте свой форк:
   git clone https://github.com/YOUR_ORG/yapay-sdk.git
   cd yapay-sdk
   git remote add upstream https://github.com/metalmon/yapay-sdk.git
   
   # Создайте и закоммитьте плагин
   make new-plugin-my-plugin
   git add src/my-plugin/
   git commit -m "feat: add my-plugin"
   git push origin main
   ```

4. **Протестируйте:**
   ```bash
   make test
   ```

## 📋 Что нужно знать

### Обязательные функции
Каждый плагин должен экспортировать функции:
- `NewHandler(merchant *yapay.Merchant, logger *logrus.Logger) interface{}` - создает плагин, реализующий оба интерфейса
- `NewPaymentGenerator(merchant *yapay.Merchant, logger *logrus.Logger) yapay.PaymentLinkGenerator` - для обратной совместимости

### Интерфейсы плагина
Плагин должен реализовывать интерфейсы:
- **PaymentLinkGenerator** - генерация данных платежа и валидация
- **PaymentEventHandler** - обработка событий жизненного цикла платежей
- **VersionedPlugin** (опционально) - сообщение версии SDK для совместимости

```go
// Обязательная реализация для версионирования
func (p *MyPlugin) GetSDKVersion() string {
    return yapay.GetSDKVersion()  // Используем метод SDK для получения версии
}
```

### Конфигурация
Плагин настраивается через файл `config.yaml` с обязательными полями:
- `id` - уникальный идентификатор клиента
- `yandex.merchant_id` - ID мерчанта в Яндекс.Пей
- `yandex.secret_key` - секретный ключ

### API для фронтенда
Используйте OpenAPI спецификацию для интеграции с фронтендом:
- `POST /api/v1/payments/create` - создание платежа
- `POST /api/v1/payments/{id}/status` - получение статуса

**Полная интеграция:** См. [Интеграция фронтенда](examples/frontend-integration.md) для примеров с кнопками, виджетами и бейджами Яндекс.Пей.

## 🔗 Полезные ссылки

- [Яндекс.Пей документация](https://pay.yandex.ru/docs/ru/custom/backend/merchant-api/index)
- [Go плагины](https://pkg.go.dev/plugin)
- [Примеры плагинов](../examples/) - Шаблоны для создания плагинов
- [Рабочие плагины](../src/) - Готовые плагины

## ❓ Нужна помощь?

1. Проверьте [раздел решения проблем](troubleshooting/common-issues.md)
2. Изучите [примеры использования](examples/real-world-scenarios.md)
3. Создайте issue в репозитории

---

**Важно:** Никогда не коммитьте секретные ключи и пароли в репозиторий!
