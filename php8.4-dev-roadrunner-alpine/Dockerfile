# ============================================================================
# PHP 8.4 Dev RoadRunner Alpine Image
# ============================================================================
FROM jiaoio/php8.4-dev:cli-alpine
LABEL maintainer="seaside <531773730@qq.com>"

# RoadRunner 在 Alpine 上运行需要 gcompat 或 libc6-compat
RUN set -eux; \
    apk add --no-cache gcompat

# 必须声明此 ARG，Docker BuildKit 会自动填充它
ARG TARGETARCH
ARG ROADRUNNER_VERSION=2025.1.7

COPY download-roadrunner.sh /tmp/download-roadrunner.sh
RUN export TARGETARCH=${TARGETARCH} && \
    chmod +x /tmp/download-roadrunner.sh && \
    ROADRUNNER_VERSION=${ROADRUNNER_VERSION} /tmp/download-roadrunner.sh && \
    rm /tmp/download-roadrunner.sh