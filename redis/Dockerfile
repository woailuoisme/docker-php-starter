ARG REDIS_VERSION=8.4-alpine
FROM redis:${REDIS_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

ARG CHANGE_SOURCE=true
ENV TIMEZONE=Asia/Shanghai

RUN if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi

RUN apk update && apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    apk del tzdata
## For security settings uncomment, make the dir, copy conf, and also start with the conf, to use it
RUN mkdir -p /usr/local/etc/redis
COPY redis.conf /usr/local/etc/redis/redis.conf

VOLUME /data

EXPOSE 6379

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
#CMD ["redis-server"]
