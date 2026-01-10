# ============================================================================
# PHP 8.5 Trixie Base CLI Image
# ============================================================================
ARG PHP_VERSION=8.5-cli-trixie
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
ARG WITH_MYSQL=true
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG WITH_UV=false
ARG SUPERCRONIC_VERSION=0.2.41

ENV PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# ============================================================================
# 系统依赖与仓库配置
# ============================================================================

# 1. 镜像源配置 (Debian Trixie)
RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi

# 2. 添加 PostgreSQL 官方仓库 (PGDG) 以支持 PG 18
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg; \
    curl -fSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# 3. 安装系统核心依赖 (Runtime & Build Libs)
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
    tzdata libffi-dev \
    libicu-dev libzip-dev libxml2-dev libonig-dev zlib1g-dev \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libavif-dev \
    $([ "$WITH_PG" = "true" ] && echo "libpq-dev") \
    $([ "$WITH_LDAP" = "true" ] && echo "libldap2-dev") \
    $([ "$WITH_AMQP" = "true" ] && echo "librabbitmq-dev") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "libmagickwand-dev") \
    $([ "$WITH_UV" = "true" ] && echo "libuv1-dev")

# 4. 配置时区
RUN set -eux; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone

# ============================================================================
# PHP 扩展安装
# ============================================================================

# 5. 安装 PHP 核心扩展
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif; \
    $([ "$WITH_LDAP" = "true" ] && echo 'docker-php-ext-configure ldap;'); \
    docker-php-ext-install -j$(nproc) \
    bcmath exif gd intl pcntl sockets zip \
    $([ "$WITH_MYSQL" = "true" ] && echo "mysqli pdo_mysql") \
    $([ "$WITH_PG" = "true" ] && echo "pgsql pdo_pgsql") \
    $([ "$WITH_LDAP" = "true" ] && echo "ldap"); \
    docker-php-ext-install ffi

# 7. 安装 PECL 扩展
RUN set -eux; \
    pecl install redis && docker-php-ext-enable redis; \
    if [ "$WITH_AMQP" = "true" ]; then pecl install amqp && docker-php-ext-enable amqp; fi; \
    if [ "$WITH_SWOOLE" = "true" ]; then pecl install swoole && docker-php-ext-enable swoole; fi; \
    if [ "$WITH_UV" = "true" ]; then pecl install uv && docker-php-ext-enable uv; fi

# 8. 安装 Imagick (备选版本逻辑)
RUN set -eux; \
    if [ "$WITH_IMAGICK" = "true" ]; then \
    pecl install imagick || pecl install imagick-3.7.0; \
    docker-php-ext-enable imagick; \
    fi

# ============================================================================
# 外部工具与终端环境
# ============================================================================

# 9. 安装 Composer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups

# 10. 安装 Node.js 与系统常用工具 (含 postgresql-client-18)
RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    apt-get install -y --no-install-recommends \
    gosu sudo gettext supervisor bash wget git openssh-client postgresql-client-18 \
    zip unzip ack ripgrep \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg")

# 11. 下载多架构二进制工具 (mc, supercronic)
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

# 12. 用户管理与权限
RUN set -eux; \
    deluser www-data 2>/dev/null || true; \
    delgroup www-data 2>/dev/null || true; \
    groupadd -g ${WWWGROUP} www-data; \
    useradd -u ${WWWUSER} -g www-data -M -s /bin/bash www-data; \
    mkdir -p /var/www /tmp /var/log/php /var/log/supervisor /var/run/supervisor /usr/local/etc/php/conf.d; \
    chown -R www-data:www-data /var/www /tmp /var/log/php /var/log/supervisor /var/run/supervisor /usr/local/etc/php/conf.d /usr/local/bin/supercronic; \
    touch /var/log/php/error.log; \
    chmod 644 /var/log/php/error.log; \
    chmod 755 /var/log/php /var/log/supervisor /var/run/supervisor

# 13. 清理构建缓存
RUN set -eux; \
    apt-get purge -y --auto-remove gnupg; \
    rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nodesource.list; \
    find /usr/local/lib/php -name "*.a" -delete 2>/dev/null || true; \
    find /usr/local/lib/php -name "*.la" -delete 2>/dev/null || true; \
    pecl clear-cache; \
    rm -rf /tmp/pear

WORKDIR /var/www
