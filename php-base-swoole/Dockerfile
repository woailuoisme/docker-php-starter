FROM jiaoio/php-base-cli

ARG WITH_SWOOLE=true
ARG SWOOLE_VERSION=6.1.5

# 安装 Swoole 扩展（如果基础镜像未安装）
RUN if ! php -m | grep -i swoole; then \
        apk add --no-cache openssl && \
        apk add --no-cache --virtual .swoole-build autoconf gcc g++ make pkgconfig linux-headers openssl-dev && \
        pecl install swoole-${SWOOLE_VERSION} && \
        docker-php-ext-enable swoole && \
        apk del .swoole-build && \
        rm -rf /tmp/pear /tmp/pecl-build; \
    fi && \
    php --ri swoole