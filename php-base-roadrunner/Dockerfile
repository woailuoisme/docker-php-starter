FROM jiaoio/php-base-cli
# 安装 glibc 兼容层（RoadRunner 需要 glibc）
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community gcompat
ARG ROADRUNNER_VERSION=2025.1.6
COPY install-roadrunner.sh /tmp/install-roadrunner.sh
RUN chmod +x /tmp/install-roadrunner.sh && \
    ROADRUNNER_VERSION=${ROADRUNNER_VERSION} /tmp/install-roadrunner.sh && \
    rm /tmp/install-roadrunner.sh