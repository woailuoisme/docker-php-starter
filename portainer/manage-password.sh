#!/bin/bash

# Portainer 密码管理脚本
# 简化版本 - 用于生成和管理 Portainer 管理员密码

set -e

# 配置
PASSWORD_FILE="secrets/portainer_password"
DEFAULT_PASSWORD="ChangeMe123!"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助
show_help() {
    echo "Portainer 密码管理脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  generate [密码]  生成新的密码文件"
    echo "  show             显示密码文件状态"
    echo "  validate         验证密码文件"
    echo "  help             显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 generate"
    echo "  $0 generate MyPassword123!"
    echo "  $0 show"
    echo "  $0 validate"
}

# 生成密码文件
generate_password() {
    local password="${1:-$DEFAULT_PASSWORD}"
    local password_dir=$(dirname "$PASSWORD_FILE")

    # 创建目录
    mkdir -p "$password_dir"

    # 生成密码文件
    echo "$password" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"

    log "密码文件已生成: $PASSWORD_FILE"
    log "密码长度: ${#password} 字符"

    # 密码强度提示
    if [ "${#password}" -lt 8 ]; then
        warn "建议使用至少8位字符的密码"
    fi
}

# 显示密码状态
show_password() {
    if [ ! -f "$PASSWORD_FILE" ]; then
        error "密码文件不存在: $PASSWORD_FILE"
        echo "运行 '$0 generate' 创建密码文件"
        exit 1
    fi

    local file_size=$(wc -c < "$PASSWORD_FILE")
    local file_perms=$(stat -c "%a" "$PASSWORD_FILE" 2>/dev/null || echo "unknown")

    log "密码文件信息:"
    echo "  位置: $PASSWORD_FILE"
    echo "  大小: $file_size 字节"
    echo "  权限: $file_perms"

    if [ -s "$PASSWORD_FILE" ]; then
        echo "  状态: 已设置密码"
    else
        echo "  状态: 空文件"
    fi
}

# 验证密码文件
validate_password() {
    if [ ! -f "$PASSWORD_FILE" ]; then
        error "密码文件不存在: $PASSWORD_FILE"
        exit 1
    fi

    local password=$(cat "$PASSWORD_FILE")

    # 检查文件是否为空
    if [ -z "$password" ]; then
        error "密码文件为空"
        exit 1
    fi

    # 检查文件权限
    local perms=$(stat -c "%a" "$PASSWORD_FILE" 2>/dev/null)
    if [ "$perms" != "600" ]; then
        warn "密码文件权限不安全 (当前: $perms，建议: 600)"
    else
        log "密码文件权限正确"
    fi

    log "密码验证通过"
    log "密码长度: ${#password} 字符"

    if [ "${#password}" -lt 8 ]; then
        warn "密码长度不足，建议使用至少8位字符"
    fi

    echo "✅ 密码文件验证通过"
}

# 主函数
main() {
    local command="${1:-help}"

    case "$command" in
        "generate")
            generate_password "$2"
            ;;
        "show")
            show_password
            ;;
        "validate")
            validate_password
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
