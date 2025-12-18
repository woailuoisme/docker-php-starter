FROM alpine:3.23
LABEL maintainer="seaside <531773730@qq.com>"

ARG CHANGE_SOURCE=false
ARG TIMEZONE=Asia/Shanghai
ARG PGBOUNCER_VERSION=1.25.0-r0

# 更换镜像源（可选）
RUN if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi

# 安装 pgbouncer 和必要工具
RUN apk add --no-cache \
    pgbouncer \
    postgresql-client \
    tzdata \
    bash \
    curl \
    netcat-openbsd \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata

# 创建非 root 用户和必要目录
RUN addgroup -S pgbouncer && adduser -S pgbouncer -G pgbouncer \
    && mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer \
    && chown -R pgbouncer:pgbouncer /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer

# 复制配置文件
COPY --chown=pgbouncer:pgbouncer pgbouncer.ini /etc/pgbouncer/
COPY --chown=pgbouncer:pgbouncer userlist.txt /etc/pgbouncer/
COPY --chown=pgbouncer:pgbouncer entrypoint.sh /usr/local/bin/

# 设置执行权限
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod 600 /etc/pgbouncer/userlist.txt

EXPOSE 6432

# 优化的健康检查 - 使用 TCP 端口检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD nc -z 127.0.0.1 6432 || exit 1

# 切换到非 root 用户
USER pgbouncer

# 使用 entrypoint 脚本启动
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
