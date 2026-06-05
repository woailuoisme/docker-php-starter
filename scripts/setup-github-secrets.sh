#!/bin/bash

# setup-github-secrets.sh
# GitHub 机密配置脚本 - 用于 Docker 镜像构建工作流
# 作用：自动化从 registry.ini 文件读取配置并设置 GitHub Actions 工作流所需的机密信息

set -e

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

info "GitHub 机密配置脚本 - Lunchbox Docker 构建"
info "================================================"
info ""

# 检查是否安装了 GitHub CLI
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) 未安装。"
    info "请先安装: https://cli.github.com/"
    exit 1
fi

# 检查用户是否已认证
if ! gh auth status &> /dev/null; then
    error "请先使用 GitHub CLI 进行认证:"
    info "   gh auth login"
    exit 1
fi

# 获取仓库信息
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
info "仓库: $REPO_OWNER/$REPO_NAME"
info ""

# 检查 registry.ini 文件是否存在
REGISTRY_FILE="registry.ini"
for path in "registry.ini" "../registry.ini" "../../registry.ini"; do
    if [ -f "$path" ]; then
        REGISTRY_FILE="$path"
        break
    fi
done

if [ ! -f "$REGISTRY_FILE" ]; then
    error "无法找到 registry.ini 文件"
    exit 1
fi
success "找到 registry.ini 文件: $REGISTRY_FILE"

info "从 registry.ini 文件读取配置"
info "--------------------------------"

# 获取配置项值的辅助函数（使用 awk 去除首尾空格，跳过注释，保证兼容性）
get_config_value() {
    local target_key=$1
    awk -F'=' -v tk="$target_key" '
        /^[[:space:]]*;/ { next }
        {
            key = $1
            sub(/^[[:space:]]+/, "", key)
            sub(/[[:space:]]+$/, "", key)
            if (key == tk) {
                val = substr($0, index($0, "=") + 1)
                sub(/^[[:space:]]+/, "", val)
                sub(/[[:space:]]+$/, "", val)
                print val
                exit
            }
        }
    ' "$REGISTRY_FILE"
}

# 读取 registry.ini 文件并解析配置
success "成功读取以下配置项:"
awk -F'=' '
    /^[[:space:]]*$/ || /^[[:space:]]*;/ { next }
    {
        key = $1
        sub(/^[[:space:]]+/, "", key)
        sub(/[[:space:]]+$/, "", key)
        val = substr($0, index($0, "=") + 1)
        sub(/^[[:space:]]+/, "", val)
        sub(/[[:space:]]+$/, "", val)
        
        if (key ~ /(TOKEN|PASSWORD)/) {
            print "   " key ": ********"
        } else {
            print "   " key ": " val
        }
    }
' "$REGISTRY_FILE"
info ""

# 设置机密的函数（自动从配置读取）
set_secret_from_config() {
    local secret_name=$1
    local config_key=$2
    local description=$3
    local is_token=$4

    info "设置机密: $secret_name ($description)"

    # 从 registry.ini 中获取配置值
    local secret_value
    secret_value=$(get_config_value "$config_key")

    # 检查配置中是否存在该键且不为空
    if [ -z "$secret_value" ]; then
        warning "跳过 $secret_name (在 registry.ini 中未找到 $config_key 或值为空)"
        return
    fi

    # 显示值（敏感信息用星号隐藏）
    if [[ "$is_token" = "true" || "$secret_name" =~ (TOKEN|PASSWORD) ]]; then
        info "   值: ********"
    else
        info "   值: $secret_value"
    fi

    read -p "   确认设置 $secret_name? (Y/n): " confirm
    confirm=${confirm:-Y}

    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "$secret_value" | gh secret set "$secret_name"
        success "$secret_name 设置成功"
    else
        error "$secret_name 未设置"
    fi
    info ""
}

# Docker Hub 机密配置
info "Docker Hub 配置"
info "-------------------"
set_secret_from_config "DOCKERHUB_USERNAME" "DOCKERHUB_USERNAME" "Docker Hub 用户名" false
set_secret_from_config "DOCKERHUB_TOKEN" "DOCKERHUB_TOKEN" "Docker Hub 访问令牌" true

# 腾讯云机密配置
info "腾讯云配置"
info "---------------"
set_secret_from_config "TENCENT_REGISTRY_USERNAME" "TENCENT_USERNAME" "腾讯云镜像仓库用户名" false
set_secret_from_config "TENCENT_REGISTRY_PASSWORD" "TENCENT_PASSWORD" "腾讯云镜像仓库密码" true
set_secret_from_config "TENCENT_REGISTRY_NAMESPACE" "TENCENT_NAMESPACE" "腾讯云镜像仓库命名空间" false

# Red Hat Registry 机密配置
info "Red Hat Registry 配置"
info "-------------------------"
set_secret_from_config "REDHAT_REGISTRY_USERNAME" "REDHAT_USERNAME" "Red Hat Registry 用户名" false
set_secret_from_config "REDHAT_REGISTRY_TOKEN" "REDHAT_TOKEN" "Red Hat Registry 访问令牌" true

# GitHub Container Registry 配置
info "GitHub Container Registry 配置"
info "----------------------------------"
# 注意：GitHub 不允许以 GITHUB_ 开头的 secret 名称，所以使用 GHCR_ 前缀
set_secret_from_config "GITHUB_USERNAME" "GITHUB_USERNAME" "GitHub Container Registry 用户名" false
set_secret_from_config "GITHUB_TOKEN" "GITHUB_TOKEN" "GitHub Container Registry 访问令牌" true

# 可选配置
info "可选配置"
info "-----------"
read -p "配置 Slack 通知? (y/N): " slack_confirm
if [[ $slack_confirm =~ ^[Yy]$ ]]; then
    read -p "   输入 SLACK_WEBHOOK_URL 的值: " -s slack_webhook
    info ""
    if [ -n "$slack_webhook" ]; then
        read -p "   确认设置 SLACK_WEBHOOK_URL? (Y/n): " confirm_slack
        confirm_slack=${confirm_slack:-Y}
        if [[ $confirm_slack =~ ^[Yy]$ ]]; then
            echo "$slack_webhook" | gh secret set "SLACK_WEBHOOK_URL"
            success "SLACK_WEBHOOK_URL 设置成功"
        fi
    fi
    info ""
fi

info ""
success "设置完成!"
info ""
info "已配置的机密摘要:"
gh secret list

info ""
info "后续步骤:"
info "   1. 推送代码以触发工作流"
info "   2. 检查 GitHub Actions 标签页查看构建状态"
info "   3. 验证镜像是否推送到您的注册表"
info ""
info "手动测试:"
info "   - 前往 GitHub Actions → 'Build and Push Docker Images' → 'Run workflow'"
info ""
info "故障排除:"
info "   - 检查工作流日志获取详细错误信息"
info "   - 验证所有必需的机密都已设置"
info "   - 确保注册表权限正确"
info ""
info "注意:"
info "   - 所有配置值都从 registry.ini 文件自动读取"
info "   - 所有 secret 名称都与工作流文件中的引用保持一致"
info "   - 敏感信息在显示时已用星号隐藏"
