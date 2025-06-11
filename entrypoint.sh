#!/bin/sh

# Cổng public mà người dùng sẽ kết nối vào
PUBLIC_PORT=1080

# Cổng nội bộ cho wireproxy (phải là một số hợp lệ từ 1-65535)
INTERNAL_WIREPROXY_PORT=51821

# --- Bước 1: Cấu hình WireGuard ---
if [ ! -f /opt/wireproxy.conf ]; then
    echo "Đang cấu hình WireGuard lần đầu..."
    mkdir -p /opt/wgcf
    wgcf register --accept-tos --config /opt/wgcf/wgcf-account.toml
    wgcf generate --config /opt/wgcf/wgcf-account.toml
    mv wgcf-profile.conf /opt/wireproxy.conf
    # SỬA LỖI: Dùng cổng nội bộ hợp lệ
    echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:${INTERNAL_WIREPROXY_PORT}" >> /opt/wireproxy.conf
else
    echo "Đã tìm thấy file cấu hình wireproxy.conf, bỏ qua bước tạo mới."
fi


# --- Bước 2: Chạy WireProxy trong nền ---
echo "Khởi chạy wireproxy nội bộ trên cổng ${INTERNAL_WIREPROXY_PORT}..."
wireproxy -c /opt/wireproxy.conf &

# Đợi một chút để WireProxy khởi động hoàn tất
sleep 3

# --- Bước 3: Chạy GOST để public proxy ra ngoài ---
INTERNAL_PROXY_URL="socks5://127.0.0.1:${INTERNAL_WIREPROXY_PORT}"

echo "Đang khởi động GOST proxy trên cổng public ${PUBLIC_PORT}..."

# Thêm xác thực nếu biến môi trường được cung cấp
if [ -n "$SOCKS5_USERNAME" ] && [ -n "$SOCKS5_PASSWORD" ]; then
    echo "GOST đang chạy với xác thực."
    gost -L "auto://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY_URL}"
else
    echo "GOST đang chạy không cần xác thực."
    gost -L "auto://0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY_URL}"
fi
