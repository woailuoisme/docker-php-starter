# =========================================================
# PostgreSQL with PostGIS and pgvector
# =========================================================
ARG POSTGRES_VERSION=17.6-alpine
FROM postgres:${POSTGRES_VERSION}

# 设置环境变量
ENV POSTGRES_DB=postgres
ARG CHANGE_SOURCE=true

# 切换为中国源（如果启用）
RUN if [ "${CHANGE_SOURCE}" = "true" ]; then \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    fi

# 安装编译和运行所需的依赖包
RUN apk update && \
    apk add --no-cache \
    build-base \
    git \
    postgresql-dev \
    postgis \
    geos \
    proj

# 编译安装 pgvector
WORKDIR /tmp
RUN git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make PG_CONFIG=/usr/bin/pg_config OPTFLAGS="" && \
    make PG_CONFIG=/usr/bin/pg_config install && \
    cd .. && \
    rm -rf pgvector

# 创建所有扩展的符号链接
RUN mkdir -p /usr/local/share/postgresql/extension && \
    mkdir -p /usr/local/lib/postgresql && \
    ln -sf /usr/share/postgresql17/extension/* /usr/local/share/postgresql/extension/ 2>/dev/null || true && \
    ln -sf /usr/lib/postgresql17/*.so /usr/local/lib/postgresql/ 2>/dev/null || true && \
    echo "扩展符号链接创建完成"

# 清理构建工具以减小镜像大小
RUN apk del --purge build-base git && \
    rm -rf /var/cache/apk/*

# 复制初始化脚本
COPY ./initdb.d/ /docker-entrypoint-initdb.d/

# 设置脚本执行权限
RUN chmod +x /docker-entrypoint-initdb.d/*.sh

# 复制配置文件和启动脚本
COPY ./postgresql.conf /etc/postgresql/postgresql.conf
COPY ./startup.sh /startup.sh
RUN chmod +x /startup.sh

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pg_isready -U postgres

# 设置工作目录
WORKDIR /var/lib/postgresql

# 设置启动脚本和配置参数
CMD ["/startup.sh"]

# 暴露端口
EXPOSE 5432
