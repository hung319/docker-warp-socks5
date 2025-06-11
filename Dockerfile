# Sử dụng base image Alpine Linux 3.19 nhỏ gọn
FROM alpine:3.19

# Đặt các phiên bản CỐ ĐỊNH của công cụ tại đây để đảm bảo ổn định
ENV WGCF_VERSION=v2.2.26
ENV WIREPROXY_VERSION=v1.0.9
ENV GOST_VERSION=v3.0.0-rc9

# Cài đặt các gói cần thiết và các công cụ từ URL đã chỉ định
RUN \
    # Bước 1: Cài đặt curl
    apk add --no-cache curl && \
    \
    # Bước 2: Xác định kiến trúc của hệ thống
    ARCH=$(uname -m) && \
    case ${ARCH} in \
        "x86_64") ARCH="amd64" ;; \
        "aarch64") ARCH="arm64" ;; \
        *) echo "LỖI: Kiến trúc ${ARCH} không được hỗ trợ"; exit 1 ;; \
    esac && \
    \
    # Bước 3: Tải WGCF từ URL cố định
    echo "Dang tai WGCF phien ban ${WGCF_VERSION}..." && \
    curl -fsSL "https://github.com/ViRb3/wgcf/releases/download/${WGCF_VERSION}/wgcf_${WGCF_VERSION#v}_linux_${ARCH}" -o /usr/bin/wgcf && \
    chmod +x /usr/bin/wgcf && \
    \
    # Bước 4: Tải WireProxy v1.0.9 từ 'whyvl/wireproxy'
    echo "Dang tai WireProxy phien ban ${WIREPROXY_VERSION} tu repo 'whyvl'..." && \
    curl -fsSL "https://github.com/whyvl/wireproxy/releases/download/${WIREPROXY_VERSION}/wireproxy_linux_${ARCH}.tar.gz" | tar -xz -C /usr/bin/ wireproxy && \
    chmod +x /usr/bin/wireproxy && \
    \
    # Bước 5: Tải GOST từ URL cố định
    echo "Dang tai GOST phien ban ${GOST_VERSION}..." && \
    curl -fsSL "https://github.com/go-gost/gost/releases/download/${GOST_VERSION}/gost_${GOST_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/bin/ gost && \
    chmod +x /usr/bin/gost

# Sao chép các script cần thiết vào image
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD warp-health-check.sh /usr/local/bin/warp-health-check.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/warp-health-check.sh

# Mở cổng proxy - ĐÃ ĐỔI SANG CỔNG 1080
EXPOSE 1080/tcp

# Chỉ định script khởi động mặc định
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Cấu hình kiểm tra sức khỏe của container
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "/usr/local/bin/warp-health-check.sh" ]
