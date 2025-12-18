FROM portainer/portainer-ce:alpine
LABEL maintainer="seaside <531773730@qq.com>"

# 创建用于存储密码文件的目录
RUN mkdir -p /run/secrets

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:9000/api/system/status || exit 1

ENTRYPOINT ["/entrypoint.sh"]

# 默认命令
CMD ["--admin-password-file", "/run/secrets/portainer_password"]
