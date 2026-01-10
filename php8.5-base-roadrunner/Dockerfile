FROM jiaoio/php-base-cli:8.5-latest

# 安装 glibc 兼容层（RoadRunner 需要 glibc）
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community gcompat

# 必须声明此 ARG，Docker BuildKit 会自动填充它
ARG TARGETARCH
ARG ROADRUNNER_VERSION=2025.1.6

COPY download-roadrunner.sh /tmp/download-roadrunner.sh
RUN export TARGETARCH=${TARGETARCH} && \
    chmod +x /tmp/download-roadrunner.sh && \
    ROADRUNNER_VERSION=${ROADRUNNER_VERSION} /tmp/download-roadrunner.sh && \
    rm /tmp/download-roadrunner.sh