# ============================================================================
# PHP 基础镜像构建文件
# ============================================================================

FROM php:8.4.14-cli-alpine3.22
LABEL maintainer="seaside <531773730@qq.com>"

# ============================================================================
# 构建参数配置
# ============================================================================

# 控制 APK 镜像源和可选功能
ARG CHANGE_SOURCE=true
ARG TIMEZONE=Asia/Shanghai

ARG WWWUSER=33
ARG WWWGROUP=33

# 可选功能开关
ARG WITH_PG=true
ARG WITH_AMQP=true
ARG WITH_LDAP=false
ARG WITH_SWOOLE=false
ARG SUPERCRONIC_VERSION=0.2.39

# ============================================================================
# 系统依赖安装和PHP扩展编译（合并为单个RUN指令以减少层数）
# ============================================================================

RUN set -eux; \
    if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi; \
    apk add --no-cache \
    bash gettext postgresql17-client \
    icu-libs libzip libxml2 oniguruma zlib \
    freetype libjpeg-turbo libpng libwebp libavif \
    tzdata libffi \
    && if [ "$WITH_PG" = "true" ]; then apk add --no-cache libpq; fi \
    && if [ "$WITH_LDAP" = "true" ]; then apk add --no-cache openldap; fi \
    && if [ "$WITH_AMQP" = "true" ]; then apk add --no-cache rabbitmq-c; fi \
    && if [ "$WITH_SWOOLE" = "true" ]; then apk add --no-cache openssl; fi \
    && ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && composer self-update --clean-backups \
    && apk add --no-cache --virtual .build-deps \
    autoconf gcc g++ make pkgconfig linux-headers \
    mysql-dev \
    freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libavif-dev \
    oniguruma-dev libxml2-dev zlib-dev libzip-dev icu-dev \
    libffi-dev \
    && if [ "$WITH_PG" = "true" ]; then apk add --no-cache --virtual .pg-build postgresql-dev; fi \
    && if [ "$WITH_LDAP" = "true" ]; then apk add --no-cache --virtual .ldap-build openldap-dev; fi \
    && if [ "$WITH_AMQP" = "true" ]; then apk add --no-cache --virtual .amqp-build rabbitmq-c-dev; fi \
    && if [ "$WITH_SWOOLE" = "true" ]; then apk add --no-cache --virtual .swoole-build openssl-dev; fi \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && if [ "$WITH_LDAP" = "true" ]; then docker-php-ext-configure ldap; fi \
    && docker-php-ext-install -j"$(nproc)" pdo pdo_mysql gd mbstring xml simplexml zip intl bcmath pcntl sockets exif \
    && docker-php-ext-install -j"$(nproc)" ffi \
    && if [ "$WITH_PG" = "true" ]; then docker-php-ext-install -j"$(nproc)" pdo_pgsql pgsql; fi \
    && if [ "$WITH_LDAP" = "true" ]; then docker-php-ext-install -j"$(nproc)" ldap; fi \
    && pecl install redis && docker-php-ext-enable redis \
    && if [ "$WITH_AMQP" = "true" ]; then pecl install amqp && docker-php-ext-enable amqp; fi \
    && if [ "$WITH_SWOOLE" = "true" ]; then pecl install swoole && docker-php-ext-enable swoole; fi \
    && pecl clear-cache \
    && rm -rf /tmp/pear /tmp/pecl-build \
    && apk del .build-deps \
    && if [ "$WITH_PG" = "true" ]; then apk del .pg-build; fi \
    && if [ "$WITH_LDAP" = "true" ]; then apk del .ldap-build; fi \
    && if [ "$WITH_AMQP" = "true" ]; then apk del .amqp-build; fi \
    && if [ "$WITH_SWOOLE" = "true" ]; then apk del .swoole-build; fi \
    && rm -rf /var/cache/apk/* \
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
    && addgroup -g ${WWWGROUP} www-data \
    && adduser -u ${WWWUSER} -D -H -G www-data www-data \
    && mkdir -p /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d \
    && chown -R www-data:www-data /var/www /tmp /var/log/php /var/run/php \
    /usr/local/etc/php/conf.d \
    && touch /var/log/php/error.log /var/log/php/slow.log \
    && chmod 644 /var/log/php/error.log /var/log/php/slow.log \
    && chmod 755 /var/log/php /var/run/php \
    && php -m | grep -i ffi || echo "FFI extension not loaded"

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www
