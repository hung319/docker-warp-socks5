# Sử dụng base image Alpine Linux 3.19 nhỏ gọn
FROM alpine:3.19

# Cài đặt các gói cần thiết và các công cụ từ GitHub trong cùng một layer
RUN \
    # Bước 1: Cài đặt các gói CƠ BẢN từ repository của Alpine
    apk add --no-cache curl jq && \
    \
    # Bước 2: Xác định kiến trúc của hệ thống
    ARCH=$(uname -m) && \
    case ${ARCH} in \
        "x86_64") ARCH="amd64" ;; \
        "aarch64") ARCH="arm64" ;; \
        "i386" | "i686") ARCH="386" ;; \
    esac && \
    \
    # Bước 3: Tải và cài đặt wgcf
    echo "Dang tim URL tai ve cho wgcf (kien truc ${ARCH})..." && \
    WGCF_URL=$(curl -fsSL https://api.github.com/repos/ViRb3/wgcf/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"_linux_${ARCH}\") and (contains(\".zip\") | not))" | head -n 1) && \
    if [ -z "${WGCF_URL}" ]; then echo "LỖI: Không tìm thấy URL tải về cho wgcf!" >&2; exit 1; fi && \
    echo "Dang tai wgcf tu ${WGCF_URL}" && \
    curl -fsSL "${WGCF_URL}" -o /usr/bin/wgcf && \
    chmod +x /usr/bin/wgcf && \
    \
    # Thêm một khoảng chờ 2 giây để tránh bị giới hạn truy cập API
    sleep 2 && \
    \
    # Bước 4: Tải wireproxy từ fork 'whyvl/wireproxy'
    echo "Dang tim URL tai ve cho wireproxy (kien truc ${ARCH})..." && \
    WIREPROXY_URL=$(curl -fsSL https://api.github.com/repos/whyvl/wireproxy/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"linux-${ARCH}\"))" | head -n 1) && \
    if [ -z "${WIREPROXY_URL}" ]; then echo "LỖI: Không tìm thấy URL tải về cho wireproxy từ fork whyvl!" >&2; exit 1; fi && \
    echo "Dang tai wireproxy tu ${WIREPROXY_URL}" && \
    curl -fsSL "${WIREPROXY_URL}" -o /usr/bin/wireproxy && \
    chmod +x /usr/bin/wireproxy && \
    \
    # Thêm một khoảng chờ 2 giây nữa
    sleep 2 && \
    \
    # Bước 5: Tải và cài đặt GOST
    echo "Dang tim URL tai ve cho GOST (kien truc ${ARCH})..." && \
    GOST_URL=$(curl -fsSL https://api.github.com/repos/go-gost/gost/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"linux-${ARCH}.tar.gz\"))" | head -n 1) && \
    if [ -z "${GOST_URL}" ]; then echo "LỖI: Không tìm thấy URL tải về cho GOST!" >&2; exit 1; fi && \
    echo "Dang tai GOST tu ${GOST_URL}" && \
    curl -fsSL "${GOST_URL}" | tar -xz -C /usr/bin/ gost && \
    chmod +x /usr/bin/gost

# Sao chép các script cần thiết vào image
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD warp-health-check.sh /usr/local/bin/warp-health-check.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/warp-health-check.sh

# Mở cổng proxy
EXPOSE 40000/tcp

# Chỉ định script khởi động mặc định
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Cấu hình kiểm tra sức khỏe của container
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "/usr/local/bin/warp-health-check.sh" ]
