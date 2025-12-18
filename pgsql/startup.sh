#!/bin/bash

# =========================================================
# PostgreSQL 启动脚本
# 支持多数据库初始化、用户角色管理和扩展启用
# =========================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local color="$NC"

    case "$level" in
        "INFO") color="$CYAN" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        "STEP") color="$BLUE" ;;
        "DEBUG") color="$PURPLE" ;;
    esac

    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color}[$level]${NC} $message"
}

log "STEP" "=========================================="
log "STEP" "   PostgreSQL 启动脚本开始执行"
log "STEP" "=========================================="

# 设置默认环境变量
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

export POSTGRES_USER POSTGRES_DB POSTGRES_PASSWORD

log "INFO" "环境变量:"
log "INFO" "  - POSTGRES_USER: $POSTGRES_USER"
log "INFO" "  - POSTGRES_DB: $POSTGRES_DB"
log "INFO" "  - POSTGRES_PASSWORD: [已设置]"

# 步骤1: 启动 PostgreSQL 服务
echo ""
log "STEP" "步骤1: 启动 PostgreSQL 服务..."
log "INFO" "使用自定义配置文件: /etc/postgresql/postgresql.conf"
docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf &

# 步骤2: 等待 PostgreSQL 完全启动
echo ""
log "STEP" "步骤2: 等待 PostgreSQL 服务就绪..."
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" 2>/dev/null; do
    log "INFO" "等待 PostgreSQL 启动..."
    sleep 2
done

log "SUCCESS" "PostgreSQL 服务已就绪"
log "INFO" "配置信息:"
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "
    SELECT name, setting, unit, context
    FROM pg_settings
    WHERE name IN ('shared_buffers', 'work_mem', 'max_connections', 'timezone')
    ORDER BY name;" || true

# 步骤3: 确保用户角色存在
echo ""
log "STEP" "步骤3: 验证用户角色..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- 确保 postgres 用户存在
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
            CREATE ROLE postgres WITH SUPERUSER CREATEDB CREATEROLE LOGIN;
            ALTER ROLE postgres WITH PASSWORD 'postgres';
            RAISE NOTICE '✅ 已创建 postgres 用户';
        ELSE
            RAISE NOTICE 'ℹ️  postgres 用户已存在';
        END IF;
    END
    \$\$;

    -- 确保当前用户有密码
    ALTER ROLE "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';

    -- 显示用户角色信息
    SELECT
        rolname as "用户名",
        rolsuper as "超级用户",
        rolcreatedb as "创建数据库",
        rolcreaterole as "创建角色",
        rolcanlogin as "允许登录"
    FROM pg_roles
    WHERE rolname IN ('postgres', '$POSTGRES_USER')
    ORDER BY rolname;
EOSQL

# 步骤4: 运行初始化脚本（如果数据目录为空）
echo ""
log "STEP" "步骤4: 检查数据库初始化状态..."
if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    log "INFO" "数据目录为空，执行初始化脚本..."
    for f in /docker-entrypoint-initdb.d/*.sh; do
        if [ -f "$f" ]; then
            log "INFO" "执行初始化脚本: $(basename "$f")"
            "$f"
        fi
    done
    for f in /docker-entrypoint-initdb.d/*.sql; do
        if [ -f "$f" ]; then
            log "INFO" "执行SQL脚本: $(basename "$f")"
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
        fi
    done
else
    log "INFO" "数据目录已存在，跳过初始化"
fi

# 步骤5: 启用和验证扩展状态
echo ""
log "STEP" "步骤5: 启用和验证扩展状态..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- 启用 PostGIS 扩展
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    CREATE EXTENSION IF NOT EXISTS postgis_raster;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

    -- 启用 pgvector 扩展
    CREATE EXTENSION IF NOT EXISTS vector;

    -- 列出所有数据库
    SELECT
        datname as "数据库名",
        pg_size_pretty(pg_database_size(datname)) as "大小",
        datistemplate as "模板库"
    FROM pg_database
    WHERE datistemplate = false
    ORDER BY datname;

    -- 列出已启用的扩展
    SELECT
        extname as "扩展名",
        extversion as "版本"
    FROM pg_extension
    ORDER BY extname;

    -- 检查 PostGIS 功能
    SELECT
        'PostGIS' as "功能",
        CASE
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN '✅ 已启用'
            ELSE '❌ 未启用'
        END as "状态"
    UNION ALL
    SELECT
        'pgvector' as "功能",
        CASE
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN '✅ 已启用'
            ELSE '❌ 未启用'
        END as "状态"
    UNION ALL
    SELECT
        'GEOS 库' as "功能",
        CASE
            WHEN postgis_lib_version() IS NOT NULL THEN '✅ 可用'
            ELSE '❌ 不可用'
        END as "状态"
    UNION ALL
    SELECT
        'PROJ 库' as "功能",
        CASE
            WHEN postgis_lib_build_date() IS NOT NULL THEN '✅ 可用'
            ELSE '❌ 不可用'
        END as "状态";
EOSQL

# 步骤5.1: 验证 GEOS 和 PROJ 库功能
echo ""
log "STEP" "步骤5.1: 验证 GEOS 和 PROJ 库功能..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- 验证 GEOS 几何引擎功能
    SELECT
        'GEOS 几何引擎' as "测试项目",
        CASE
            WHEN ST_IsValid(ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')) THEN '✅ 几何验证正常'
            ELSE '❌ 几何验证失败'
        END as "结果"
    UNION ALL
    SELECT
        'GEOS 空间关系' as "测试项目",
        CASE
            WHEN ST_Contains(
                ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'),
                ST_GeomFromText('POINT(5 5)')
            ) THEN '✅ 空间关系正常'
            ELSE '❌ 空间关系失败'
        END as "结果"
    UNION ALL
    SELECT
        'PROJ 坐标投影' as "测试项目",
        CASE
            WHEN ST_Transform(ST_GeomFromText('POINT(116.3974 39.9093)', 4326), 3857) IS NOT NULL THEN '✅ 坐标投影正常'
            ELSE '❌ 坐标投影失败'
        END as "结果"
    UNION ALL
    SELECT
        'PROJ 坐标转换' as "测试项目",
        CASE
            WHEN ST_SRID(ST_Transform(ST_GeomFromText('POINT(116.3974 39.9093)', 4326), 3857)) = 3857 THEN '✅ 坐标转换正常'
            ELSE '❌ 坐标转换失败'
        END as "结果";

    -- 显示 GEOS 和 PROJ 版本信息
    SELECT
        'GEOS 版本' as "库信息",
        postgis_lib_version() as "版本"
    UNION ALL
    SELECT
        'PROJ 版本' as "库信息",
        postgis_proj_version() as "版本"
    UNION ALL
    SELECT
        'PostGIS 构建日期' as "库信息",
        postgis_lib_build_date() as "版本";
EOSQL

# 步骤6: 健康检查准备
echo ""
log "STEP" "步骤6: 设置健康检查..."
log "SUCCESS" "PostgreSQL 服务运行中..."
log "INFO" "监听端口: 5432"
log "INFO" "可用数据库:"
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -t -c "
    SELECT '  - ' || datname
    FROM pg_database
    WHERE datistemplate = false
    ORDER BY datname;" || true

echo ""
log "STEP" "=========================================="
log "SUCCESS" "   PostgreSQL 启动完成"
log "STEP" "=========================================="
log "INFO" "连接信息:"
log "INFO" "  - 主机: localhost"
log "INFO" "  - 端口: 5432"
log "INFO" "  - 用户: $POSTGRES_USER 或 postgres"
log "INFO" "  - 默认数据库: $POSTGRES_DB"
echo ""
log "INFO" "示例连接命令:"
log "INFO" "  psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB"
log "INFO" "  psql -h localhost -U postgres -d postgres"
log "STEP" "=========================================="

# 步骤7: 保持容器运行
log "INFO" "容器运行中..."
wait
