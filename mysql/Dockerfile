ARG MYSQL_VERSION=8.4
FROM mysql:${MYSQL_VERSION}
LABEL maintainer="seaside <531773730@qq.com>"

ARG TIMEZONE=Asia/Shanghai
ARG CHANGE_SOURCE=false

# 更换为国内镜像源（可选）- Oracle Linux 使用 microdnf/yum
RUN if [ "$CHANGE_SOURCE" = "true" ]; then \
    sed -i 's|yum.oracle.com|mirrors.aliyun.com/oracle-linux|g' /etc/yum.repos.d/*.repo 2>/dev/null || true; \
    fi

# 安装必要工具
RUN microdnf install -y \
    curl \
    ca-certificates \
    && microdnf clean all

# 设置时区（MySQL 官方镜像已包含 tzdata）
RUN ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone

# 创建必要的目录并设置权限
RUN mkdir -p /var/log/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/log/mysql /var/run/mysqld \
    && chmod 755 /var/run/mysqld

# 复制简化的配置文件
COPY my.cnf /etc/mysql/conf.d/my.cnf
# 设置配置文件权限
RUN chmod 644 /etc/mysql/conf.d/my.cnf

# 复制初始化脚本
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

EXPOSE 3306 33060
# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
