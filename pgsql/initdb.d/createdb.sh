#!/usr/bin/env bash

#
# 多数据库初始化脚本
# 自动创建多个应用数据库并启用所有扩展
#

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

# 执行 SQL 命令并处理错误
execute_sql() {
    local dbname="$1"
    local sql="$2"

    log_info "在数据库 $dbname 执行 SQL 命令..."
    if ! psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$dbname" <<< "$sql"; then
        log_error "在数据库 $dbname 执行 SQL 失败"
        return 1
    fi
    return 0
}

# 创建数据库函数
create_database() {
    local dbname="$1"
    local description="$2"

    log_info "创建数据库: $dbname ($description)"

    if ! psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE DATABASE IF NOT EXISTS $dbname;
        GRANT ALL PRIVILEGES ON DATABASE $dbname TO "$POSTGRES_USER";
EOSQL
    then
        log_error "创建数据库 $dbname 失败"
        return 1
    fi

    log_success "数据库 $dbname 创建成功"
    return 0
}

# 启用扩展函数
enable_extensions() {
    local dbname="$1"

    log_info "为数据库 $dbname 启用扩展..."

    local extensions_sql="
        -- PostGIS 扩展
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_topology;
        CREATE EXTENSION IF NOT EXISTS postgis_raster;
        CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

        -- pgvector 扩展
        CREATE EXTENSION IF NOT EXISTS vector;
    "

    if ! execute_sql "$dbname" "$extensions_sql"; then
        log_error "为数据库 $dbname 启用扩展失败"
        return 1
    fi

    log_success "数据库 $dbname 扩展启用完成"
    return 0
}

# 主函数
main() {
    log_info "开始多数据库初始化..."

    # 检查环境变量
    if [[ -z "$POSTGRES_USER" ]] || [[ -z "$POSTGRES_DB" ]]; then
        log_error "缺少必要的环境变量: POSTGRES_USER 或 POSTGRES_DB"
        exit 1
    fi

    log_info "使用用户: $POSTGRES_USER, 默认数据库: $POSTGRES_DB"

    # 创建 postgres 用户（如果不存在）
    log_info "检查 postgres 用户..."
    if ! execute_sql "$POSTGRES_DB" "
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
                CREATE ROLE postgres WITH SUPERUSER CREATEDB CREATEROLE LOGIN;
            END IF;
        END
        \$\$;
    "; then
        log_warning "创建 postgres 用户失败或已存在"
    fi

    # 创建各个数据库
    databases=(
        "lunchbox:午餐盒应用"
        "shop:商店应用"
        "domost:智能家居"
        "authelia:认证服务"
    )

    for db_info in "${databases[@]}"; do
        IFS=':' read -r dbname description <<< "$db_info"

        if create_database "$dbname" "$description"; then
            if enable_extensions "$dbname"; then
                log_success "数据库 $dbname 初始化完成"
            else
                log_warning "数据库 $dbname 扩展启用存在问题"
            fi
        else
            log_error "数据库 $dbname 创建失败"
        fi
        echo
    done

    # 为默认数据库启用扩展
    log_info "为默认数据库 $POSTGRES_DB 启用扩展..."
    if enable_extensions "$POSTGRES_DB"; then
        log_success "默认数据库扩展启用完成"
    else
        log_warning "默认数据库扩展启用存在问题"
    fi

    # 最终总结
    log_success "多数据库初始化完成！"
    log_info "已创建的数据库："
    for db_info in "${databases[@]}"; do
        IFS=':' read -r dbname description <<< "$db_info"
        echo "  - $dbname ($description)"
    done
    echo "  - $POSTGRES_DB (默认数据库)"
}

# 执行主函数
main "$@"
