# ============================================================================
# PHP 8.5 Trixie Base Simple CLI Image
# ============================================================================
ARG PHP_VERSION=8.5-cli-trixie
FROM php:${PHP_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

# 添加 extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

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
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG WITH_UV=false
ARG WITH_RDKAFKA=false
ARG WITH_SEASCLICK=false
ARG WITH_MD4C=false
ARG WITH_OPEN_TELEMETRY=true
ARG WITH_XLSWRITER=true
ARG SUPERCRONIC_VERSION=0.2.41

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖与仓库配置
# ============================================================================

# 1. 系统依赖与仓库配置 (合并层以极大缩减体积)
RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg locales \
    webp libavif-bin jpegoptim optipng pngquant gifsicle; \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    curl -fSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    openssh-client postgresql-client-18 zip unzip; \
    apt-get purge -y --auto-remove gnupg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# 2. PHP 扩展配置与编译
# ============================================================================
# 默认已安装扩展: Core, ctype, curl, date, dom, fileinfo, filter, hash, iconv, json
# lexbor, libxml, mbstring, mysqlnd, openssl, pcre, PDO, pdo_sqlite, Phar, posix
# random, readline, Reflection, session, SimpleXML, sodium, SPL, sqlite3, standard
# tokenizer, uri, xml, xmlreader, xmlwriter, Zend OPcache, zlib
RUN set -eux; \
    install-php-extensions lz4 zstd igbinary msgpack simdjson redis; \
    install-php-extensions \
    bcmath gmp exif pcntl sockets protobuf intl zip ffi \
    gd; \
    if [ "${WITH_MYSQL:-false}" = "true" ]; then install-php-extensions mysqli pdo_mysql; fi; \
    if [ "${WITH_PG:-false}" = "true" ]; then install-php-extensions pgsql pdo_pgsql; fi; \
    if [ "${WITH_MONGODB:-false}" = "true" ]; then install-php-extensions mongodb; fi; \
    if [ "${WITH_LDAP:-false}" = "true" ]; then install-php-extensions ldap; fi; \
    if [ "${WITH_AMQP:-false}" = "true" ]; then install-php-extensions amqp; fi; \
    if [ "${WITH_SWOOLE:-false}" = "true" ]; then install-php-extensions swoole; fi; \
    if [ "${WITH_UV:-false}" = "true" ]; then install-php-extensions uv; fi; \
    if [ "${WITH_IMAGICK:-false}" = "true" ]; then install-php-extensions imagick; fi; \
    if [ "${WITH_OPEN_TELEMETRY:-false}" = "true" ]; then install-php-extensions opentelemetry; fi; \
    if [ "${WITH_XLSWRITER:-false}" = "true" ]; then install-php-extensions xlswriter; fi; \
    if [ "${WITH_RDKAFKA:-false}" = "true" ]; then install-php-extensions rdkafka; fi; \
    if [ "${WITH_SEASCLICK:-false}" = "true" ]; then install-php-extensions seasclick; fi; \
    if [ "${WITH_MD4C:-false}" = "true" ]; then install-php-extensions md4c; fi; \
    find /usr/local/lib/php -name "*.a" -delete; \
    find /usr/local/lib/php -name "*.la" -delete; \
    rm -f /etc/apt/sources.list.d/pgdg.list; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups

# ============================================================================
# 3. 外部工具与权限配置
# ============================================================================

ARG TARGETARCH
RUN set -eux; \
    ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64"); \
    curl -fSL "https://dl.min.io/client/mc/release/linux-${ARCH_SUFFIX}/mc" -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/mc; \
    curl -fSL -o /usr/local/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH_SUFFIX}"; \
    chmod +x /usr/local/bin/supercronic

RUN set -eux; \
    deluser www-data 2>/dev/null || true; \
    delgroup www-data 2>/dev/null || true; \
    groupadd -g ${WWWGROUP} www-data; \
    useradd -u ${WWWUSER} -g www-data -M -s /bin/bash www-data; \
    mkdir -p /var/www /tmp /var/log/php /usr/local/etc/php/conf.d; \
    chown -R www-data:www-data /var/www /tmp /var/log/php /usr/local/etc/php/conf.d /usr/local/bin/supercronic; \
    touch /var/log/php/error.log; \
    chmod 644 /var/log/php/error.log; \
    chmod 755 /var/log/php


WORKDIR /var/www
