#!/bin/bash

# Certbot 健康检查脚本
# 只检查续签状态

set -e

# 默认域名
DOMAIN=${DOMAIN:-haoxiaoguai.xyz}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local color_code=""

    case "$level" in
        "info")
            color_code="32"  # 绿色
            ;;
        "warn")
            color_code="33"  # 黄色
            ;;
        "error")
            color_code="31"  # 红色
            ;;
        *)
            color_code="37"  # 白色
            ;;
    esac

    echo -e "\033[${color_code}m[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message\033[0m" >&2
}

# 检查续签状态
check_renewal_status() {
    local renewal_config="/etc/letsencrypt/renewal/$DOMAIN.conf"

    if [ ! -f "$renewal_config" ]; then
        log "WARNING: 续签配置文件不存在: $renewal_config"
        return 0  # 首次运行可能没有续签配置
    fi

    # 检查最后一次续签时间
    local last_renewal
    last_renewal=$(grep -oP 'last_renewal_time\s*=\s*\K\d+' "$renewal_config" 2>/dev/null || echo "0")

    if [ "$last_renewal" -gt 0 ]; then
        local current_time
        current_time=$(date +%s)
        local days_since_renewal
        days_since_renewal=$(( (current_time - last_renewal) / 86400 ))

        if [ $days_since_renewal -gt 90 ]; then
            log "warn" "距离上次续签已超过 $days_since_renewal 天"
            return 1
        else
            log "info" "距离上次续签 $days_since_renewal 天"
            return 0
        fi
    fi

    return 0
}

# 主健康检查函数
main_healthcheck() {
    log "info" "开始续签状态检查"

    # 执行续签状态检查
    if ! check_renewal_status; then
        log "error" "续签状态检查失败"
        echo "UNHEALTHY"
        return 1
    fi

    log "info" "续签状态检查通过"
    echo "HEALTHY"
    return 0
}

# 处理命令行参数
case "${1:-}" in
    "check")
        main_healthcheck
        exit $?
        ;;
    *)
        echo "用法: $0 check"
        echo "  check  - 执行续签状态检查"
        exit 1
        ;;
esac
