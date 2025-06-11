#!/bin/sh

# ĐỔI SANG CỔNG 8888
PROXY_PORT=8888
PROXY_URL="http://localhost:${PROXY_PORT}"

if [ -n "$SOCKS5_USERNAME" ]; then
    PROXY_URL="http://$SOCKS5_USERNAME:$SOCKS5_PASSWORD@localhost:${PROXY_PORT}"
fi

curl \
    -x "$PROXY_URL" \
    -f -s \
    --connect-timeout 5 \
    https://www.cloudflare.com/cdn-cgi/trace > /dev/null

exit $?
