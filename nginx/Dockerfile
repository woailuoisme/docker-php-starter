ARG NGINX_VERSION=1.29-alpine
FROM nginx:${NGINX_VERSION}

LABEL maintainer="seaside <seaside@qq.com>"
# 复制配置文件
COPY nginx.conf /etc/nginx/
# 环境变量配置
ARG CHANGE_SOURCE=false
ARG TIMEZONE=Asia/Shanghai
ARG PHP_UPSTREAM_CONTAINER=php-fpm
ARG PHP_UPSTREAM_PORT=9000
# 用户和组ID配置，默认值为33(www-data)
ARG WWWUSER=33
ARG WWWGROUP=33

ENV DOMIAN=jso.lol \
    PROXY_FPM=app-fpm,rest,php-fpm:9000 \
    PROXY_FRNAKEN=app-octane,dev,php-franken:8001 \
    PROXY_REVERB=app-reverb,ws,php-reverb:8080 \
    PROXY_DOZZLE=dozzle,dozzle,dozzle:8080 \
    PROXY_MINIO=minio,mos,minio:9000 \
    PROXY_MINIO_CONSOLE=minio-console,mo,minio:9001 \
    PROXY_MILISEARCH=meilisearch,search,meilisearch:7700 \
    PROXY_RABBITMQ=rabbitmq,mq,rabbitmq:15672

# 设置时区和包源
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories; \
    fi && \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
    gettext \
    logrotate \
    openssl \
    bash \
    tzdata \
    apache2-utils \
    yq \
    curl && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    touch /var/log/messages

RUN set -x ; \
    deluser www-data 2>/dev/null || true ; \
    delgroup www-data 2>/dev/null || true ; \
    addgroup -g ${WWWUSER} -S www-data ; \
    adduser -u ${WWWGROUP} -D -S -G www-data www-data

# 确保 /run 和 /var/run 目录对 www-data 用户可写
RUN mkdir -p /run /var/run && \
    chown -R www-data:www-data /run /var/run && \
    chmod 755 /run /var/run

# 确保 Nginx 缓存目录存在并具有正确的权限
RUN mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chmod -R 755 /var/cache/nginx

# 复制配置文件和代码片段
COPY logrotate/nginx /etc/logrotate.d/
COPY snippets /etc/nginx/snippets

# 复制用户配置文件和初始化脚本
COPY users.yml /etc/nginx/auth/
COPY scripts/init-users.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-users.sh

# 移除默认配置
RUN rm -f /etc/nginx/conf.d/default.conf

# 复制启动脚本并设置执行权限
COPY scripts/startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh && \
    chmod +x /opt/startup.sh

#   pgrep nginx - 查找所有名为"nginx"的进程
#   如果找到进程（返回状态码0），命令成功
#   状态码0 : 健康（找到nginx进程）
#   状态码1 : 不健康（未找到nginx进程）
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD pgrep nginx -l > /dev/null || exit 1

# 容器启动命令和端口暴露
CMD ["/bin/bash", "/opt/startup.sh"]
EXPOSE 80 81 443 46379 45432
