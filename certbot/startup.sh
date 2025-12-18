#!/bin/sh

# 设置错误处理
set -e

# 环境变量默认值
DNS_PROVIDER=${DNS_PROVIDER:-cloudflare}
DOMAIN=${DOMAIN:-example.com}
EMAIL=${EMAIL:-admin@example.com}
RENEW_INTERVAL=${RENEW_INTERVAL:-43200}  # 12小时

# Cloudflare 环境变量
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-}
CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY:-}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL:-}

# 阿里云环境变量
ALIYUN_ACCESS_KEY_ID=${ALIYUN_ACCESS_KEY_ID:-}
ALIYUN_ACCESS_KEY_SECRET=${ALIYUN_ACCESS_KEY_SECRET:-}

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 验证必要的环境变量
validate_config() {
    case $DNS_PROVIDER in
        "cloudflare")
            # 检查 Cloudflare 凭据
            if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
                log "使用 Cloudflare API Token 进行认证"
            elif [ -n "$CLOUDFLARE_API_KEY" ] && [ -n "$CLOUDFLARE_EMAIL" ]; then
                log "使用 Cloudflare API Key 和 Email 进行认证"
            else
                log "错误: 缺少 Cloudflare 凭据，请设置 CLOUDFLARE_API_TOKEN 或 CLOUDFLARE_API_KEY 和 CLOUDFLARE_EMAIL"
                exit 1
            fi
            ;;
        "aliyun")
            # 检查阿里云凭据
            if [ -z "$ALIYUN_ACCESS_KEY_ID" ] || [ -z "$ALIYUN_ACCESS_KEY_SECRET" ]; then
                log "错误: 缺少阿里云凭据，请设置 ALIYUN_ACCESS_KEY_ID 和 ALIYUN_ACCESS_KEY_SECRET"
                exit 1
            fi
            ;;
        *)
            log "错误: 不支持的 DNS 提供商: $DNS_PROVIDER (支持: cloudflare, aliyun)"
            exit 1
            ;;
    esac
}

# 创建临时凭据文件
create_credentials_file() {
    case $DNS_PROVIDER in
        "cloudflare")
            if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
                # 使用 API Token
                echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > /tmp/cloudflare.ini
            else
                # 使用 API Key + Email
                echo "dns_cloudflare_email = $CLOUDFLARE_EMAIL" > /tmp/cloudflare.ini
                echo "dns_cloudflare_api_key = $CLOUDFLARE_API_KEY" >> /tmp/cloudflare.ini
            fi
            chmod 600 /tmp/cloudflare.ini
            ;;
        "aliyun")
            # 创建阿里云凭据文件
            echo "dns_aliyun_access_key = $ALIYUN_ACCESS_KEY_ID" > /tmp/aliyun.ini
            echo "dns_aliyun_access_key_secret = $ALIYUN_ACCESS_KEY_SECRET" >> /tmp/aliyun.ini
            chmod 600 /tmp/aliyun.ini
            ;;
    esac
}

# 获取证书函数
obtain_certificate() {
    log "开始为域名 $DOMAIN 申请证书，使用 $DNS_PROVIDER DNS 验证"

    # 创建临时凭据文件
    create_credentials_file

    case $DNS_PROVIDER in
        "cloudflare")
            certbot certonly \
                --non-interactive \
                --authenticator dns-cloudflare \
                --dns-cloudflare-credentials /tmp/cloudflare.ini \
                --dns-cloudflare-propagation-seconds 60 \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --expand \
                --domains "$DOMAIN" \
                --domains "*.$DOMAIN"
            ;;
        "aliyun")
            certbot certonly \
                --non-interactive \
                --authenticator dns-aliyun \
                --dns-aliyun-credentials /tmp/aliyun.ini \
                --dns-aliyun-propagation-seconds 60 \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --expand \
                --domains "$DOMAIN" \
                --domains "*.$DOMAIN"
            ;;
    esac

    # 清理临时凭据文件
    rm -f /tmp/cloudflare.ini /tmp/aliyun.ini

    if [ $? -eq 0 ]; then
        log "证书申请成功"
    else
        log "证书申请失败"
        exit 1
    fi
}

# 续签证书函数
renew_certificates() {
    log "检查证书续签"

    # 创建临时凭据文件用于续签
    create_credentials_file

    # 使用 --quiet 进行静默续签检查
    certbot renew --quiet

    # 清理临时凭据文件
    rm -f /tmp/cloudflare.ini /tmp/aliyun.ini

    if [ $? -eq 0 ]; then
        log "证书续签检查完成"
    else
        log "证书续签失败"
    fi
}

# 主函数
main() {
    log "Certbot 容器启动，DNS 提供商: $DNS_PROVIDER，域名: $DOMAIN"

    # 验证配置
    validate_config

    # 检查是否已有证书
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log "发现已存在的证书，跳过初始申请"
    else
        # 首次申请证书
        obtain_certificate
    fi

    # 设置信号处理
    trap 'log "收到终止信号，正在退出..."; exit 0' TERM INT

    # 进入续签循环
    log "开始证书自动续签循环，检查间隔: ${RENEW_INTERVAL}秒"

    while true; do
        sleep "$RENEW_INTERVAL" &
        wait $!

        renew_certificates
    done
}

# 调用主函数
main "$@"
