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

# [4] Веб-сервер (из ПЗ №6)
echo "--- Раздел 4: Веб-сервер ---"
check "Установлен пакет nginx" command -v nginx
check "Конфигурация Nginx корректна" sudo nginx -t
check "Сертификат действителен (>30 дней)" sudo openssl x509 -in /etc/ssl/certs/devops.crt -checkend 2592000 -noout
check "Нет файлов, доступных для записи всем" test -z "$(sudo find /var/www/devops-site -perm -o+w 2>/dev/null)"
check "Права ключа TLS равны 600" test "$(sudo stat -c '%a' /etc/ssl/private/devops.key)" == "600"

# [5] Контейнеризация (из ПЗ №7)
echo "--- Раздел 5: Контейнеризация ---"
check "Служба docker активна" systemctl is-active --quiet docker
check "Контейнер СУБД healthy" test "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null)" == "healthy"
# Проверка, что порты 5000 и 5432 слушаются только на 127.0.0.1 (или не слушаются вообще)
check "Порты 5000 и 5432 не доступны извне" test -z "$(sudo ss -tln | grep -E ':(5000|5432)\b' | grep -v '127.0.0.1' || true)"
check "Права .env равны 600" test "$(stat -c '%a' ~/app/.env)" == "600"

echo "==============================="

if [ $FAILED -eq 1 ]; then
    echo "Аудит завершен с ошибками."
    exit 1
else
    echo "Аудит успешно пройден."
    exit 0
fi
