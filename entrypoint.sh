#!/bin/sh

if [ ! -f /opt/wireproxy.conf ]; then
    echo "Đang cấu hình WireGuard lần đầu..."
    mkdir -p /opt/wgcf
    wgcf register --accept-tos --config /opt/wgcf/wgcf-account.toml
    wgcf generate --config /opt/wgcf/wgcf-account.toml
    mv wgcf-profile.conf /opt/wireproxy.conf
    echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:108080" >> /opt/wireproxy.conf
else
    echo "Đã tìm thấy file cấu hình wireproxy.conf, bỏ qua bước tạo mới."
fi

wireproxy -c /opt/wireproxy.conf &
sleep 3

# ĐỔI SANG CỔNG 8888
PUBLIC_PORT=8888
INTERNAL_PROXY="socks5://127.0.0.1:108080"

echo "Đang khởi động GOST proxy trên cổng ${PUBLIC_PORT}..."

if [ -n "$SOCKS5_USERNAME" ] && [ -n "$SOCKS5_PASSWORD" ]; then
    echo "GOST đang chạy với xác thực..."
    gost -L "auto://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY}"
else
    echo "GOST đang chạy không cần xác thực..."
    gost -L "auto://0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY}"
fi
