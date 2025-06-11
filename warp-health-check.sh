#!/bin/sh

# --- Cấu hình ---
# Cổng public của proxy
PROXY_PORT=1080
# URL đích để kiểm tra kết nối
TARGET_URL="https://www.cloudflare.com/cdn-cgi/trace"
# Các tùy chọn chung cho curl
CURL_OPTS="-f -s --connect-timeout 5"

# --- Xử lý xác thực ---
AUTH_OPTS=""
if [ -n "$PROXY_USERNAME" ]; then
    AUTH_OPTS="--proxy-user $PROXY_USERNAME:$PROXY_PASSWORD"
fi

# --- Bắt đầu kiểm tra ---
# Chuyển hướng các thông báo trạng thái ra stderr (>%2) để không ảnh hưởng đến output chính
# và giúp xem log dễ dàng hơn.

# 1. Kiểm tra HTTP Proxy
# ========================
# echo "Health Check: Đang kiểm tra HTTP proxy..." >&2
curl ${CURL_OPTS} ${AUTH_OPTS} -x "http://localhost:${PROXY_PORT}" "${TARGET_URL}" > /dev/null
HTTP_CHECK_STATUS=$?

if [ ${HTTP_CHECK_STATUS} -ne 0 ]; then
    echo "Health Check FAILED: HTTP proxy không hoạt động (Exit code: ${HTTP_CHECK_STATUS})." >&2
    exit 1
fi
# echo "Health Check OK: HTTP proxy hoạt động tốt." >&2


# 2. Kiểm tra SOCKS5 Proxy
# =========================
# echo "Health Check: Đang kiểm tra SOCKS5 proxy..." >&2
# Dùng `socks5h` để proxy phân giải DNS, đây là một bài kiểm tra tốt hơn.
curl ${CURL_OPTS} ${AUTH_OPTS} -x "socks5h://localhost:${PROXY_PORT}" "${TARGET_URL}" > /dev/null
SOCKS_CHECK_STATUS=$?

if [ ${SOCKS_CHECK_STATUS} -ne 0 ]; then
    echo "Health Check FAILED: SOCKS5 proxy không hoạt động (Exit code: ${SOCKS_CHECK_STATUS})." >&2
    exit 1
fi
# echo "Health Check OK: SOCKS5 proxy hoạt động tốt." >&2


# --- Kết luận ---
# Nếu script chạy đến đây, có nghĩa là cả hai kiểm tra đều đã thành công.
# echo "Health Check PASSED: Cả HTTP và SOCKS5 đều hoạt động." >&2
exit 0
