#!/usr/bin/env bash
set -euo pipefail

WEB_ROOT="/var/www/ptit-web"
INDEX_FILE="$WEB_ROOT/html/index.html"
OUTPUT_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/permission-output.txt"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Vui lòng chạy bằng sudo: sudo ./verify-permissions.sh" >&2
    exit 1
fi

{
    echo "Thời điểm kiểm tra: $(date --iso-8601=seconds)"
    echo
    echo "=== Quyền thư mục và file ==="
    ls -la "$WEB_ROOT"
    ls -la "$WEB_ROOT/html"

    echo
    echo "=== devops ghi file không dùng sudo trong shell của user ==="
    sudo -u devops -- sh -c "echo 'Update' >> '$INDEX_FILE'"
    echo "Ghi file thành công với user: $(sudo -u devops -- id -un)"
    tail -n 3 "$INDEX_FILE"

    echo
    echo "=== Nginx đọc file với user www-data ==="
    sudo -u www-data -- test -r "$INDEX_FILE"
    echo "www-data đọc được index.html: PASS"

    echo
    echo "=== Kiểm tra HTTP ==="
    curl --fail --silent --show-error --head http://localhost
} | tee "$OUTPUT_FILE"

echo
echo "Đã lưu kết quả thật tại: $OUTPUT_FILE"
