FROM caddy:2.10.2-builder-alpine AS builder
LABEL maintainer="seaside <531773730@qq.com>"

# 运行 xcaddy build 来构建，不需要指定核心模块，它们会自动包含。
RUN xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddyserver/transform-encoder  \
    --with github.com/hslatman/caddy-crowdsec-bouncer/crowdsec \
    --with github.com/mholt/caddy-l4 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddyserver/ipfilter \
    --with github.com/caddyserver/replace-response

# 阶段 2: 最终运行镜像
FROM caddy:2.10.2-alpine
# 替换官方的 caddy 可执行文件为我们构建的版本
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

ARG CHANGE_SOURCE=false
ARG TIMEZONE=Asia/Shanghai
RUN if [ "${CHANGE_SOURCE}" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories; \
    fi && \
    apk add --no-cache nss-tools tzdata curl && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone
