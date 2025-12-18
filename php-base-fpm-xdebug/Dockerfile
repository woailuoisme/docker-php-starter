# ============================================================================
# PHP 基础镜像构建文件
# 基于 PHP 8.4 FPM Alpine 版本，包含所有PHP扩展和依赖
# 作为 php-fpm、php-queue、php-schedule 的基础镜像
# 优化版本：减少镜像体积，移除不必要的开发工具
# ============================================================================

FROM jiaoio/php-base-fpm
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
