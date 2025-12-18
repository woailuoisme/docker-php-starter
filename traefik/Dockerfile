FROM traefik:v3.6

# 环境变量
ENV TZ=Asia/Shanghai \
    DOMAIN=localhost \
    ACME_EMAIL=admin@localhost \
    ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory

# 安装必要工具
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    bash

# 创建必要的目录
RUN mkdir -p \
    /config/dynamic \
    /config/certs \
    /config/acme \
    /traefik/logs

# 设置权限
RUN chmod 700 /config/acme && \
    touch /config/acme/acme.json && \
    chmod 600 /config/acme/acme.json

# 复制主配置文件
COPY traefik.yml /etc/traefik/traefik.yml

# 复制动态配置
COPY config/dynamic/ /config/dynamic/

# 复制证书生成脚本
COPY config/certs/ /config/certs/

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置工作目录
WORKDIR /etc/traefik

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q -O- http://localhost:80/ping || exit 1

# 暴露端口
EXPOSE 80 443 8080 8082 5432 6379

# 启动命令
ENTRYPOINT ["/entrypoint.sh"]
