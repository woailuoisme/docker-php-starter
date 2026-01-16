# ============================================================================
# PHP 基础镜像构建文件
# ============================================================================
ARG PHP_VERSION=8.4-cli-trixie
FROM php:${PHP_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

# 添加 extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

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

# 1. 系统依赖与仓库配置 (合并层以极大缩减体积)
RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg tzdata; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone; \
    curl -fSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    apt-get install -y --no-install-recommends \
    nodejs \
    gosu sudo gettext supervisor bash wget git openssh-client postgresql-client-18 \
    zip unzip ack ripgrep \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg"); \
    apt-get purge -y --auto-remove gnupg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nodesource.list /etc/apt/sources.list.d/pgdg.list

# ============================================================================
# 2. PHP 扩展配置与编译
# ============================================================================

RUN set -eux; \
    # 安装 igbinary 和压缩库依赖
    apt-get update; \
    apt-get install -y --no-install-recommends liblz4-dev libzstd-dev; \
    install-php-extensions igbinary; \
    # 编译安装 redis 并启用 igbinary, lz4, zstd 支持
    pecl install --configureoptions 'enable-redis-igbinary="yes" enable-redis-lz4="yes" enable-redis-zstd="yes"' redis; \
    docker-php-ext-enable redis; \
    # 安装其余核心扩展
    install-php-extensions \
    gd intl zip bcmath mbstring xml mysqli pdo_mysql opcache ffi \
    $([ "$WITH_PG" = "true" ] && echo "pgsql pdo_pgsql") \
    $([ "$WITH_LDAP" = "true" ] && echo "ldap") \
    $([ "$WITH_AMQP" = "true" ] && echo "amqp") \
    $([ "$WITH_IMAGICK" = "true" ] && echo "imagick") \
    $([ "$WITH_SWOOLE" = "true" ] && echo "swoole") \
    $([ "$WITH_UV" = "true" ] && echo "uv"); \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups; \
    ARCH_SUFFIX=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64"); \
    curl -fSL "https://dl.min.io/client/mc/release/linux-${ARCH_SUFFIX}/mc" -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/mc; \
    curl -fSL -o /usr/local/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH_SUFFIX}"; \
    chmod +x /usr/local/bin/supercronic; \
    find /usr/local/lib/php -name "*.a" -delete; \
    find /usr/local/lib/php -name "*.la" -delete; \
    rm -rf /tmp/pear


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
