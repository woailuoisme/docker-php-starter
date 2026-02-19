# ============================================================================
# PHP Base RoadRunner Trixie Image
# ============================================================================
FROM jiaoio/php-base-cli-trixie
LABEL maintainer="seaside <531773730@qq.com>"

# Debian Trixie 已经是 glibc 系统，RoadRunner 可以直接运行，无需额外安装

# 必须声明此 ARG，Docker BuildKit 会自动填充它
ARG TARGETARCH
ARG ROADRUNNER_VERSION=2025.1.7

COPY download-roadrunner.sh /tmp/download-roadrunner.sh
RUN export TARGETARCH=${TARGETARCH} && \
    chmod +x /tmp/download-roadrunner.sh && \
    ROADRUNNER_VERSION=${ROADRUNNER_VERSION} /tmp/download-roadrunner.sh && \
    rm /tmp/download-roadrunner.sh