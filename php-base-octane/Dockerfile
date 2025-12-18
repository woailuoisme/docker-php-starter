# ============================================================================
# PHP Base Octane Image - Laravel Octane Support
# ============================================================================

FROM jiaoio/php-base-cli
LABEL maintainer="seaside <531773730@qq.com>"

# 环境变量配置
ENV RR_VERSION=2025.1.5 \
    FRANKENPHP_VERSION=1.9.1

# 复制 FrankenPHP 下载脚本
COPY download-frankenphp.sh /tmp/download-frankenphp.sh
RUN chmod +x /tmp/download-frankenphp.sh

# 安装 RoadRunner (暂时跳过)
# RUN set -eux; \
#     curl -L -o /tmp/rr.tar.gz \
#     https://github.com/roadrunner-server/roadrunner/releases/download/v${RR_VERSION}/rr-${RR_VERSION}-linux-$(uname -m).tar.gz \
#     && tar -xzf /tmp/rr.tar.gz -C /tmp/ \
#     && mv /tmp/rr /usr/local/bin/rr \
#     && chmod +x /usr/local/bin/rr \
#     && rm -rf /tmp/rr.tar.gz

# 安装 FrankenPHP
RUN set -eux; \
    /tmp/download-frankenphp.sh \
    && rm -f /tmp/download-frankenphp.sh

# ============================================================================
# 验证安装
# ============================================================================

RUN frankenphp --version \
    && php -m | grep swoole

# ============================================================================
# 工作目录设置
# ============================================================================

WORKDIR /var/www
