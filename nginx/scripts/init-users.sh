#!/bin/bash
# /usr/local/bin/init-users.sh - 简化版Nginx用户初始化脚本
CONFIG_FILE="/etc/nginx/auth/users.yml"
PASSWD_FILE="/etc/nginx/auth/.htpasswd"
LOG_FILE="/var/log/nginx/auth-init.log"

# 确保目录存在
mkdir -p "$(dirname "$PASSWD_FILE")" "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() { log "INFO: $1"; }
log_error() { log "ERROR: $1"; }
log_success() { log "SUCCESS: $1"; }

# 检查依赖
check_dependencies() {
    local missing_deps=()
    command -v htpasswd >/dev/null 2>&1 || missing_deps+=("apache2-utils")
    command -v yq >/dev/null 2>&1 || missing_deps+=("yq")

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_info "安装依赖: ${missing_deps[*]}"
        
        if command -v apk >/dev/null 2>&1; then
            # Alpine Linux
            [[ " ${missing_deps[*]} " =~ " apache2-utils " ]] && apk add --no-cache apache2-utils
            [[ " ${missing_deps[*]} " =~ " yq " ]] && apk add --no-cache yq --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
        elif command -v apt-get >/dev/null 2>&1; then
            # Ubuntu/Debian
            apt-get update
            [[ " ${missing_deps[*]} " =~ " apache2-utils " ]] && apt-get install -y apache2-utils
            [[ " ${missing_deps[*]} " =~ " yq " ]] && {
                wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64"
                chmod +x /usr/local/bin/yq
            }
        else
            log_error "不支持的包管理器，请手动安装: ${missing_deps[*]}"
            return 1
        fi
    fi
    
    log_success "依赖检查通过"
    return 0
}

# 验证配置文件
validate_config() {
    [ ! -f "$CONFIG_FILE" ] && { log_error "配置文件不存在: $CONFIG_FILE"; return 1; }
    
    # 检查YAML语法
    yq eval '.' "$CONFIG_FILE" >/dev/null 2>&1 || { log_error "配置文件YAML格式错误"; return 1; }
    
    # 检查users字段
    yq eval 'has("users")' "$CONFIG_FILE" | grep -q "true" || { log_error "配置文件缺少'users'字段"; return 1; }
    
    local user_count=$(yq eval '.users | length' "$CONFIG_FILE")
    [ "$user_count" -eq 0 ] && { log_error "用户列表为空"; return 1; }
    
    log_success "配置文件验证通过，共 $user_count 个用户"
    return 0
}

# 备份现有密码文件
backup_existing() {
    if [ -f "$PASSWD_FILE" ]; then
        local backup_file="${PASSWD_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$PASSWD_FILE" "$backup_file"
        log_info "已备份现有密码文件到: $backup_file"
        
        # 清理旧备份（保留最近5个）
        find "$(dirname "$PASSWD_FILE")" -name "$(basename "$PASSWD_FILE").backup.*" -type f | \
            sort -r | tail -n +6 | xargs -r rm -f
    fi
}

# 从配置文件初始化用户
init_users_from_config() {
    log_info "开始从配置文件初始化用户..."
    
    local user_count=$(yq eval '.users | length' "$CONFIG_FILE")
    [ -f "$PASSWD_FILE" ] && rm -f "$PASSWD_FILE"
    
    local created_count=0 failed_count=0
    
    for i in $(seq 0 $((user_count - 1))); do
        local username=$(yq eval ".users[$i].username" "$CONFIG_FILE")
        local password=$(yq eval ".users[$i].password" "$CONFIG_FILE")
        local description=$(yq eval ".users[$i].description // \"无描述\"" "$CONFIG_FILE")
        
        log_info "创建用户: $username ($description)"
        
        # 使用htpasswd创建用户
        if [ "$created_count" -eq 0 ]; then
            htpasswd -bc "$PASSWD_FILE" "$username" "$password" 2>/dev/null
        else
            htpasswd -b "$PASSWD_FILE" "$username" "$password" 2>/dev/null
        fi
        
        if [ $? -eq 0 ]; then
            log_success "用户 '$username' 创建成功"
            created_count=$((created_count + 1))
        else
            log_error "用户 '$username' 创建失败"
            failed_count=$((failed_count + 1))
        fi
    done
    
    # 设置文件权限
    [ -f "$PASSWD_FILE" ] && { chmod 644 "$PASSWD_FILE"; chown root:root "$PASSWD_FILE" 2>/dev/null || true; }
    
    log_info "用户初始化完成: 成功 $created_count 个, 失败 $failed_count 个"
    [ "$failed_count" -gt 0 ] && return 1
    return 0
}

# 显示创建的用户列表
show_created_users() {
    if [ -f "$PASSWD_FILE" ]; then
        log_info "已创建的用户列表:"
        echo "========================================" | tee -a "$LOG_FILE"
        
        local count=0
        while IFS=':' read -r username _; do
            count=$((count + 1))
            local description=$(yq eval ".users[] | select(.username == \"$username\") | .description // \"无描述\"" "$CONFIG_FILE" 2>/dev/null || echo "无描述")
            printf "%-3s %-15s %s\\n" "$count." "$username" "($description)" | tee -a "$LOG_FILE"
        done < "$PASSWD_FILE"
        
        echo "========================================" | tee -a "$LOG_FILE"
        log_info "总计: $count 个用户"
    else
        log_error "密码文件不存在"
    fi
}

# 主函数
main() {
    log_info "开始执行Nginx用户初始化"
    
    # 检查依赖
    check_dependencies || exit 1
    
    # 验证配置文件
    validate_config || exit 1
    
    # 备份现有文件
    backup_existing
    
    # 初始化用户
    init_users_from_config || { log_error "用户初始化失败"; exit 1; }
    
    # 显示结果
    show_created_users
    
    log_success "Nginx用户初始化完成"
}

# 执行主函数
main "$@"
