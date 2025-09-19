# Ручное развертывание плагинов

## 🚀 Быстрый старт

### 1. Настройка (один раз)

1. **Настройте Secrets** в GitHub репозитории:
   - `SERVER_HOST` - IP сервера
   - `SERVER_USER` - `deployer`
   - `SERVER_SSH_KEY` - приватный SSH ключ
   - `PLUGINS_PATH` - путь к плагинам на сервере
   - `PLUGINS_USER` - пользователь для плагинов

2. **Создайте пользователя deployer** на сервере:
   ```bash
   sudo useradd -m -s /bin/bash deployer
   sudo -u deployer ssh-keygen -t ed25519 -f /home/deployer/.ssh/id_ed25519 -N ""
   ```

### 2. Ручной запуск

1. **Перейдите в Actions** в вашем репозитории GitHub
2. **Выберите workflow** "Deploy Plugins"
3. **Нажмите "Run workflow"**
4. **Выберите параметры:**
   - **Force rebuild**: `true` для полной пересборки
5. **Нажмите "Run workflow"**

## 📋 Параметры запуска

| Параметр | Описание | Значения | По умолчанию |
|----------|----------|----------|--------------|
| `force_rebuild` | Принудительная пересборка всех плагинов | `true`, `false` | `false` |

### Логика параметров:

- **Ручной запуск**: Используется выбранный параметр `force_rebuild`
- **Автоматический запуск (push)**: 
  - `force_rebuild` = `true` (всегда, для гарантии обновления)

## 🔄 Включение автоматического запуска

Для автоматического развертывания при каждом пуше в main ветку:

1. Откройте `.github/workflows/deploy.yml`
2. Раскомментируйте строки в конце секции `on:`:
   ```yaml
   # Раскомментируйте эти строки для автоматического запуска при пуше:
   #   push:
   #     branches: [ main ]
   #   pull_request:
   #     branches: [ main ]
   ```

## 🛠️ Примеры использования

### Обычное развертывание
- Force rebuild: `false`

### Полная пересборка
- Force rebuild: `true`

## 🔧 Troubleshooting

### GitHub Action не запускается
- Убедитесь, что все Secrets настроены
- Проверьте, что вы находитесь в ветке `main`
- Убедитесь, что workflow файл существует

### Плагины не обновляются
- GitHub Action обновляет только плагины из текущего репозитория
- Используйте `Force rebuild: true` для гарантии обновления

### Ошибки SSH
```bash
# Тестируем подключение
ssh -i ~/.ssh/deploy_key deployer@SERVER_HOST
```

## 📚 Дополнительно

- [Полная документация](workflow.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
