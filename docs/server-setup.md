
## 8. Веб-сервер

- **Устанавливаемый пакет:** `nginx`
- **Путь к конфигурации ресурса:** `/etc/nginx/sites-available/devops-site` (символическая ссылка в `/etc/nginx/sites-enabled/`)
- **Каталог ресурса:** `/var/www/devops-site`
- **Владелец каталога и права:** владелец `devops:devops`, права `755` для каталогов и `644` для файлов (модель «владелец пишет, веб-сервер читает»).
- **Пути к сертификату и ключу:**
  - Сертификат: `/etc/ssl/certs/devops.crt` (права `644`, владелец `root`)
  - Закрытый ключ: `/etc/ssl/private/devops.key` (права `600`, владелец `root`)
- **Команда формирования сертификата:**
  ```bash
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/devops.key \
    -out /etc/ssl/certs/devops.crt \
    -subj "/CN=devops.local" \
    -addext "subjectAltName=DNS:devops.local"


---

### Шаг 2. Дополняем скрипт аудита (`scripts/audit.sh`)

В методичке сказано, что нужно добавить раздел `[4] Веб-сервер` с четырьмя проверками. 

Я напишу для тебя готовый скрипт, который включает в себя эти проверки. **Перезапишем** файл `scripts/audit.sh` (так как мы не знаем, что там было до этого, но по методичке нам нужна функция `check`).

```bash
cat > scripts/audit.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

FAILED=0

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "[OK] $description"
    else
        echo "[FAIL] $description"
        FAILED=1
    fi
}

echo "=== Аудит конфигурации сервера ==="

# [1-3] Предыдущие проверки из ПЗ №5 (оставлены для примера)
# check "SSH доступ по ключу" ssh -o BatchMode=yes -o ConnectTimeout=5 devops@localhost true

# [4] Веб-сервер
echo "--- Раздел 4: Веб-сервер ---"

# Проверка "а" (пропущена в задании, но логично проверить наличие пакета)
check "Установлен пакет nginx" command -v nginx

# Проверка "б": конфигурация nginx синтаксически корректна
check "Конфигурация Nginx корректна" sudo nginx -t

# Проверка "в": сертификат истекает не ранее чем через 30 дней
check "Сертификат действителен (>30 дней)" sudo openssl x509 -in /etc/ssl/certs/devops.crt -checkend 2592000 -noout

# Проверка "г": 
# 1. Нет файлов, доступных для записи всем (find ... -perm -o+w)
# 2. Права ключа равны 600 (sudo stat -c '%a' ...)
check "Нет файлов, доступных для записи всем" test -z "$(sudo find /var/www/devops-site -perm -o+w 2>/dev/null)"
check "Права ключа TLS равны 600" test "$(sudo stat -c '%a' /etc/ssl/private/devops.key)" == "600"

echo "==============================="

if [ $FAILED -eq 1 ]; then
    echo "Аудит завершен с ошибками."
    exit 1
else
    echo "Аудит успешно пройден."
    exit 0
fi
