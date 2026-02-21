# ============================================================================
# PHP 8.4 Prod FrankenPHP Trixie Image
# ============================================================================
FROM jiaoio/php8.4:cli-trixie
LABEL maintainer="seaside <531773730@qq.com>"

# 必须声明此 ARG，Docker BuildKit 会自动填充它
ARG TARGETARCH
ARG FRANKENPHP_VERSION=1.11.2

ENV VERSION=${FRANKENPHP_VERSION} \
    FRANKENPHP_VERSION=${FRANKENPHP_VERSION}

# 根据架构下载对应的 FrankenPHP 静态二进制文件并验证（支持多个镜像源）
COPY download-frankenphp.sh /usr/local/bin/download-frankenphp.sh
RUN export TARGETARCH=${TARGETARCH} && \
    chmod +x /usr/local/bin/download-frankenphp.sh && \
    /usr/local/bin/download-frankenphp.sh && \
    rm -f /usr/local/bin/download-frankenphp.sh && \
    frankenphp --version
