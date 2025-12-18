# ============================================================================
# Xdebug 调试工具
# ============================================================================
FROM jiaoio/php-base-cli
LABEL maintainer="seaside <531773730@qq.com>"

ARG WITH_XDEBUG=true

# ============================================================================
# Xdebug 安装和配置
# ============================================================================
RUN set -eux; \
    if [ "$WITH_XDEBUG" = "true" ]; then \
    apk add --no-cache --virtual .xdebug-build \
    autoconf gcc g++ make pkgconfig linux-headers gettext && \
    pecl install xdebug && docker-php-ext-enable xdebug && \
    pecl clear-cache && \
    rm -rf /tmp/pear /tmp/pecl-build && \
    apk del .xdebug-build; \
    fi

# ============================================================================
# Xdebug 配置文件复制
# ============================================================================

COPY xdebug.ini /usr/local/etc/php/conf.d/99-xdebug.ini

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www

EXPOSE 9001 9003
