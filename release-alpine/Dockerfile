FROM alpine:3.24

ARG CHINA=false
ARG TIMEZONE=Asia/Shanghai
RUN if [ "${CHINA}" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories; \
    fi && \
    apk add --no-cache nss-tools tzdata curl vips && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone