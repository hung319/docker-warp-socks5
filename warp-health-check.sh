#!/bin/sh

# Đặt URL proxy, trỏ đến CỔNG 1080
PROXY_PORT=1080
PROXY_URL="http://localhost:${PROXY_PORT}"

if [ -n "$SOCKS5_USERNAME" ]; then
    PROXY_URL="http://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@localhost:${PROXY_PORT}"
fi

# Thực hiện kiểm tra bằng curl thông qua HTTP proxy
# Dấu "> /dev/null" dùng để ẩn output của lệnh, vì ta chỉ quan tâm đến mã thoát
curl \
    -x "$PROXY_URL" \
    -f -s \
    --connect-timeout 5 \
    https://www.cloudflare.com/cdn-cgi/trace > /dev/null

# Lệnh 'exit $?' sẽ thoát script với cùng mã thoát của lệnh curl trước đó.
# 0 = HEALTHY (khỏe mạnh), khác 0 = UNHEALTHY (có vấn đề)
exit $?
