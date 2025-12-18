#!/usr/bin/env bash

#
# 数据库状态验证脚本
# 验证所有数据库及其扩展的安装状态
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

# 执行 SQL 查询并返回结果
execute_query() {
    local dbname="$1"
    local query="$2"
    local description="$3"

    log_info "$description (数据库: $dbname)"

    if ! psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$dbname" -c "$query"; then
        log_error "执行查询失败: $description (数据库: $dbname)"
        return 1
    fi
    return 0
}

# 列出所有数据库
list_databases() {
    log_info "=== 数据库列表 ==="

    local query="
        SELECT
            datname as database_name,
            datistemplate as is_template,
            datallowconn as allows_connections,
            pg_size_pretty(pg_database_size(datname)) as size
        FROM pg_database
        WHERE datistemplate = false
        ORDER BY datname;
    "

    execute_query "$POSTGRES_DB" "$query" "获取数据库列表"
}

# 验证数据库扩展状态
check_database_extensions() {
    local dbname="$1"

    log_info "检查数据库 $dbname 的扩展状态..."

    local query="
        SELECT
            extname,
            extversion
        FROM pg_extension
        ORDER BY extname;
    "

    execute_query "$dbname" "$query" "扩展状态检查"
}

# 验证 PostGIS 功能
test_postgis_functionality() {
    local dbname="$1"

    log_info "测试数据库 $dbname 的 PostGIS 功能..."

    local query="
        SELECT
            '$dbname' as database,
            ST_Area(ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')) > 0 as geometry_works,
            ST_Transform(ST_GeomFromText('POINT(0 0)', 4326), 3857) IS NOT NULL as projection_works
        FROM pg_extension
        WHERE extname = 'postgis'
        LIMIT 1;
    "

    if execute_query "$dbname" "$query" "PostGIS 功能测试"; then
        log_success "数据库 $dbname: PostGIS 功能正常"
    else
        log_warning "数据库 $dbname: PostGIS 扩展未找到或功能异常"
    fi
}

# 验证 pgvector 功能
test_pgvector_functionality() {
    local dbname="$1"

    log_info "测试数据库 $dbname 的 pgvector 功能..."

    local query="
        SELECT
            '$dbname' as database,
            ('[1,2,3]'::vector <-> '[4,5,6]'::vector) > 0 as vector_distance_works
        FROM pg_extension
        WHERE extname = 'vector'
        LIMIT 1;
    "

    if execute_query "$dbname" "$query" "pgvector 功能测试"; then
        log_success "数据库 $dbname: pgvector 功能正常"
    else
        log_warning "数据库 $dbname: pgvector 扩展未找到或功能异常"
    fi
}

# 获取数据库连接统计
get_connection_stats() {
    log_info "=== 数据库连接统计 ==="

    local query="
        SELECT
            datname,
            numbackends as active_connections,
            xact_commit as transactions_committed,
            xact_rollback as transactions_rolled_back
        FROM pg_stat_database
        WHERE datistemplate = false;
    "

    execute_query "$POSTGRES_DB" "$query" "连接统计"
}

# 验证扩展依赖关系
check_extension_dependencies() {
    log_info "=== 扩展依赖关系 ==="

    local query="
        SELECT
            e.extname as extension,
            array_agg(d.deptype) as dependency_types,
            COUNT(*) as dependency_count
        FROM pg_extension e
        LEFT JOIN pg_depend d ON e.oid = d.refobjid
        WHERE e.extname IN ('postgis', 'postgis_topology', 'postgis_raster', 'fuzzystrmatch', 'vector')
        GROUP BY e.extname
        ORDER BY e.extname;
    "

    execute_query "$POSTGRES_DB" "$query" "扩展依赖关系检查"
}

# 验证所有数据库
verify_all_databases() {
    log_info "开始验证所有数据库..."

    # 获取所有非模板数据库
    local databases_query="SELECT datname FROM pg_database WHERE datistemplate = false;"
    local databases=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -t -c "$databases_query")

    if [[ -z "$databases" ]]; then
        log_error "未找到任何数据库"
        return 1
    fi

    # 验证每个数据库
    while IFS= read -r dbname; do
        dbname=$(echo "$dbname" | xargs)  # 去除空格
        if [[ -n "$dbname" ]]; then
            log_info "--- 验证数据库: $dbname ---"

            check_database_extensions "$dbname"
            test_postgis_functionality "$dbname"
            test_pgvector_functionality "$dbname"
            echo
        fi
    done <<< "$databases"
}

# 生成验证总结
generate_summary() {
    log_info "=== 数据库验证总结 ==="

    local query="
        SELECT
            COUNT(DISTINCT datname) as total_databases,
            COUNT(DISTINCT CASE WHEN extname = 'postgis' THEN datname END) as databases_with_postgis,
            COUNT(DISTINCT CASE WHEN extname = 'vector' THEN datname END) as databases_with_vector,
            '验证完成' as status
        FROM (
            SELECT datname, extname
            FROM pg_database d
            CROSS JOIN LATERAL (
                SELECT extname
                FROM dblink('dbname=' || d.datname, 'SELECT extname FROM pg_extension') AS t(extname text)
            ) ext
            WHERE d.datistemplate = false
        ) all_extensions;
    "

    execute_query "$POSTGRES_DB" "$query" "验证总结"
}

# 主函数
main() {
    log_info "开始验证数据库状态..."

    # 检查环境变量
    if [[ -z "$POSTGRES_USER" ]] || [[ -z "$POSTGRES_DB" ]]; then
        log_error "缺少必要的环境变量: POSTGRES_USER 或 POSTGRES_DB"
        exit 1
    fi

    log_info "使用默认数据库: $POSTGRES_DB, 用户: $POSTGRES_USER"

    # 执行验证步骤
    list_databases
    echo
    verify_all_databases
    get_connection_stats
    echo
    check_extension_dependencies
    echo
    generate_summary

    log_success "数据库验证完成！"
}

# 执行主函数
main "$@"
