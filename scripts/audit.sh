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

# [4] Веб-сервер
echo "--- Раздел 4: Веб-сервер ---"

check "Установлен пакет nginx" command -v nginx
check "Конфигурация Nginx корректна" sudo nginx -t
check "Сертификат действителен (>30 дней)" sudo openssl x509 -in /etc/ssl/certs/devops.crt -checkend 2592000 -noout
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
