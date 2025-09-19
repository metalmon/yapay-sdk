# 🔌 Plugin Compatibility Guide for Developers

## 🎯 **Для разработчиков плагинов**

Этот гайд поможет вам создавать совместимые плагины для YAPAY и понимать, как работает система совместимости.

## 🏗️ **Архитектура совместимости**

### **Эталонный образ**
- YAPAY использует **эталонный образ** `metalmon/yapay:builder`
- Образ содержит **фиксированный vendor граф** зависимостей
- Все плагины должны использовать **ТОЧНО ТЕ ЖЕ** зависимости

### **Как это работает**
```bash
# При сборке плагина
cp /app/go.mod .        # Копируем go.mod из эталонного образа
cp /app/go.sum .        # Копируем go.sum из эталонного образа  
cp -r /app/vendor .     # Копируем vendor граф из эталонного образа
go build -mod=vendor    # Собираем с фиксированными зависимостями
```

## 🔧 **Проверка совместимости**

### **Команды для проверки**

```bash
# Проверить совместимость всех плагинов
make check-plugin-compatibility

# Проверить конкретный плагин
make build-plugin-MY_PLUGIN

# Проверить среду разработки
make check-compatibility
```

### **Что проверяется**
- ✅ Совместимость с эталонным образом
- ✅ Корректность сборки плагина
- ✅ Соответствие зависимостей vendor графу

## 📋 **Рекомендации для разработчиков**

### **1. Используйте только SDK зависимости**
```go
// ✅ Хорошо - используйте только зависимости из SDK
import (
    "github.com/sirupsen/logrus"
    "github.com/metalmon/yapay-sdk"
)

// ❌ Плохо - не добавляйте новые зависимости
import (
    "github.com/some-new-library"  // Это сломает совместимость!
)
```

### **2. Следуйте интерфейсам SDK**
```go
// ✅ Хорошо - реализуйте стандартные интерфейсы
type MyPlugin struct{}

func (p *MyPlugin) HandlePaymentSuccess(payment *yapay.Payment) error {
    // Ваша логика
}

// ❌ Плохо - не изменяйте интерфейсы
func (p *MyPlugin) MyCustomMethod() {  // Это может сломаться!
    // Ваша логика
}
```

### **3. Тестируйте совместимость**
```bash
# Перед каждым коммитом
make check-plugin-compatibility

# Перед релизом плагина
make test-plugins
```

## 🚨 **Что может сломать совместимость**

### **Критические изменения**
- Изменение зависимостей в основном проекте
- Обновление Go версии
- Изменение интерфейсов SDK
- Изменение vendor графа

### **Безопасные изменения**
- Изменения в логике плагина (без новых зависимостей)
- Обновления документации
- Добавление новых методов (не изменяя существующие)

## 🔄 **Процесс обновления**

### **Когда YAPAY обновляется**

1. **Уведомление**: Вы получите уведомление о breaking changes
2. **Время на адаптацию**: Обычно 2-4 недели
3. **Новый builder образ**: Будет доступен новый эталонный образ
4. **Пересборка**: Вам нужно пересобрать плагин с новым образом

### **Как обновить плагин**

```bash
# 1. Обновите builder образ
docker pull metalmon/yapay:builder

# 2. Проверьте совместимость
make check-plugin-compatibility

# 3. Пересоберите плагин
make build-plugin-MY_PLUGIN

# 4. Протестируйте
make test-plugins
```

## 🛠️ **Инструменты разработки**

### **Создание нового плагина**
```bash
# Создать новый плагин из шаблона
make new-plugin-my-awesome-plugin

# Собрать плагин
make build-plugin-my-awesome-plugin

# Протестировать плагин
make test-plugins
```

### **Отладка плагинов**
```bash
# Отладить конкретный плагин
make debug-plugin-MY_PLUGIN

# Проверить совместимость
make check-plugin-compatibility
```

## 📞 **Поддержка**

### **Если что-то сломалось**

1. **Проверьте совместимость**: `make check-plugin-compatibility`
2. **Обновите builder образ**: `docker pull metalmon/yapay:builder`
3. **Обратитесь за поддержкой**: Создайте issue в репозитории SDK

### **Контакты**
- **GitHub Issues**: [YAPAY SDK Issues](https://github.com/metalmon/yapay-sdk/issues)
- **Documentation**: [YAPAY SDK Docs](https://github.com/metalmon/yapay-sdk/docs)
- **Examples**: [Plugin Examples](https://github.com/metalmon/yapay-sdk/examples)

## 🎯 **Лучшие практики**

### **1. Версионирование плагинов**
```go
const PluginVersion = "1.2.3"
const MinYapayVersion = "1.0.0"
```

### **2. Обработка ошибок**
```go
func (p *MyPlugin) HandlePaymentSuccess(payment *yapay.Payment) error {
    if payment == nil {
        return fmt.Errorf("payment cannot be nil")
    }
    // Ваша логика
    return nil
}
```

### **3. Логирование**
```go
import "github.com/sirupsen/logrus"

func (p *MyPlugin) HandlePaymentSuccess(payment *yapay.Payment) error {
    logrus.WithFields(logrus.Fields{
        "plugin": "my-plugin",
        "payment_id": payment.ID,
    }).Info("Processing payment")
    
    // Ваша логика
    return nil
}
```

---

*Этот гайд поможет вам создавать стабильные и совместимые плагины для YAPAY.*
