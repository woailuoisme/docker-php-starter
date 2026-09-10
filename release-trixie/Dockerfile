FROM debian:trixie-slim

ARG CHINA=false
ARG TZ=Asia/Shanghai
RUN if [ "${CHINA}" = "true" ]; then \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi && \
    apt-get update && \
    apt-get install -y --no-install-recommends libnss3-tools libvips42t64 tzdata curl && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*
