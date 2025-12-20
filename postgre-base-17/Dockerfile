ARG POSTGRES_VERSION=17.6-alpine
FROM postgres:${POSTGRES_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

ARG TIMEZONE=Asia/Shanghai
ARG CHANGE_SOURCE=true

RUN if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi

RUN apk update && apk add --no-cache \
    postgresql-pgvector \
    postgis \
    geos \
    proj \
    gdal \
    sfcgal \
    tzdata \
    && mkdir -p /usr/local/share/postgresql/extension \
    && mkdir -p /usr/local/lib/postgresql \
    && ln -sf /usr/share/postgresql17/extension/* /usr/local/share/postgresql/extension/ \
    && ln -sf /usr/lib/postgresql17/*.so /usr/local/lib/postgresql/ \
    && ln -sf /usr/share/postgresql18/extension/* /usr/local/share/postgresql/extension/ \
    && ln -sf /usr/lib/postgresql18/*.so /usr/local/lib/postgresql/ \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata