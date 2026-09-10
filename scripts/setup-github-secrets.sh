#!/bin/bash

# setup-github-secrets.sh
# 从 registry.ini 读取凭据，一次性确认后设置 GitHub Actions secrets

set -e

# 前置检查
command -v gh >/dev/null 2>&1 || { echo "未安装 GitHub CLI (gh)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "请先执行 gh auth login" >&2; exit 1; }

REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')

REGISTRY_FILE="registry.ini"
for path in "registry.ini" "../registry.ini" "../../registry.ini"; do
    if [ -f "$path" ]; then
        REGISTRY_FILE="$path"
        break
    fi
done
if [ ! -f "$REGISTRY_FILE" ]; then
    echo "找不到 registry.ini" >&2
    exit 1
fi

# 读取配置值（去除首尾空格，跳过注释行）
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

# 要设置的 secrets: "secret 名称:registry.ini 键"
SECRETS=(
    "DOCKER_HUB_USERNAME:DOCKERHUB_USERNAME"
    "DOCKER_HUB_TOKEN:DOCKERHUB_TOKEN"
    "TENCENT_REGISTRY_USERNAME:TENCENT_USERNAME"
    "TENCENT_REGISTRY_PASSWORD:TENCENT_PASSWORD"
    "TENCENT_REGISTRY_NAMESPACE:TENCENT_NAMESPACE"
    "QUAY_USERNAME:REDHAT_USERNAME"
    "QUAY_TOKEN:REDHAT_TOKEN"
    # 注意：GitHub 不允许 GITHUB_ 前缀，所以使用 GHCR_ 前缀
    "GHCR_USERNAME:GITHUB_USERNAME"
    "GHCR_TOKEN:GITHUB_TOKEN"
)

# 统计可设置的 secrets（跳过配置中缺失或为空的项）
to_set=()
for entry in "${SECRETS[@]}"; do
    name=${entry%%:*}
    key=${entry#*:}
    if [ -n "$(get_config_value "$key")" ]; then
        to_set+=("$name")
    fi
done

echo "仓库: $REPO"
echo "将设置 ${#to_set[@]} 个 secrets:"
printf '  - %s\n' "${to_set[@]}"
read -r -p "确认执行? (Y/n): " confirm
[[ ${confirm:-Y} =~ ^[Yy]$ ]] || { echo "已取消"; exit 1; }

# 设置 secrets
for entry in "${SECRETS[@]}"; do
    name=${entry%%:*}
    key=${entry#*:}
    value=$(get_config_value "$key")
    [ -n "$value" ] || continue
    echo "$value" | gh secret set -R "$REPO" "$name"
done

echo ""
echo "完成。当前 secrets:"
gh secret list -R "$REPO" | cat
