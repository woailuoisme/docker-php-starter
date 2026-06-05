#!/bin/bash

# rsync 同步脚本 - 同步 SSL 证书配置文件到远程服务器
# 用途: 同步 aliyun.ini 和 cloudflare.ini 到服务器 Graves/certbot/conf 目录
#       同步 ssh 文件夹到服务器的 /var/docker/lunchbox/ssh 目录
# 注意: 使用 -a 参数会保留文件权限、时间戳、所有者 and 组信息

# 从 .env 获取配置的辅助函数
get_env_value() {
    local key=$1
    local default=$2
    local val
    if [ -f "../.env" ]; then
        val=$(awk -F'=' -v k="$key" '$1 == k { gsub(/\r/, ""); print $2; exit }' ../.env)
    fi
    echo "${val:-$default}"
}

# 配置变量
REMOTE_USER=$(get_env_value "REMOTE_USER" "root")                 # 远程服务器用户名
REMOTE_HOST=$(get_env_value "REMOTE_HOST" "8.155.171.54")         # 远程服务器地址
REMOTE_PATH=$(get_env_value "DOCKER_PATH" "/var/docker/lunchbox") # 远程服务器目标路径
LOCAL_PATH="./"                                                   # 本地文件路径

# 要同步的文件列表
#FILES_TO_SYNC=("aliyun.ini" "cloudflare.ini")
FILES_TO_SYNC=("aliyun.ini")
SSH_FOLDER="ssh"

# 颜色常量定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 统一的输出辅助函数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查本地文件是否存在
check_local_files() {
    local missing_files=()

    for file in "${FILES_TO_SYNC[@]}"; do
        if [[ ! -f "${LOCAL_PATH}${file}" ]]; then
            missing_files+=("$file")
        fi
    done

    # 检查 SSH 文件夹是否存在
    if [[ ! -d "${LOCAL_PATH}${SSH_FOLDER}" ]]; then
        warning "SSH 文件夹 ${SSH_FOLDER} 不存在，将跳过 SSH 文件夹同步"
        SYNC_SSH=false
    else
        SYNC_SSH=true
    fi

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        error "以下文件在本地不存在: ${missing_files[*]}"
        return 1
    fi

    return 0
}

# 统一的 rsync 执行函数（支持 Dry-Run 模式）
run_rsync() {
    local src=$1
    local dest=$2
    if [[ "$DRY_RUN" == "true" ]]; then
        info "  [DRY-RUN] rsync $src -> ${REMOTE_USER}@${REMOTE_HOST}:${dest}"
        return 0
    fi
    rsync -avz --progress -e "ssh -o StrictHostKeyChecking=no" "$src" "${REMOTE_USER}@${REMOTE_HOST}:${dest}"
}

# 执行 rsync 同步
sync_files() {
    local file_count=0

    for file in "${FILES_TO_SYNC[@]}"; do
        info "正在同步文件: $file"

        if run_rsync "${LOCAL_PATH}${file}" "${REMOTE_PATH}/certbot/conf/"; then
            success "文件 $file 同步成功"
            ((file_count++))
        else
            error "文件 $file 同步失败"
            return 1
        fi
    done

    success "所有文件同步完成 ($file_count/${#FILES_TO_SYNC[@]})"

    # 同步 SSH 文件夹
    if [[ "$SYNC_SSH" == "true" ]]; then
        info "正在同步 SSH 文件夹: $SSH_FOLDER"

        if run_rsync "${LOCAL_PATH}${SSH_FOLDER}/" "${REMOTE_PATH}/${SSH_FOLDER}/"; then
            success "SSH 文件夹同步成功"
        else
            error "SSH 文件夹同步失败"
            return 1
        fi
    fi

    return 0
}

# 显示使用说明
show_usage() {
    info "使用方法: $0 [选项]"
    info ""
    info "选项:"
    info "  -h, --help          显示此帮助信息"
    info "  -u, --user USER     指定远程用户名 (默认: $REMOTE_USER)"
    info "  -H, --host HOST     指定远程主机地址 (默认: $REMOTE_HOST)"
    info "  -p, --path PATH     指定远程路径 (默认: $REMOTE_PATH)"
    info "  -l, --local PATH    指定本地路径 (默认: $LOCAL_PATH)"
    info "  -d, --dry-run       模拟运行，不实际同步文件"
    info ""
    info "示例:"
    info "  $0 -u deploy -H example.com -p /opt/lunchbox"
    info "  $0 --dry-run"
    info ""
    info "权限保留说明:"
    info "  - 使用 -a 参数会保留文件权限、时间戳、所有者和组信息"
    info "  - SSH 密钥文件的 600 权限会被正确保留"
    info "  - 配置文件的不同权限设置会被正确同步"
}

# 处理命令行参数
handle_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h | --help)
                show_usage
                exit 0
                ;;
            -u | --user)
                REMOTE_USER="$2"
                shift 2
                ;;
            -H | --host)
                REMOTE_HOST="$2"
                shift 2
                ;;
            -p | --path)
                REMOTE_PATH="$2"
                shift 2
                ;;
            -l | --local)
                LOCAL_PATH="$2"
                shift 2
                ;;
            -d | --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    info "开始 SSL 证书配置文件同步"
    info "远程服务器: ${REMOTE_USER}@${REMOTE_HOST}"
    info "目标路径: ${REMOTE_PATH}/certbot/conf"

    # 检查本地文件
    if ! check_local_files; then
        exit 1
    fi

    # 显示要同步的文件列表
    info "要同步的文件: ${FILES_TO_SYNC[*]}"
    if [[ "$SYNC_SSH" == "true" ]]; then
        info "要同步的文件夹: $SSH_FOLDER"
    fi

    # 如果是模拟运行，先输出警告信息
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "模拟运行模式 - 不会实际同步文件"
        info "将模拟执行以下同步操作:"
    fi

    # 执行同步（在 run_rsync 中自动处理 DRY_RUN）
    if sync_files; then
        if [[ "$DRY_RUN" == "true" ]]; then
            success "模拟同步操作展示完毕"
        elif [[ "$SYNC_SSH" == "true" ]]; then
            success "所有 SSL 证书配置文件和 SSH 文件夹已成功同步到远程服务器"
        else
            success "所有 SSL 证书配置文件已成功同步到远程服务器"
        fi
    else
        error "同步过程中出现错误"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    handle_arguments "$@"
    main
fi
