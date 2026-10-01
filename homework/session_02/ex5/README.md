# Bài 5 - Quản lý quyền sở hữu thư mục Web

## Mục tiêu phân quyền

Thư mục web `/var/www/ptit-web` được cấu hình với:

- Owner: `devops` để triển khai và chỉnh sửa nội dung không cần quyền root.
- Group: `www-data` để Nginx đọc và phục vụ website.
- Thư mục: `2750` (`rwxr-s---`).
- File: `0640` (`rw-r-----`).
- Other: không có quyền truy cập.

Thư mục cần quyền execute cho nhóm vì Nginx phải đi xuyên qua `/var/www/ptit-web/html` để đọc `index.html`. Chỉ cấp quyền đọc `r` cho thư mục là chưa đủ và có thể gây lỗi 403.

## Thực hiện

Trên Ubuntu Droplet, chạy:

```bash
cd homework/session_02/ex5
chmod +x configure-permissions.sh verify-permissions.sh
sudo ./configure-permissions.sh
```

Các lệnh chính trong script:

```bash
sudo chown -R devops:www-data /var/www/ptit-web
sudo find /var/www/ptit-web -type d -exec chmod 2750 {} +
sudo find /var/www/ptit-web -type f -exec chmod 0640 {} +
```

Không dùng `chmod -R 750` cho mọi thứ vì file HTML không cần quyền execute. Tách quyền thư mục và file giúp tuân theo nguyên tắc cấp quyền tối thiểu.

Bit setgid (`2`) trên thư mục đảm bảo file hoặc thư mục mới do `devops` tạo sẽ kế thừa group `www-data`, giảm nguy cơ Nginx mất quyền đọc sau các lần deploy tiếp theo.

## Kiểm tra tự động

```bash
sudo ./verify-permissions.sh
```

Script thực hiện đầy đủ:

1. Chạy `ls -la /var/www/ptit-web` và thư mục `html`.
2. Dùng `sudo -u devops` để chạy chính xác lệnh ghi `echo "Update" >> index.html` dưới quyền user thường.
3. Dùng `sudo -u www-data test -r` để xác nhận Nginx đọc được file.
4. Gọi `curl --fail --head http://localhost` để phát hiện HTTP 403 hoặc lỗi Nginx.
5. Ghi toàn bộ kết quả thật vào `permission-output.txt`.

## Kết quả mong đợi

Ví dụ định dạng quyền sau cấu hình:

```text
drwxr-s--- devops www-data html
-rw-r----- devops www-data index.html
```

Kết quả kiểm tra phải có:

```text
Ghi file thành công với user: devops
www-data đọc được index.html: PASS
HTTP/1.1 200 OK
```

## Bằng chứng thực tế

Kết quả từ Droplet được lưu tại [permission-output.txt](permission-output.txt). File này phải được tạo lại bằng `sudo ./verify-permissions.sh` trên máy chủ trước khi nộp bài.

## Xử lý lỗi 403 Forbidden

Nếu Nginx trả 403, kiểm tra từng thành phần đường dẫn:

```bash
namei -l /var/www/ptit-web/html/index.html
sudo -u www-data test -r /var/www/ptit-web/html/index.html && echo PASS
sudo tail -n 30 /var/log/nginx/ptit-web.error.log
```

Mọi thư mục cha phải cho group `www-data` quyền execute; file HTML phải cho group quyền read. Sau khi sửa quyền tệp, không cần reload Nginx.
