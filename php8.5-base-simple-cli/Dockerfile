# ============================================================================
# PHP 8.5 Alpine Base Simple CLI Image
# ============================================================================
ARG PHP_VERSION=8.5-cli-alpine3.23
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
ARG WITH_FFMPEG=false
ARG WITH_MYSQL=false
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG SUPERCRONIC_VERSION=0.2.41

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖安装与编译配置
# ============================================================================

# 1. 镜像源配置
RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi

# 2. 安装基础系统工具
RUN set -eux; \
    apk add --no-cache \
    bash \
    curl \
    gettext \
    git \
    openssh-client \
    postgresql18-client \
    supervisor \
    tar \
    unzip \
    wget \
    zip

# 3. 安装扩展依赖库 (运行环境)
RUN set -eux; \
    apk add --no-cache \
    freetype \
    icu-libs \
    libavif \
    libjpeg-turbo \
    libpng \
    libwebp \
    libzip \
    libxml2 \
    oniguruma \
    zlib \
    tzdata \
    libffi \
    $([ "$WITH_PG" = "true" ] && echo "libpq") \
    $([ "$WITH_LDAP" = "true" ] && echo "openldap") \
    $([ "$WITH_AMQP" = "true" ] && echo "rabbitmq-c") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "openssl") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "imagemagick") \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg")

# 4. 配置时区
RUN set -eux; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone

# ============================================================================
# PHP 扩展编译安装
# ============================================================================

# 5. 安装 PHP 核心扩展
RUN set -eux; \
    # 安装编译工具
    apk add --no-cache --virtual .build-deps \
    autoconf \
    g++ \
    gcc \
    make \
    pkgconfig \
    linux-headers \
    libffi-dev \
    freetype-dev \
    icu-dev \
    libavif-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxml2-dev \
    libzip-dev \
    oniguruma-dev \
    zlib-dev \
    $([ "$WITH_PG" = "true" ] && echo "postgresql-dev") \
    $([ "$WITH_LDAP" = "true" ] && echo "openldap-dev") \
    $([ "$WITH_AMQP" = "true" ] && echo "rabbitmq-c-dev") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "openssl-dev") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "imagemagick-dev"); \
    \
    # 配置并安装并行的核心扩展
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif; \
    $([ "$WITH_LDAP" = "true" ] && echo 'docker-php-ext-configure ldap;'); \
    docker-php-ext-install -j$(nproc) \
    bcmath \
    exif \
    gd \
    intl \
    mbstring \
    mysqli \
    pdo_mysql \
    pcntl \
    sockets \
    xml \
    zip \
    $([ "$WITH_PG" = "true" ] && echo "pgsql pdo_pgsql") \
    $([ "$WITH_LDAP" = "true" ] && echo "ldap")

# 6. 单独安装 FFI
RUN docker-php-ext-install ffi

# 7. 单独安装 Opcache
RUN docker-php-ext-install opcache

# 8. 安装 PECL 扩展
RUN set -eux; \
    # 重新安装编译依赖
    apk add --no-cache --virtual .build-deps-pecl \
    autoconf g++ gcc make pkgconfig linux-headers \
    $([ "$WITH_AMQP" = "true" ] && echo "rabbitmq-c-dev") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "openssl-dev") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "imagemagick-dev"); \
    \
    pecl install redis && docker-php-ext-enable redis; \
    if [ "$WITH_AMQP" = "true" ]; then pecl install amqp && docker-php-ext-enable amqp; fi; \
    if [ "$WITH_SWOOLE" = "true" ]; then pecl install swoole && docker-php-ext-enable swoole; fi; \
    if [ "$WITH_IMAGICK" = "true" ]; then pecl install imagick && docker-php-ext-enable imagick; fi; \
    \
    # 清理所有编译依赖
    apk del .build-deps-pecl; \
    apk del .build-deps || true; \
    rm -rf /tmp/pear /tmp/pecl-build; \
    find /usr/local/lib/php -name "*.a" -delete; \
    find /usr/local/lib/php -name "*.la" -delete

# ============================================================================
# 外部工具安装
# ============================================================================

# 9. 安装 Composer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups

# 10. 下载多架构二进制工具 (mc, supercronic)
ARG TARGETARCH
RUN set -eux; \
    ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64"); \
    curl -fSL "https://dl.min.io/client/mc/release/linux-${ARCH_SUFFIX}/mc" -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/mc; \
    curl -fSL -o /usr/local/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH_SUFFIX}"; \
    chmod +x /usr/local/bin/supercronic

# ============================================================================
# 用户、目录与权限配置
# ============================================================================

# 11. 用户、目录与权限配置
RUN set -eux; \
    deluser www-data 2>/dev/null || true; \
    delgroup www-data 2>/dev/null || true; \
    addgroup -g ${WWWGROUP} www-data; \
    adduser -u ${WWWUSER} -D -H -G www-data www-data; \
    mkdir -p /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d; \
    chown -R www-data:www-data /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d /usr/local/bin/supercronic; \
    touch /var/log/php/error.log /var/log/php/slow.log; \
    chmod 644 /var/log/php/error.log /var/log/php/slow.log; \
    chmod 755 /var/log/php /var/run/php

WORKDIR /var/www
