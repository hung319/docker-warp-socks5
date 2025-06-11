#!/bin/sh

# --- Bước 1: Cấu hình WireGuard với wgcf ---
echo "Đang cấu hình WireGuard..."
mkdir -p /opt/wgcf
wgcf register --accept-tos --config /opt/wgcf/wgcf-account.toml
wgcf generate --config /opt/wgcf/wgcf-account.toml
mv wgcf-profile.conf /opt/wireproxy.conf

# --- Bước 2: Cấu hình WireProxy để chạy SOCKS5 trên cổng nội bộ ---
# WireProxy sẽ chỉ lắng nghe trên localhost, cổng 1080.
echo "Đang cấu hình WireProxy..."
echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:1080" >>/opt/wireproxy.conf

# Chạy WireProxy trong nền
wireproxy -c /opt/wireproxy.conf &

# Đợi một chút để WireProxy khởi động hoàn tất
sleep 3

# --- Bước 3: Cấu hình và chạy GOST để public proxy ra ngoài ---
# GOST sẽ mở cổng 40000, nhận cả SOCKS5 và HTTP,
# sau đó chuyển tiếp tất cả đến cổng SOCKS5 của WireProxy.
echo "Đang khởi động GOST proxy trên cổng 40000..."

# Lệnh của GOST
# -L: Chế độ lắng nghe. "auto://" tự động nhận diện giao thức.
#     nghe trên địa chỉ 0.0.0.0, cổng 40000.
# -F: Chế độ chuyển tiếp. Chuyển đến socks5://127.0.0.1:1080.
#
# Thêm xác thực nếu biến môi trường được cung cấp
if [ -n "$SOCKS5_USERNAME" ] && [ -n "$SOCKS5_PASSWORD" ]; then
    echo "GOST đang chạy với xác thực..."
    gost -L "auto://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@0.0.0.0:40000" -F "socks5://127.0.0.1:1080"
else
    echo "GOST đang chạy không cần xác thực..."
    gost -L "auto://0.0.0.0:40000" -F "socks5://127.0.0.1:1080"
fi
