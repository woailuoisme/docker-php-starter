#!/bin/sh

set -e

# Portainer 启动脚本
# 支持通过环境变量配置管理员密码

# 默认配置
PORTAINER_ADMIN_PASSWORD_FILE="/run/secrets/portainer_password"
PORTAINER_DATA_DIR="/data"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查是否首次运行
is_first_run() {
    if [ ! -f "$PORTAINER_DATA_DIR/portainer.db" ]; then
        return 0  # 首次运行
    else
        return 1  # 非首次运行
    fi
}

# 设置管理员密码
setup_admin_password() {
    local password_file="$1"

    # 如果密码文件已存在，直接使用
    if [ -f "$password_file" ]; then
        log "INFO: 使用现有的密码文件"
        return 0
    fi

    # 检查环境变量
    if [ -n "$PORTAINER_ADMIN_PASSWORD" ]; then
        log "INFO: 从环境变量设置管理员密码"
        echo "$PORTAINER_ADMIN_PASSWORD" > "$password_file"
        chmod 600 "$password_file"
        log "INFO: 管理员密码已设置到文件: $password_file"
    else
        log "WARNING: 未设置 PORTAINER_ADMIN_PASSWORD 环境变量"
        log "WARNING: 首次访问时需要手动设置管理员密码"
        # 创建空文件，让Portainer提示设置密码
        touch "$password_file"
        chmod 600 "$password_file"
    fi
}

# 准备数据目录
prepare_data_directory() {
    if [ ! -d "$PORTAINER_DATA_DIR" ]; then
        log "INFO: 创建数据目录: $PORTAINER_DATA_DIR"
        mkdir -p "$PORTAINER_DATA_DIR"
    fi

    # 确保目录权限正确
    chown -R portainer:portainer "$PORTAINER_DATA_DIR" 2>/dev/null || true
}

# 主启动函数
main() {
    log "INFO: 启动 Portainer CE"

    # 准备数据目录
    prepare_data_directory

    # 如果是首次运行，设置管理员密码
    if is_first_run; then
        log "INFO: 检测到首次运行"
        setup_admin_password "$PORTAINER_ADMIN_PASSWORD_FILE"
    else
        log "INFO: 检测到已有数据，跳过密码设置"
    fi

    # 设置信号处理
    trap 'log "INFO: 收到终止信号，正在退出..."; exit 0' TERM INT

    # 启动 Portainer
    log "INFO: 启动 Portainer 服务"
    exec /portainer "$@"
}

# 执行主函数
main "$@"
