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

# 可选功能开关
ARG WITH_PG=true
ARG WITH_AMQP=true
ARG WITH_IMAGICK=true
ARG WITH_FFMPEG=false
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG WITH_UV=false
ARG SUPERCRONIC_VERSION=0.2.41

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖安装和PHP扩展编译（合并为单个RUN指令以减少层数）
# ============================================================================

# 声明目标架构
ARG TARGETARCH

RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
        sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg tzdata \
    libicu-dev libzip-dev libxml2-dev libonig-dev zlib1g-dev \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libavif-dev \
    $([ "$WITH_PG" = "true" ] && echo "libpq-dev") \
    $([ "$WITH_LDAP" = "true" ] && echo "libldap2-dev") \
    $([ "$WITH_AMQP" = "true" ] && echo "librabbitmq-dev") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "libmagickwand-dev") \
    $([ "$WITH_UV" = "true" ] && echo "libuv1-dev") \
    && ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install -j$(nproc) \
    gd intl zip bcmath mbstring xml mysqli pdo_mysql opcache ffi \
    $([ "$WITH_PG" = "true" ] && echo "pgsql pdo_pgsql") \
    $([ "$WITH_LDAP" = "true" ] && echo "ldap") \
    && pecl install redis && docker-php-ext-enable redis \
    && if [ "$WITH_AMQP" = "true" ]; then \
        pecl install amqp && docker-php-ext-enable amqp; \
    fi \
    && if [ "$WITH_IMAGICK" = "true" ]; then \
        pecl install imagick && docker-php-ext-enable imagick; \
    fi \
    && if [ "$WITH_SWOOLE" = "true" ]; then \
        pecl install swoole && docker-php-ext-enable swoole; \
    fi \
    && if [ "$WITH_UV" = "true" ]; then \
        pecl install uv && docker-php-ext-enable uv; \
    fi \
    && pecl clear-cache && rm -rf /tmp/pear \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && composer self-update --clean-backups \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && node --version && npm --version \
    && apt-get install -y --no-install-recommends \
    gosu sudo gettext supervisor bash wget git openssh-client postgresql-client \
    ack ripgrep \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg") \
    && ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") \
    && curl -sSL "https://dl.min.io/client/mc/release/linux-${ARCH_SUFFIX}/mc" -o /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc \
    && curl -sSL -o /usr/local/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH_SUFFIX}" \
    && chmod +x /usr/local/bin/supercronic \
    && apt-get purge -y --auto-remove gnupg \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nodesource.list \
    && find /usr/local/lib/php -name "*.a" -delete 2>/dev/null || true \
    && find /usr/local/lib/php -name "*.la" -delete 2>/dev/null || true

# ============================================================================
# 用户、目录和权限配置（合并到单个RUN指令以减少层数）
# ============================================================================

RUN deluser www-data 2>/dev/null || true \
    && delgroup www-data 2>/dev/null || true \
    && groupadd -g ${WWWGROUP} www-data \
    && useradd -u ${WWWUSER} -g www-data -M -s /bin/bash www-data \
    && mkdir -p /var/www /tmp /var/log/php \
    /var/log/supervisor /var/run/supervisor \
    /usr/local/etc/php/conf.d \
    && chown -R www-data:www-data /var/www /tmp /var/log/php \
    /var/log/supervisor /var/run/supervisor \
    /usr/local/etc/php/conf.d \
    && touch /var/log/php/error.log \
    && chmod 644 /var/log/php/error.log \
    && chmod 755 /var/log/php /var/log/supervisor /var/run/supervisor

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www
