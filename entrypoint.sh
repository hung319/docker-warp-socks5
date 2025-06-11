#!/bin/sh

# --- Bước 1: Cấu hình WireGuard với wgcf ---
# Không cần thiết phải chạy lại các lệnh này nếu đã có file wireproxy.conf
# Tuy nhiên, để script tự hoạt động hoàn toàn, ta vẫn giữ lại.
if [ ! -f /opt/wireproxy.conf ]; then
    echo "Đang cấu hình WireGuard lần đầu..."
    mkdir -p /opt/wgcf
    wgcf register --accept-tos --config /opt/wgcf/wgcf-account.toml
    wgcf generate --config /opt/wgcf/wgcf-account.toml
    mv wgcf-profile.conf /opt/wireproxy.conf
    # Cấu hình WireProxy để chạy SOCKS5 trên cổng nội bộ 108080 để tránh trùng lặp
    echo -e "\n[Socks5]\nBindAddress = 127.0.0.1:108080" >> /opt/wireproxy.conf
else
    echo "Đã tìm thấy file cấu hình wireproxy.conf, bỏ qua bước tạo mới."
fi


# --- Bước 2: Chạy WireProxy trong nền ---
# WireProxy sẽ chỉ lắng nghe trên localhost, cổng 108080
wireproxy -c /opt/wireproxy.conf &

# Đợi một chút để WireProxy khởi động hoàn tất
sleep 3

# --- Bước 3: Cấu hình và chạy GOST để public proxy ra ngoài trên CỔNG 1080 ---
PUBLIC_PORT=1080
INTERNAL_PROXY="socks5://127.0.0.1:108080"

echo "Đang khởi động GOST proxy trên cổng ${PUBLIC_PORT}..."

# Thêm xác thực nếu biến môi trường được cung cấp
if [ -n "$SOCKS5_USERNAME" ] && [ -n "$SOCKS5_PASSWORD" ]; then
    echo "GOST đang chạy với xác thực..."
    gost -L "auto://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY}"
else
    echo "GOST đang chạy không cần xác thực..."
    gost -L "auto://0.0.0.0:${PUBLIC_PORT}" -F "${INTERNAL_PROXY}"
fi
