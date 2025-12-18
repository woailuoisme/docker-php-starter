#!/bin/bash

# setup-github-secrets.sh
# GitHub 机密配置脚本 - 用于 Docker 镜像构建工作流
# 作用：自动化从 registry.ini 文件读取配置并设置 GitHub Actions 工作流所需的机密信息

set -e

echo "🚀 GitHub 机密配置脚本 - Lunchbox Docker 构建"
echo "================================================"
echo ""

# 检查是否安装了 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) 未安装。"
    echo "请先安装: https://cli.github.com/"
    exit 1
fi

# 检查用户是否已认证
if ! gh auth status &> /dev/null; then
    echo "❌ 请先使用 GitHub CLI 进行认证:"
    echo "   gh auth login"
    exit 1
fi

# 获取仓库信息
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
echo "📦 仓库: $REPO_OWNER/$REPO_NAME"
echo ""

# 检查 registry.ini 文件是否存在
REGISTRY_FILE="registry.ini"
if [ ! -f "$REGISTRY_FILE" ]; then
    echo "❌ registry.ini 文件不存在: $REGISTRY_FILE"
    echo "请确保 registry.ini 文件位于项目根目录"
    echo "当前目录: $(pwd)"
    echo "尝试查找 registry.ini 文件..."

    # 尝试在项目根目录查找
    if [ -f "../registry.ini" ]; then
        REGISTRY_FILE="../registry.ini"
        echo "✅ 找到 registry.ini 文件: $REGISTRY_FILE"
    elif [ -f "../../registry.ini" ]; then
        REGISTRY_FILE="../../registry.ini"
        echo "✅ 找到 registry.ini 文件: $REGISTRY_FILE"
    else
        echo "❌ 无法找到 registry.ini 文件"
        exit 1
    fi
    exit 1
fi

echo "📁 从 registry.ini 文件读取配置"
echo "--------------------------------"

# 读取 registry.ini 文件并解析配置
echo "✅ 成功读取以下配置项:"
while IFS='=' read -r key value; do
    # 跳过空行和注释行
    [[ -z "$key" || "$key" =~ ^[[:space:]]*\; ]] && continue

    # 去除前后空格
    key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 显示配置项
    if [[ "$key" =~ (TOKEN|PASSWORD) ]]; then
        echo "   $key: ********"
    else
        echo "   $key: $value"
    fi
done < "$REGISTRY_FILE"
echo ""

# 设置机密的函数（自动从配置读取）
set_secret_from_config() {
    local secret_name=$1
    local config_key=$2
    local description=$3
    local is_token=$4

    echo "🔐 设置机密: $secret_name"
    echo "   描述: $description"

    # 从 registry.ini 文件中查找配置值
    local secret_value=""
    while IFS='=' read -r key value; do
        # 跳过空行和注释行
        [[ -z "$key" || "$key" =~ ^[[:space:]]*\; ]] && continue

        # 去除前后空格
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [ "$key" = "$config_key" ]; then
            secret_value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            break
        fi
    done < "$REGISTRY_FILE"

    # 检查配置中是否存在该键
    if [ -z "$secret_value" ]; then
        echo "   ⚠️  跳过 $secret_name (在 registry.ini 中未找到 $config_key)"
        return
    fi

    if [ -z "$secret_value" ]; then
        echo "   ⚠️  跳过 $secret_name (空值)"
        return
    fi

    # 显示值（敏感信息用星号隐藏）
    if [[ "$is_token" = "true" || "$secret_name" =~ (TOKEN|PASSWORD) ]]; then
        echo "   值: ********"
    else
        echo "   值: $secret_value"
    fi

    read -p "   确认设置 $secret_name? (Y/n): " confirm
    confirm=${confirm:-Y}

    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "$secret_value" | gh secret set "$secret_name"
        echo "   ✅ $secret_name 设置成功"
    else
        echo "   ❌ $secret_name 未设置"
    fi
    echo ""
}

# Docker Hub 机密配置
echo "🐳 Docker Hub 配置"
echo "-------------------"
set_secret_from_config "DOCKERHUB_USERNAME" "DOCKERHUB_USERNAME" "Docker Hub 用户名" false
set_secret_from_config "DOCKERHUB_TOKEN" "DOCKERHUB_TOKEN" "Docker Hub 访问令牌" true

# 腾讯云机密配置
echo "☁️  腾讯云配置"
echo "---------------"
set_secret_from_config "TENCENT_REGISTRY_USERNAME" "TENCENT_USERNAME" "腾讯云镜像仓库用户名" false
set_secret_from_config "TENCENT_REGISTRY_PASSWORD" "TENCENT_PASSWORD" "腾讯云镜像仓库密码" true
set_secret_from_config "TENCENT_REGISTRY_NAMESPACE" "TENCENT_NAMESPACE" "腾讯云镜像仓库命名空间" false

# Red Hat Registry 机密配置
echo "🔴 Red Hat Registry 配置"
echo "-------------------------"
set_secret_from_config "REDHAT_REGISTRY_USERNAME" "REDHAT_USERNAME" "Red Hat Registry 用户名" false
set_secret_from_config "REDHAT_REGISTRY_TOKEN" "REDHAT_TOKEN" "Red Hat Registry 访问令牌" true

# GitHub Container Registry 配置
echo "📦 GitHub Container Registry 配置"
echo "----------------------------------"
# 注意：GitHub 不允许以 GITHUB_ 开头的 secret 名称，所以使用 GHCR_ 前缀
set_secret_from_config "GITHUB_USERNAME" "GITHUB_USERNAME" "GitHub Container Registry 用户名" false
set_secret_from_config "GITHUB_TOKEN" "GITHUB_TOKEN" "GitHub Container Registry 访问令牌" true

# 可选配置
echo "🔔 可选配置"
echo "-----------"
read -p "配置 Slack 通知? (y/N): " slack_confirm
if [[ $slack_confirm =~ ^[Yy]$ ]]; then
    read -p "   输入 SLACK_WEBHOOK_URL 的值: " -s slack_webhook
    echo ""
    if [ -n "$slack_webhook" ]; then
        read -p "   确认设置 SLACK_WEBHOOK_URL? (Y/n): " confirm_slack
        confirm_slack=${confirm_slack:-Y}
        if [[ $confirm_slack =~ ^[Yy]$ ]]; then
            echo "$slack_webhook" | gh secret set "SLACK_WEBHOOK_URL"
            echo "   ✅ SLACK_WEBHOOK_URL 设置成功"
        fi
    fi
    echo ""
fi

echo ""
echo "✅ 设置完成!"
echo ""
echo "📋 已配置的机密摘要:"
gh secret list

echo ""
echo "🚀 后续步骤:"
echo "   1. 推送代码以触发工作流"
echo "   2. 检查 GitHub Actions 标签页查看构建状态"
echo "   3. 验证镜像是否推送到您的注册表"
echo ""
echo "💡 手动测试:"
echo "   - 前往 GitHub Actions → 'Build and Push Docker Images' → 'Run workflow'"
echo ""
echo "🔧 故障排除:"
echo "   - 检查工作流日志获取详细错误信息"
echo "   - 验证所有必需的机密都已设置"
echo "   - 确保注册表权限正确"
echo ""
echo "📝 注意:"
echo "   - 所有配置值都从 registry.ini 文件自动读取"
echo "   - 所有 secret 名称都与工作流文件中的引用保持一致"
echo "   - 敏感信息在显示时已用星号隐藏"
