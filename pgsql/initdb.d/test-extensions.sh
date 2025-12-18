#!/usr/bin/env bash

#
# PostGIS 扩展功能测试脚本
# 验证所有已安装的扩展是否正常工作
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
    local query="$1"
    local description="$2"

    log_info "$description"

    if ! psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "$query"; then
        log_error "执行查询失败: $description"
        return 1
    fi
    return 0
}

# 验证 GEOS 和 PROJ 库版本
check_geos_proj_versions() {
    log_info "1. 验证 GEOS 和 PROJ 库版本..."

    local query="
        SELECT
            'GEOS 版本' as library,
            postgis_lib_version() as version
        UNION ALL
        SELECT
            'PROJ 版本' as library,
            postgis_proj_version() as version
        UNION ALL
        SELECT
            'PostGIS 构建日期' as library,
            postgis_lib_build_date() as version;
    "

    execute_query "$query" "GEOS 和 PROJ 版本检查"
}

# 测试基础 PostGIS 功能
test_basic_geometry() {
    log_info "2. 测试基础 PostGIS 几何功能..."

    local query="
        SELECT
            '基础几何功能' as test_category,
            ST_Area(ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')) as polygon_area,
            ST_Distance(
                ST_GeomFromText('POINT(0 0)'),
                ST_GeomFromText('POINT(3 4)')
            ) as point_distance,
            ST_Intersects(
                ST_GeomFromText('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))'),
                ST_GeomFromText('POLYGON((3 3, 8 3, 8 8, 3 8, 3 3))')
            ) as polygons_intersect;
    "

    execute_query "$query" "基础几何功能测试"
}

# 测试 PostGIS Topology 功能
test_topology() {
    log_info "3. 测试 PostGIS Topology 功能..."

    # 创建拓扑
    local create_query="
        SELECT
            '拓扑功能' as test_category,
            topology.CreateTopology('test_topology', 4326) IS NOT NULL as topology_created,
            (SELECT COUNT(*) FROM topology.topology WHERE name = 'test_topology') as topology_count;
    "

    execute_query "$create_query" "拓扑创建测试"

    # 清理拓扑测试数据
    local cleanup_query="SELECT topology.DropTopology('test_topology');"
    execute_query "$cleanup_query" "拓扑清理"
}

# 测试 PostGIS Raster 功能
test_raster() {
    log_info "4. 测试 PostGIS Raster 功能..."

    local query="
        SELECT
            '栅格功能' as test_category,
            ST_MakeEmptyRaster(100, 100, 0, 0, 1, -1, 0, 0, 4326) IS NOT NULL as raster_created,
            ST_Width(ST_MakeEmptyRaster(100, 100, 0, 0, 1, -1, 0, 0, 4326)) as raster_width,
            ST_Height(ST_MakeEmptyRaster(100, 100, 0, 0, 1, -1, 0, 0, 4326)) as raster_height;
    "

    execute_query "$query" "栅格功能测试"
}

# 测试 Fuzzy String Match 功能
test_fuzzy_match() {
    log_info "5. 测试模糊字符串匹配功能..."

    local query="
        SELECT
            '模糊匹配' as test_category,
            levenshtein('hello', 'hallo') as levenshtein_distance,
            levenshtein_less_equal('hello', 'hallo', 2) as levenshtein_limited,
            difference('hello', 'hallo') as soundex_difference,
            metaphone('hello', 4) as metaphone_code;
    "

    execute_query "$query" "模糊字符串匹配测试"
}

# 测试 pgvector 功能
test_pgvector() {
    log_info "6. 测试 pgvector 向量功能..."

    local query="
        SELECT
            '向量功能' as test_category,
            '[1,2,3]'::vector as sample_vector,
            '[1,2,3]'::vector <-> '[4,5,6]'::vector as vector_distance,
            array_dims('[1,2,3]'::vector::float8[]) as vector_dimensions;
    "

    execute_query "$query" "向量功能测试"
}

# 验证所有扩展状态
check_extensions_status() {
    log_info "7. 验证所有扩展状态..."

    local query="
        SELECT
            extname,
            extversion,
            CASE
                WHEN extname = 'postgis' THEN '核心空间数据扩展'
                WHEN extname = 'postgis_topology' THEN '拓扑数据处理'
                WHEN extname = 'postgis_raster' THEN '栅格数据处理'
                WHEN extname = 'fuzzystrmatch' THEN '模糊字符串匹配'
                WHEN extname = 'vector' THEN '向量相似度搜索'
                ELSE '其他扩展'
            END as description
        FROM pg_extension
        WHERE extname IN ('postgis', 'postgis_topology', 'postgis_raster', 'fuzzystrmatch', 'vector')
        ORDER BY extname;
    "

    execute_query "$query" "扩展状态检查"
}

# 测试坐标投影功能
test_coordinate_projection() {
    log_info "8. 测试坐标投影功能..."

    local query="
        SELECT
            '坐标投影' as test_category,
            ST_Transform(ST_GeomFromText('POINT(-122.4194 37.7749)', 4326), 3857) as transformed_point,
            ST_SRID(ST_Transform(ST_GeomFromText('POINT(-122.4194 37.7749)', 4326), 3857)) as target_srid;
    "

    execute_query "$query" "坐标投影测试"
}

# 测试几何引擎功能
test_geometry_engine() {
    log_info "9. 测试几何引擎功能..."

    local query="
        SELECT
            '几何引擎' as test_category,
            ST_IsValid(ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')) as valid_geometry,
            ST_IsSimple(ST_GeomFromText('LINESTRING(0 0, 10 10)')) as simple_geometry,
            ST_Contains(
                ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'),
                ST_GeomFromText('POINT(5 5)')
            ) as contains_point;
    "

    execute_query "$query" "几何引擎测试"
}

# 测试 GEOS 和 PROJ 核心功能
test_geos_proj_core() {
    log_info "10. 测试 GEOS 和 PROJ 核心功能..."

    local query="
        SELECT
            'GEOS 几何验证' as test_category,
            CASE
                WHEN ST_IsValid(ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))')) THEN '✅ 有效几何'
                ELSE '❌ 无效几何'
            END as geometry_validation,
            CASE
                WHEN ST_IsSimple(ST_GeomFromText('LINESTRING(0 0, 10 10)')) THEN '✅ 简单几何'
                ELSE '❌ 复杂几何'
            END as geometry_simplicity
        UNION ALL
        SELECT
            'GEOS 空间关系' as test_category,
            CASE
                WHEN ST_Contains(
                    ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'),
                    ST_GeomFromText('POINT(5 5)')
                ) THEN '✅ 包含关系正确'
                ELSE '❌ 包含关系错误'
            END as spatial_relationship,
            CASE
                WHEN ST_Intersects(
                    ST_GeomFromText('POLYGON((0 0, 5 0, 5 5, 0 5, 0 0))'),
                    ST_GeomFromText('POLYGON((3 3, 8 3, 8 8, 3 8, 3 3))')
                ) THEN '✅ 相交关系正确'
                ELSE '❌ 相交关系错误'
            END as intersection_check
        UNION ALL
        SELECT
            'PROJ 坐标转换' as test_category,
            CASE
                WHEN ST_Transform(ST_GeomFromText('POINT(116.3974 39.9093)', 4326), 3857) IS NOT NULL THEN '✅ WGS84转Web墨卡托'
                ELSE '❌ 坐标转换失败'
            END as coordinate_projection,
            CASE
                WHEN ST_SRID(ST_Transform(ST_GeomFromText('POINT(116.3974 39.9093)', 4326), 3857)) = 3857 THEN '✅ 目标坐标系正确'
                ELSE '❌ 目标坐标系错误'
            END as target_srid_check;
    "

    execute_query "$query" "GEOS 和 PROJ 核心功能测试"
}

# 最终测试总结
test_summary() {
    log_info "=== 扩展功能测试总结 ==="

    local query="
        SELECT
            COUNT(*) as total_extensions,
            SUM(CASE WHEN extname IN ('postgis', 'postgis_topology', 'postgis_raster', 'fuzzystrmatch', 'vector') THEN 1 ELSE 0 END) as tested_extensions,
            '所有扩展功能测试完成' as status
        FROM pg_extension
        WHERE extname IN ('postgis', 'postgis_topology', 'postgis_raster', 'fuzzystrmatch', 'vector');
    "

    execute_query "$query" "测试总结"
}

# 主函数
main() {
    log_info "开始测试 PostGIS 扩展功能..."

    # 检查环境变量
    if [[ -z "$POSTGRES_USER" ]] || [[ -z "$POSTGRES_DB" ]]; then
        log_error "缺少必要的环境变量: POSTGRES_USER 或 POSTGRES_DB"
        exit 1
    fi

    log_info "使用数据库: $POSTGRES_DB, 用户: $POSTGRES_USER"

    # 执行所有测试
    check_geos_proj_versions
    test_basic_geometry
    test_topology
    test_raster
    test_fuzzy_match
    test_pgvector
    check_extensions_status
    test_coordinate_projection
    test_geometry_engine
    test_geos_proj_core
    test_summary

    log_success "PostGIS 扩展功能测试完成！"
}

# 执行主函数
main "$@"
