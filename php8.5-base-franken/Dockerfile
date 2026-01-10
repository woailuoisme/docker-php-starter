FROM jiaoio/php-base-cli:8.5-latest


ENV VERSION=1.11.1 \
    FRANKENPHP_VERSION=1.11.1

# 必须声明此 ARG，Docker BuildKit 会自动填充它
ARG TARGETARCH

# 根据架构下载对应的 FrankenPHP 静态二进制文件并验证（支持多个镜像源）
COPY download-frankenphp.sh /usr/local/bin/download-frankenphp.sh
RUN export TARGETARCH=${TARGETARCH} && \
    chmod +x /usr/local/bin/download-frankenphp.sh && \
    /usr/local/bin/download-frankenphp.sh && \
    rm -f /usr/local/bin/download-frankenphp.sh && \
    frankenphp --version
