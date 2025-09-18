# Workflow разработки плагинов

## 🎯 Обзор процесса

Этот документ описывает процесс разработки плагинов в команде с использованием GitHub Organizations и автоматического развертывания.


## ⚡ Быстрая настройка

### 1. Форк репозитория (1 минута)
1. Перейдите на https://github.com/metalmon/yapay-sdk
2. Нажмите **"Fork"** → выберите свою организацию
3. GitHub автоматически создаст `YOUR_ORG/yapay-sdk`

### 2. Клонирование форка (2 минуты)
```bash
git clone https://github.com/YOUR_ORG/yapay-sdk.git
cd yapay-sdk

# Добавляем upstream для обновлений
git remote add upstream https://github.com/metalmon/yapay-sdk.git
```

### 3. Включение GitHub Action (2 минуты)
1. Откройте `.github/workflows/deploy.yml` в GitHub
2. Раскомментируйте строки `on:` в начале файла
3. Сохраните изменения

### 4. Настройка Secrets (3 минуты)
В Settings → Secrets and variables → Actions добавьте:
- `SERVER_HOST` - IP сервера
- `SERVER_USER` - `deployer`
- `SERVER_SSH_KEY` - приватный SSH ключ
- `PLUGINS_PATH` - путь к плагинам на сервере
- `PLUGINS_USER` - пользователь для плагинов на хосте сервера (например: `user:group`)

### 5. Создание плагина (1 минута)
```bash
make new-plugin-my-plugin
git add src/my-plugin/
git commit -m "feat: add my-plugin"
git push origin main
```

**Готово!** Плагин автоматически развернется на сервере.

## 📋 Этапы разработки

### 1. Настройка репозитория

**Способ 1: Форк (рекомендуется)**
```bash
# Клонируем свой форк
git clone https://github.com/YOUR_ORG/yapay-sdk.git
cd yapay-sdk

# Добавляем upstream для обновлений
git remote add upstream https://github.com/metalmon/yapay-sdk.git

# Проверяем готовность к разработке
make check-compatibility
```

**Способ 2: Клонирование + новый репозиторий**
```bash
# Клонируем SDK
git clone https://github.com/metalmon/yapay-sdk.git
cd yapay-sdk

# Убираем origin (чтобы не пушить в основной репозиторий)
git remote remove origin

# Добавляем свой репозиторий в организации
git remote add origin https://github.com/YOUR_ORG/YOUR_PLUGIN_REPO.git

# Проверяем готовность к разработке
make check-compatibility
```

### 2. Создание плагина

```bash
# Создаем плагин
make new-plugin-my-plugin
```

### 3. Разработка

```bash
# Редактируем код
vim src/my-plugin/main.go
vim src/my-plugin/config.yaml

# Тестируем локально
make build-plugin-my-plugin
make test-plugins
```

### 4. Коммит и пуш

```bash
# Добавляем изменения
git add src/my-plugin/
git commit -m "feat: add my-plugin implementation"

# Пушим в свой форк
git push origin main
```

### 5. Обновление из upstream (опционально)

```bash
# Получаем обновления из основного репозитория
git fetch upstream
git checkout main
git merge upstream/main

# Пушим обновления в свой форк
git push origin main
```

## 🔄 Автоматическое развертывание

### Готовый GitHub Action

В репозитории SDK уже есть готовый GitHub Action файл `.github/workflows/deploy.yml`, но он отключен по умолчанию.

### Включение GitHub Action

1. **Перейдите в свой репозиторий** в GitHub
2. **Откройте файл** `.github/workflows/deploy.yml`
3. **Нажмите "Edit"** (карандаш)
4. **Раскомментируйте строки** в начале файла:
   ```yaml
   # Раскомментируйте эти строки для включения Action:
   # on:
   #   push:
   #     branches: [ main ]
   #   pull_request:
   #     branches: [ main ]
   ```
5. **Сохраните изменения** (Commit changes)

### Настройка Secrets в GitHub

В настройках репозитория добавьте следующие secrets:

1. **Перейдите в Settings** → **Secrets and variables** → **Actions**
2. **Нажмите "New repository secret"**
3. **Добавьте следующие secrets:**

   | Secret Name      | Описание                   | Пример                                   | Обязательный |
   |------------------|----------------------------|------------------------------------------|--------------|
   | `SERVER_HOST`    | IP адрес сервера           | `192.168.1.100`                          | ✅ |
   | `SERVER_USER`    | Пользователь для SSH       | `deployer`                               | ✅ |
   | `SERVER_SSH_KEY` | Приватный SSH ключ         | `-----BEGIN OPENSSH PRIVATE KEY-----...` | ✅ |
   | `PLUGINS_PATH`   | Путь к плагинам на сервере | `/opt/yapay/plugins`                     | ✅ |
   | `PLUGINS_USER`   | Пользователь для плагинов  | `user:group`                             | ✅ |

### Создание SSH ключа для деплоя

**Зачем нужен SSH ключ?**
GitHub Actions использует SSH для подключения к серверу и автоматического развертывания плагинов. 
- **GitHub Actions** использует **ПРИВАТНЫЙ** ключ (из Secrets) для подключения
- **Сервер** проверяет **ПУБЛИЧНЫЙ** ключ (в authorized_keys) для аутентификации

На сервере создайте отдельного пользователя для деплоя:

```bash
# Создаем пользователя для деплоя
sudo useradd -m -s /bin/bash deployer

# Создаем SSH ключи
sudo -u deployer ssh-keygen -t ed25519 -f /home/deployer/.ssh/id_ed25519 -N ""

# Показываем публичный ключ (добавьте его в authorized_keys)
sudo cat /home/deployer/.ssh/id_ed25519.pub

# Показываем приватный ключ (добавьте его в GitHub Secrets)
sudo cat /home/deployer/.ssh/id_ed25519
```

**Что делать с ключами:**
1. **Публичный ключ** → добавьте в `/home/deployer/.ssh/authorized_keys` на сервере
2. **Приватный ключ** → добавьте в GitHub Secrets как `SERVER_SSH_KEY`

**Процесс аутентификации:**
1. GitHub Actions читает приватный ключ из Secrets
2. GitHub Actions подключается к серверу по SSH
3. Сервер проверяет, что публичный ключ есть в authorized_keys
4. Если ключи совпадают → доступ разрешен
5. GitHub Actions может выполнять команды на сервере

**Как работает SSH аутентификация:**
```
GitHub Actions                    Сервер
┌─────────────────┐              ┌─────────────────┐
│ 1. Подключается │              │ 2. Проверяет    │
│    используя    │ ──────────→  │    публичный    │
│    ПРИВАТНЫЙ    │              │    ключ в       │
│    ключ из      │              │    authorized_  │
│    Secrets      │              │    keys         │
└─────────────────┘              └─────────────────┘
```

### Настройка прав пользователя deployer

```bash
# Разрешаем только копирование плагинов
echo "deployer ALL=(ALL) NOPASSWD: /bin/cp" | sudo tee /etc/sudoers.d/deployer

# Проверяем права
sudo -u deployer sudo -l
```

## 🔒 Безопасность

### Процесс деплоя

GitHub Action выполняет следующие шаги:

1. **Сборка плагинов** - собирает все плагины из `src/` через `make build-plugins`
2. **Создание резервной копии** - сохраняет текущие плагины в `/tmp/yapay-backup-TIMESTAMP/`
3. **Селективное копирование** - копирует только плагины из текущего репозитория
4. **Установка прав** - устанавливает правильные права доступа
5. **Hot-reload** - сервер автоматически подхватывает изменения

**Важно:** Деплой НЕ перезаписывает всю папку плагинов, а обновляет только плагины из текущего репозитория.

### Принципы безопасности

1. **Изоляция пользователей** - отдельный пользователь `deployer` только для деплоя
2. **Минимальные права** - доступ только к копированию плагинов (hot-reload не требует перезапуска)
3. **SSH ключи** - отдельные ключи только для деплоя (приватный в GitHub Secrets, публичный на сервере)
4. **Изоляция плагинов** - работа в контейнерах с ограниченными правами
5. **Резервное копирование** - автоматическое создание бэкапов перед деплоем
6. **Безопасное хранение** - приватные ключи хранятся в GitHub Secrets, не в коде
7. **Hot-reload** - плагины обновляются без перезапуска сервера
8. **Селективный деплой** - обновляются только плагины из текущего репозитория

### Проверка безопасности

```bash
# Проверяем права пользователя deployer
sudo -u deployer sudo -l

# Проверяем SSH доступ
sudo -u deployer ssh -o ConnectTimeout=5 localhost

# Проверяем статус сервиса
sudo systemctl status yapay
```

## 📁 Структура репозитория

```
your-plugin-repo/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── src/
│   └── my-plugin/
│       ├── main.go
│       ├── config.yaml
│       ├── go.mod
│       └── README.md
└── README.md
```

## 🚀 Примеры команд

### Создание нового плагина

```bash
# Создаем плагин
make new-plugin-shop-plugin

# Добавляем в Git
git add src/shop-plugin/
git commit -m "feat: add shop-plugin"
git push origin main
```

### Обновление существующего плагина

```bash
# Редактируем код
vim src/my-plugin/main.go

# Тестируем
make build-plugin-my-plugin
make test-plugins

# Коммитим изменения
git add src/my-plugin/
git commit -m "fix: update payment logic"
git push origin main
```

## 🔧 Troubleshooting

### Проблемы с деплоем

1. **GitHub Action не запускается:**
   - Проверьте, что раскомментировали строки `on:` в `.github/workflows/deploy.yml`
   - Убедитесь, что все Secrets настроены в репозитории

2. **Плагины не обновляются:**
   - GitHub Action обновляет только плагины из текущего репозитория
   - Если плагин был создан в другом репозитории, он не будет затронут
   - Для обновления всех плагинов используйте ручной деплой

3. **Ошибки с правами доступа:**
   - Проверьте, что `PLUGINS_USER` соответствует пользователю на хосте сервера
   - Укажите правильного пользователя в формате `user:group`
   - Пользователь должен иметь права на запись в `PLUGINS_PATH`

4. **Ошибки SSH подключения:**
   ```bash
   # Тестируем подключение
   ssh -i ~/.ssh/deploy_key deployer@SERVER_HOST
   
   # Проверяем права на ключ
   chmod 600 ~/.ssh/deploy_key
   ```

3. **Плагин не загружается после деплоя:**
   ```bash
   # Проверяем логи сервера (hot-reload должен подхватить изменения)
   sudo journalctl -u yapay -f
   
   # Проверяем права на файл
   ls -la $PLUGINS_PATH/my-plugin/
   
   # Проверяем, что файл обновился
   stat $PLUGINS_PATH/my-plugin/my-plugin.so
   ```

4. **Ошибки сборки:**
   ```bash
   # Проверяем совместимость
   make check-compatibility
   
   # Собираем локально для тестирования
   make build-plugin-my-plugin
   ```

## 📚 Дополнительные ресурсы

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Yapay SDK Documentation](../README.md)
