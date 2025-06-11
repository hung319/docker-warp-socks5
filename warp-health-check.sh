#!/bin/sh

# Đặt URL proxy, bao gồm cả thông tin xác thực nếu có.
# Điều này giúp cho lệnh curl trở nên gọn gàng hơn.
PROXY_URL="http://localhost:40000"
if [ -n "$SOCKS5_USERNAME" ]; then
    PROXY_URL="http://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@localhost:40000"
fi

# Thực hiện kiểm tra bằng curl thông qua HTTP proxy
# -x: Chỉ định proxy để sử dụng
# -f: Lệnh sẽ thất bại (trả về mã lỗi khác 0) nếu server trả về lỗi HTTP
# -s: Chế độ im lặng, không hiển thị thanh tiến trình
# --connect-timeout 5: Đặt thời gian chờ kết nối là 5 giây
# Dấu "> /dev/null" dùng để ẩn output của lệnh, vì ta chỉ quan tâm đến mã thoát
curl \
    -x "$PROXY_URL" \
    -f -s \
    --connect-timeout 5 \
    https://www.cloudflare.com/cdn-cgi/trace > /dev/null

# Lệnh 'exit $?' sẽ thoát script với cùng mã thoát của lệnh curl trước đó.
# Docker hoặc hệ thống giám sát sẽ dựa vào mã này để xác định trạng thái:
# 0 = HEALTHY (khỏe mạnh)
# khác 0 = UNHEALTHY (có vấn đề)
exit $?
