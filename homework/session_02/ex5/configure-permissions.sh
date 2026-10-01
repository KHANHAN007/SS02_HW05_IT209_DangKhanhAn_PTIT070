#!/usr/bin/env bash
set -euo pipefail

WEB_ROOT="/var/www/ptit-web"
OWNER="devops"
GROUP="www-data"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Vui lòng chạy bằng sudo: sudo ./configure-permissions.sh" >&2
    exit 1
fi

if ! id "$OWNER" >/dev/null 2>&1; then
    echo "Không tìm thấy user $OWNER. Hãy tạo user trước khi phân quyền." >&2
    exit 1
fi

if ! getent group "$GROUP" >/dev/null 2>&1; then
    echo "Không tìm thấy group $GROUP. Hãy kiểm tra cài đặt Nginx." >&2
    exit 1
fi

if [[ ! -d "$WEB_ROOT" ]]; then
    echo "Không tìm thấy thư mục $WEB_ROOT." >&2
    exit 1
fi

chown -R "$OWNER:$GROUP" "$WEB_ROOT"

# Thư mục cần quyền execute để Nginx có thể đi xuyên tới file HTML.
# Bit setgid giúp nội dung tạo mới kế thừa group www-data.
find "$WEB_ROOT" -type d -exec chmod 2750 {} +
find "$WEB_ROOT" -type f -exec chmod 0640 {} +

echo "Đã cấu hình owner=$OWNER, group=$GROUP cho $WEB_ROOT"
find "$WEB_ROOT" -maxdepth 2 -printf '%M %u:%g %p\n'
