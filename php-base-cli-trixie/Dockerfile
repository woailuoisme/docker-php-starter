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
ARG WITH_FFMPEG=true
ARG WITH_MYSQL=false
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG WITH_UV=false

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖安装和PHP扩展编译（合并为单个RUN指令以减少层数）
# ============================================================================

RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
        sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    libfcgi-bin gosu sudo gettext nodejs supervisor bash wget curl git openssh-client postgresql-client \
    libicu72 libzip4 libxml2 libonig5 zlib1g ack ripgrep \
    libfreetype6 libjpeg62-turbo libpng16-16 libwebp7 libavif16 \
    tzdata libffi8 \
    $([ "$WITH_PG" = "true" ] && echo "libpq5") \
    $([ "$WITH_LDAP" = "true" ] && echo "libldap-2.5-0") \
    $([ "$WITH_AMQP" = "true" ] && echo "librabbitmq4") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "libssl3") \
    $([ "$WITH_UV" = "true" ] && echo "libuv1") \
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
    && if [ "$WITH_UV" = "true" ]; then \
        apt-get install -y --no-install-recommends autoconf gcc g++ make pkg-config libuv1-dev && \
        pecl install uv && docker-php-ext-enable uv && \
        apt-get purge -y --auto-remove autoconf gcc g++ make pkg-config libuv1-dev && \
        pecl clear-cache && rm -rf /tmp/pear /tmp/pecl-build; \
    fi \
    && apt-get purge -y --auto-remove ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nodesource.list \
    && find /usr/local/lib/php -name "*.a" -delete \
    && find /usr/local/lib/php -name "*.la" -delete \
    && strip --strip-all $(which php) 2>/dev/null || true \
    && curl -sSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc  \
    && chmod +x /usr/local/bin/mc \
    && curl -sSL -o /usr/local/bin/supercronic https://github.com/aptible/supercronic/releases/download/v0.2.34/supercronic-linux-amd64 \
    && chmod +x /usr/local/bin/supercronic \
    && corepack enable \
    && corepack prepare pnpm@latest --activate \
    && curl -fsSL https://bun.sh/install | bash \
    && ln -s /root/.bun/bin/bun /usr/local/bin/bun

# ============================================================================
# 用户、目录和权限配置（合并到单个RUN指令以减少层数）
# ============================================================================

RUN deluser www-data 2>/dev/null || true \
    && delgroup www-data 2>/dev/null || true \
    && groupadd -g ${WWWGROUP} www-data \
    && useradd -u ${WWWUSER} -g www-data -M -s /bin/bash www-data \
    && mkdir -p /var/www /tmp /var/log/php /var/run/php \
    /var/log/supervisor /var/run/supervisor \
    /usr/local/etc/php/conf.d /usr/local/etc/php-fpm.d \
    && chown -R www-data:www-data /var/www /tmp /var/log/php /var/run/php \
    /var/log/supervisor /var/run/supervisor \
    /usr/local/etc/php/conf.d /usr/local/etc/php-fpm.d \
    && touch /var/log/php/error.log /var/log/php/slow.log \
    && chmod 644 /var/log/php/error.log /var/log/php/slow.log \
    && chmod 755 /var/log/php /var/run/php /var/log/supervisor /var/run/supervisor

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www
