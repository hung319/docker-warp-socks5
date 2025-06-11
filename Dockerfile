# Sử dụng base image Alpine Linux 3.19 nhỏ gọn
FROM alpine:3.19

# Cài đặt các gói cần thiết và các công cụ từ GitHub trong cùng một layer
RUN \
    # Bước 1: Cài đặt các gói từ repository của Alpine
    apk add --no-cache curl gost jq && \
    \
    # Bước 2: Xác định kiến trúc của hệ thống (amd64, arm64, etc.)
    ARCH=$(uname -m) && \
    case ${ARCH} in \
        "x86_64") ARCH="amd64" ;; \
        "aarch64") ARCH="arm64" ;; \
        "i386" | "i686") ARCH="386" ;; \
    esac && \
    \
    # Bước 3: Tải và cài đặt wgcf (vẫn tự động vì repo đang hoạt động tốt)
    echo "Dang tim URL tai ve cho wgcf (kien truc ${ARCH})..." && \
    WGCF_URL=$(curl -fsSL https://api.github.com/repos/ViRb3/wgcf/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"_linux_${ARCH}\") and (contains(\".zip\") | not)) | head -n 1") && \
    if [ -z "${WGCF_URL}" ]; then \
        echo "LỖI: Không tìm thấy URL tải về cho wgcf!" >&2; \
        exit 1; \
    fi && \
    echo "Dang tai wgcf tu ${WGCF_URL}" && \
    curl -fsSL "${WGCF_URL}" -o /usr/bin/wgcf && \
    chmod +x /usr/bin/wgcf && \
    \
    # Bước 4: Tải wireproxy (SỬ DỤNG PHIÊN BẢN CỐ ĐỊNH ĐỂ ĐẢM BẢO ỔN ĐỊNH)
    # Repo của Wireproxy đã bị archived, nên ta sẽ dùng link trực tiếp đến phiên bản v1.1.2
    echo "Dang chuan bi tai ve wireproxy v1.1.2 (kien truc ${ARCH})..." && \
    WIREPROXY_VERSION="v1.1.2" && \
    case ${ARCH} in \
        "amd64") WIREPROXY_URL="https://github.com/pufferffish/wireproxy/releases/download/${WIREPROXY_VERSION}/wireproxy_linux_amd64.tar.gz" ;; \
        "arm64") WIREPROXY_URL="https://github.com/pufferffish/wireproxy/releases/download/${WIREPROXY_VERSION}/wireproxy_linux_arm64.tar.gz" ;; \
        "386") WIREPROXY_URL="https://github.com/pufferffish/wireproxy/releases/download/${WIREPROXY_VERSION}/wireproxy_linux_386.tar.gz" ;; \
        *) echo "LỖI: Kiến trúc ${ARCH} không được wireproxy hỗ trợ trong phiên bản này." >&2; exit 1 ;; \
    esac && \
    echo "Dang tai wireproxy tu ${WIREPROXY_URL}" && \
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
