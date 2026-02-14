FROM caddy:2.10.2-builder-alpine AS builder

RUN xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddyserver/transform-encoder  \
    --with github.com/mholt/caddy-l4 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddyserver/replace-response \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/lindenlab/caddy-s3-proxy \
    --with github.com/sagikazarmark/caddy-fs-s3 \
    --with github.com/pberkel/caddy-storage-redis

# 第二阶段：使用 Debian 运行
FROM debian:trixie-slim

# 拷贝二进制文件
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

ARG CHANGE_SOURCE=false
ARG TIMEZONE=Asia/Shanghai
RUN set -eux; \
    if [ "${CHANGE_SOURCE}" = "true" ]; then \
        # 尝试修改默认源（适配新版 Debian 的 sources.list.d/debian.sources 或旧版 sources.list）
        if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
            sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
        elif [ -f /etc/apt/sources.list ]; then \
            sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list; \
        fi; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libnss3-tools \
        tzdata \
        curl \
        ca-certificates; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80 443 2019