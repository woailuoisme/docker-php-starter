#!/bin/bash
# 批量更新路由配置中的证书解析器
# 将 certResolver: default 替换为使用环境变量

DYNAMIC_DIR="config/dynamic"

echo "🔄 Updating certificate resolver in all route configurations..."

# 查找所有包含 certResolver 的文件
for file in "$DYNAMIC_DIR"/*.yml; do
    if [ -f "$file" ]; then
        # 检查文件是否包含 certResolver
        if grep -q "certResolver:" "$file"; then
            echo "   📝 Updating: $(basename $file)"
            # 使用 sed 替换（macOS 兼容）
            sed -i '' 's/certResolver: default/certResolver: "{{ env \"DEFAULT_CERT_RESOLVER\" \"default\" }}"/g' "$file"
            sed -i '' 's/certResolver: letsencrypt/certResolver: "{{ env \"DEFAULT_CERT_RESOLVER\" \"letsencrypt\" }}"/g' "$file"
        fi
    fi
done

echo "✅ Certificate resolver update complete!"
echo ""
echo "Usage:"
echo "  Local:      ENV_TYPE=local docker-compose up -d"
echo "  Staging:    ENV_TYPE=staging docker-compose up -d"
echo "  Production: ENV_TYPE=production docker-compose up -d"
