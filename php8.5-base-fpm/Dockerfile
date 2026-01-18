# ============================================================================
# PHP 8.5 Alpine Base FPM Image
# ============================================================================
ARG PHP_VERSION=8.5-fpm-alpine3.23
FROM php:${PHP_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

# ============================================================================
# 构建参数配置
# ============================================================================

ARG CHANGE_SOURCE=true
ARG TIMEZONE=Asia/Shanghai

ARG WWWUSER=33
ARG WWWGROUP=33

# 可选功能开关
ARG WITH_PG=true
ARG WITH_AMQP=true
ARG WITH_IMAGICK=true
ARG WITH_MYSQL=true
ARG WITH_MONGODB=true
ARG WITH_FFMPEG=false
ARG WITH_SWOOLE=false
ARG WITH_LDAP=false
ARG SUPERCRONIC_VERSION=0.2.41

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖与环境配置
# ============================================================================

# 1. 镜像源与基础工具
RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi; \
    apk update; \
    apk add --no-cache \
    bash curl fcgi gettext git gosu grep openssh-client \
    postgresql18-client sudo supervisor tar unzip wget zip nodejs

# 2. 运行时库依赖 (保留非PHP扩展依赖)
RUN set -eux; \
    apk add --no-cache \
    tzdata \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg")

# 3. 配置时区
RUN set -eux; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone

# ============================================================================
# PHP 扩展安装 (使用 install-php-extensions 简化构建)
# ============================================================================

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# 4. 安装扩展
# 默认已安装扩展: Core, ctype, curl, date, dom, fileinfo, filter, hash, iconv, json
# lexbor, libxml, mbstring, mysqlnd, openssl, pcre, PDO, pdo_sqlite, Phar, posix
# random, readline, Reflection, session, SimpleXML, sodium, SPL, sqlite3, standard
# tokenizer, uri, xml, xmlreader, xmlwriter, Zend OPcache, zlib
RUN set -eux; \
    install-php-extensions lz4 zstd igbinary redis; \
    install-php-extensions \
    bcmath exif pcntl sockets protobuf intl zip ffi \
    gd; \
    if [ "${WITH_MYSQL:-false}" = "true" ]; then install-php-extensions mysqli pdo_mysql; fi; \
    if [ "${WITH_PG:-false}" = "true" ]; then install-php-extensions pgsql pdo_pgsql; fi; \
    if [ "${WITH_MONGODB:-false}" = "true" ]; then install-php-extensions mongodb; fi; \
    if [ "${WITH_LDAP:-false}" = "true" ]; then install-php-extensions ldap; fi; \
    if [ "${WITH_AMQP:-false}" = "true" ]; then install-php-extensions amqp; fi; \
    if [ "${WITH_SWOOLE:-false}" = "true" ]; then install-php-extensions swoole; fi; \
    if [ "${WITH_IMAGICK:-false}" = "true" ]; then install-php-extensions imagick; fi; \
    rm -rf /tmp/pear /var/cache/apk/*; \
    find /usr/local/lib/php -name "*.a" -delete; \
    find /usr/local/lib/php -name "*.la" -delete

# ============================================================================
# 应用工具与权限配置
# ============================================================================

# 5. 安装 Composer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups

# 6. 下载多架构二进制工具 (mc, supercronic)
ARG TARGETARCH
RUN set -eux; \
    ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64"); \
    curl -fSL "https://dl.min.io/client/mc/release/linux-${ARCH_SUFFIX}/mc" -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/mc; \
    curl -fSL -o /usr/local/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH_SUFFIX}"; \
    chmod +x /usr/local/bin/supercronic

# 7. 用户、目录与权限配置
RUN set -eux; \
    deluser www-data 2>/dev/null || true; \
    delgroup www-data 2>/dev/null || true; \
    addgroup -g ${WWWGROUP} www-data; \
    adduser -u ${WWWUSER} -D -H -G www-data www-data; \
    mkdir -p /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d; \
    chown -R www-data:www-data /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d; \
    touch /var/log/php/error.log /var/log/php/slow.log; \
    chmod 644 /var/log/php/error.log /var/log/php/slow.log; \
    chmod 755 /var/log/php /var/run/php

WORKDIR /var/www
