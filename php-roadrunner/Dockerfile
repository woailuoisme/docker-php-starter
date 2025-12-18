FROM jiaoio/php-base-cli
# 安装 glibc 兼容层（RoadRunner 需要 glibc）
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community gcompat
ARG ROADRUNNER_VERSION=2025.1.6
ARG TARGETARCH=arm64
COPY install-roadrunner.sh /tmp/install-roadrunner.sh
RUN chmod +x /tmp/install-roadrunner.sh && \
    ROADRUNNER_VERSION=${ROADRUNNER_VERSION} FORCE_ARCH=${TARGETARCH} /tmp/install-roadrunner.sh && \
    rm /tmp/install-roadrunner.sh

ENV APP_PATH=/var/www/lunchbox \
    APP_PORT=8001 \
    APP_ENV=docker \
    APP_DEBUG=true \
    ENABLE_SUPERVISOR=false \
    OCTANE_RR_BINARY=/usr/local/bin/rr \
    OCTANE_SERVER=roadrunner \
    OCTANE_HOST=0.0.0.0 \
    OCTANE_WORKERS=4 \
    OCTANE_MAX_REQUESTS=300 \
    OCTANE_LOG_LEVEL=info \
    WATCH=false \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PYTHONWARNINGS="ignore:pkg_resources is deprecated"

# 复制PHP配置
#COPY config/php.ini $PHP_INI_DIR/conf.d/99-custom.ini
COPY config/*.ini /usr/local/etc/php/conf.d/

# 复制启动脚本
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# 复制健康检查脚本
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# 创建必要的 supervisor 目录
RUN mkdir -p /usr/local/etc/supervisord.d

# 复制 Supervisor 主配置文件
COPY supervisord.conf /usr/local/etc/supervisord.conf

# 健康检测配置
HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

EXPOSE ${APP_PORT} 9103
WORKDIR $APP_PATH
USER www-data
CMD ["/usr/local/bin/startup.sh"]
