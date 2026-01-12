#!/usr/bin/env bash
set -euo pipefail

# 带颜色的日志函数
log_info() {
    echo -e "\033[32m[INFO] [$(date '+%H:%M:%S')] $*\033[0m" >&2
}

log_warning() {
    echo -e "\033[33m[WARNING] [$(date '+%H:%M:%S')] $*\033[0m" >&2
}

log_error() {
    echo -e "\033[31m[ERROR] [$(date '+%H:%M:%S')] $*\033[0m" >&2
}

# 确保Nginx缓存目录存在并具有正确的权限
ensure_cache_dirs() {
    local cache_dirs=(
        "/var/cache/nginx"
        "/var/cache/nginx/client_temp"
        "/var/cache/nginx/proxy_temp"
        "/var/cache/nginx/fastcgi_temp"
        "/var/cache/nginx/uwsgi_temp"
        "/var/cache/nginx/scgi_temp"
    )

    for dir in "${cache_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
        chown -R www-data:www-data "$dir"
        chmod -R 755 "$dir"
    done

    log_info "确保Nginx缓存目录权限设置完成"
}

# 初始化用户认证
init_auth() {
    if [ -f "/usr/local/bin/init-users.sh" ]; then
        log_info "初始化Nginx认证用户..."
        /usr/local/bin/init-users.sh || log_warning "用户初始化失败，继续启动"
    else
        log_warning "用户初始化脚本不存在，跳过认证初始化"
    fi
}

# 应用Nginx模板配置 (类似官方镜像的 20-envsubst-on-templates.sh)
apply_templates() {
    local template_dir="/etc/nginx/templates"
    local output_dir="/etc/nginx/sites-available"
    
    # 确保输出目录存在
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi

    if [ ! -d "$template_dir" ]; then
        log_info "模板目录 $template_dir 不存在，跳过模板处理"
        return
    fi

    local suffix=".template"
    local defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))

    # 查找并处理模板文件 (.conf 和 .template)
    find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
        local relative_path="${template#$template_dir/}"
        local output_path="$output_dir/${relative_path%$suffix}.conf"
        local subdir=$(dirname "$output_path")
        
        # 确保子目录存在
        mkdir -p "$subdir"

        log_info "正在生成配置: $relative_path -> ${output_path#$output_dir/}"
        envsubst "$defined_envs" < "$template" > "$output_path"
    done
    
    # 也处理 .conf 文件 (直接替换)
    find "$template_dir" -follow -type f -name "*.conf" -print | while read -r template; do
        local relative_path="${template#$template_dir/}"
        local output_path="$output_dir/$relative_path"
        local subdir=$(dirname "$output_path")
        
        mkdir -p "$subdir"
        
        log_info "正在生成配置: $relative_path -> ${output_path#$output_dir/}"
        envsubst "$defined_envs" < "$template" > "$output_path"
    done
}


# 初始化服务
init_services() {
    crond -l 2 -b || log_error "crond启动失败"
    ensure_cache_dirs
    init_auth
    apply_templates
    nginx -t >/dev/null 2>&1 || { log_error "nginx配置错误"; nginx -t; exit 1; }
    log_info "服务初始化完成"
}

init_services

# 测试nginx配置
test_nginx() {
    nginx -t >/dev/null 2>&1 || { log_error "nginx配置测试失败"; nginx -t; exit 1; }
    log_info "nginx配置测试通过"
}

# 主启动逻辑
test_nginx
log_info "启动nginx前台模式"
exec nginx
