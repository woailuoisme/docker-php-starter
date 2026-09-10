ARG CADDY_VERSION=2.11.4

# 阶段 1: 编译构建
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder

# 运行 xcaddy build 来构建，不需要指定核心模块，它们会自动包含。
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddyserver/transform-encoder \
    --with github.com/mholt/caddy-l4 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddyserver/replace-response \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/lindenlab/caddy-s3-proxy \
    --with github.com/corazawaf/coraza-caddy/v2

# 阶段 2: 最终运行镜像
FROM caddy:${CADDY_VERSION}-alpine
LABEL maintainer="seaside <531773730@qq.com>"

ARG TIMEZONE=Asia/Shanghai
ENV TZ=${TIMEZONE}

# 安装基础运行依赖并配置时区（前置以最大化利用构建层缓存）
RUN apk add --no-cache nss-tools tzdata curl && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

# 替换官方的 caddy 可执行文件为我们构建的版本
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
