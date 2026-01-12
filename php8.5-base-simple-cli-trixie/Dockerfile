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
ARG WITH_FFMPEG=false
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
    tzdata \
    bash gettext openssh-client postgresql-client-18 supervisor zip unzip \
    $([ "$WITH_FFMPEG" = "true" ] && echo "ffmpeg")

# 4. 配置时区
RUN set -eux; \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime; \
    echo "${TIMEZONE}" > /etc/timezone

# ============================================================================
# PHP 扩展配置与编译 (合并层以减小体积)
# ============================================================================

# 5. 配置 & 安装核心扩展
RUN set -eux; \
    install-php-extensions \
    bcmath exif pcntl sockets intl zip ffi redis \
    gd; \
    if [ "$WITH_MYSQL" = "true" ]; then install-php-extensions mysqli pdo_mysql; fi; \
    if [ "$WITH_PG" = "true" ]; then install-php-extensions pgsql pdo_pgsql; fi; \
    if [ "$WITH_LDAP" = "true" ]; then install-php-extensions ldap; fi; \
    if [ "$WITH_AMQP" = "true" ]; then install-php-extensions amqp; fi; \
    if [ "$WITH_SWOOLE" = "true" ]; then install-php-extensions swoole; fi; \
    if [ "$WITH_UV" = "true" ]; then install-php-extensions uv; fi; \
    if [ "$WITH_IMAGICK" = "true" ]; then install-php-extensions imagick; fi; \
    find /usr/local/lib/php -name "*.a" -delete; \
    find /usr/local/lib/php -name "*.la" -delete

# ============================================================================
# 外部工具安装
# ============================================================================

# 6. 安装 Composer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    chmod +x /usr/local/bin/composer; \
    composer self-update --clean-backups

# 7. 下载多架构二进制工具 (mc, supercronic)
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

# 8. 用户管理与权限
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

# 9. 清理构建缓存
RUN set -eux; \
    apt-get purge -y --auto-remove gnupg; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www
