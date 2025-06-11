# Sử dụng base image Alpine Linux 3.19 nhỏ gọn
FROM alpine:3.19

# Cài đặt các gói cần thiết và các công cụ từ GitHub trong cùng một layer
RUN \
    # Bước 1: Cài đặt các gói từ repository của Alpine
    # Thêm 'gost' vào đây là thay đổi quan trọng nhất
    apk add --no-cache curl gost && \
    \
    # Bước 2: Xác định kiến trúc của hệ thống (amd64, arm64, etc.)
    ARCH=$(uname -m) && \
    case ${ARCH} in \
        "x86_64") ARCH="amd64" ;; \
        "aarch64") ARCH="arm64" ;; \
        "i386" | "i686") ARCH="386" ;; \
    esac && \
    \
    # Bước 3: Tải và cài đặt phiên bản wgcf mới nhất
    echo "Dang tai wgcf cho kien truc ${ARCH}..." && \
    WGCF_URL=$(curl -fsSL https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep 'browser_download_url' | cut -d'"' -f4 | grep "_linux_${ARCH}") && \
    curl -fsSL "${WGCF_URL}" -o /usr/bin/wgcf && \
    chmod +x /usr/bin/wgcf && \
    \
    # Bước 4: Tải và cài đặt phiên bản wireproxy mới nhất
    echo "Dang tai wireproxy cho kien truc ${ARCH}..." && \
    WIREPROXY_URL=$(curl -fsSL https://api.github.com/repos/pufferffish/wireproxy/releases/latest | grep 'browser_download_url' | cut -d'"' -f4 | grep "wireproxy_linux_${ARCH}.tar.gz") && \
    curl -fsSL "${WIREPROXY_URL}" | tar -xz -C /usr/bin/ && \
    chmod +x /usr/bin/wireproxy

# Sao chép các script cần thiết vào image
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD warp-health-check.sh /usr/local/bin/warp-health-check.sh

# Mở cổng proxy
EXPOSE 40000/tcp

# Chỉ định script khởi động mặc định
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Cấu hình kiểm tra sức khỏe của container
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "/usr/local/bin/warp-health-check.sh" ]
