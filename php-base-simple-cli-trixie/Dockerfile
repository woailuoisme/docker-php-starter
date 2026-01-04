# ============================================================================
# PHP 基础镜像构建文件
# ============================================================================

FROM php:8.4-cli-trixie
LABEL maintainer="seaside <531773730@qq.com>"

# ============================================================================
# 构建参数配置
# ============================================================================

# 控制 Debian 镜像源和可选功能
ARG CHANGE_SOURCE=true
ARG TIMEZONE=Asia/Shanghai

ARG WWWUSER=33
ARG WWWGROUP=33

ARG WITH_PG=true
ARG WITH_AMQP=true
ARG WITH_IMAGICK=true
ARG WITH_FFMPEG=true
ARG WITH_MYSQL=false
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG SUPERCRONIC_VERSION=0.2.39

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖安装和PHP扩展编译（合并为单个RUN指令以减少层数）
# ============================================================================

RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
        sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update && apt-get install -y --no-install-recommends \
    bash gettext postgresql-client supervisor \
    libicu72 libzip4 libxml2 libonig5 zlib1g \
    libfreetype6 libjpeg62-turbo libpng16-16 libwebp7 libavif16 \
    tzdata libffi8 \
    $([ "$WITH_PG" = "true" ] && echo "libpq5") \
    $([ "$WITH_LDAP" = "true" ] && echo "libldap-2.5-0") \
    $([ "$WITH_AMQP" = "true" ] && echo "librabbitmq4") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "libssl3") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "imagemagick libmagickwand-6.q16-7") \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg") \
    && ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && composer self-update --clean-backups \
    && apt-get install -y --no-install-recommends \
    php8.4-gd php8.4-intl php8.4-zip php8.4-bcmath \
    php8.4-mbstring php8.4-xml php8.4-mysql php8.4-redis \
    php8.4-ffi \
    $([ "$WITH_PG" = "true" ] && echo "php8.4-pgsql") \
    $([ "$WITH_LDAP" = "true" ] && echo "php8.4-ldap") \
    $([ "$WITH_AMQP" = "true" ] && echo "php8.4-amqp") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "php8.4-swoole") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "php8.4-imagick") \
    && rm -rf /var/lib/apt/lists/* \
    && find /usr/local/lib/php -name "*.a" -delete \
    && find /usr/local/lib/php -name "*.la" -delete \
    && strip --strip-all $(which php) 2>/dev/null || true \
    && curl -sSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc  \
    && chmod +x /usr/local/bin/mc \
    && curl -sSL -o /usr/local/bin/supercronic https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64 \
    && chmod +x /usr/local/bin/supercronic

# ============================================================================
# 用户、目录和权限配置（合并到单个RUN指令以减少层数）
# ============================================================================

RUN deluser www-data 2>/dev/null || true \
    && delgroup www-data 2>/dev/null || true \
    && groupadd -g ${WWWGROUP} www-data \
    && useradd -u ${WWWUSER} -g www-data -M -s /bin/bash www-data \
    && mkdir -p /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d \
    && chown -R www-data:www-data /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d /usr/local/bin/supercronic \
    && touch /var/log/php/error.log /var/log/php/slow.log \
    && chmod 644 /var/log/php/error.log /var/log/php/slow.log \
    && chmod 755 /var/log/php /var/run/php \
    && php -m | grep -i ffi || echo "FFI extension not loaded"

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www
