#!/bin/bash
set -e

# 检测环境
ENV_TYPE="${ENV_TYPE:-local}"

echo "🚀 Starting Traefik in ${ENV_TYPE} environment..."

# 根据环境设置证书解析器
if [ "$ENV_TYPE" = "production" ]; then
    echo "📜 Using Let's Encrypt production certificates"
    export DEFAULT_CERT_RESOLVER="letsencrypt"
    export ACME_CA_SERVER="https://acme-v02.api.letsencrypt.org/directory"
elif [ "$ENV_TYPE" = "staging" ]; then
    echo "📜 Using Let's Encrypt staging certificates"
    export DEFAULT_CERT_RESOLVER="letsencrypt"
    export ACME_CA_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
else
    echo "📜 Using local self-signed certificates"
    export DEFAULT_CERT_RESOLVER="default"
    export ACME_CA_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    
    # 检查本地证书是否存在
    if [ ! -f "/config/certs/localhost.crt" ]; then
        echo "⚠️  Local certificates not found, generating..."
        cd /config/certs
        if [ -f "./generate-certs.sh" ]; then
            bash ./generate-certs.sh
        else
            echo "❌ Certificate generation script not found!"
        fi
    fi
fi

# 确保 ACME 存储文件存在且权限正确
mkdir -p /config/acme
for file in acme.json letsencrypt.json cloudflare.json aliyun.json; do
    touch /config/acme/$file
    chmod 600 /config/acme/$file
done

echo "✅ Configuration complete"
echo "   - Cert Resolver: ${DEFAULT_CERT_RESOLVER}"
echo "   - ACME Server: ${ACME_CA_SERVER}"
echo "   - Domain: ${DOMAIN}"

# 启动 Traefik
exec traefik --configfile=/etc/traefik/traefik.yml
