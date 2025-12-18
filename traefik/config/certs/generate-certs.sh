#!/bin/bash

# Traefik TLS 证书管理脚本
# 在当前目录下生成本地 mkcert 证书

set -e

# 配置
CERT_DIR="$(dirname "$0")"
LOCAL_DOMAINS=(
    "*.test.local"
    "app.local"
    "traefik.local"
    "logs.local"
    "minio.local"
    "search.local"
    "portainer.local"
    "localhost"
    "127.0.0.1"
    "::1"
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# 检查 mkcert 是否安装
check_mkcert() {
    if ! command -v mkcert >/dev/null 2>&1; then
        log_error "mkcert 未安装"
        echo "请先安装 mkcert:"
        echo "  macOS: brew install mkcert"
        echo "  Ubuntu/Debian: sudo apt install libnss3-tools && wget -O mkcert https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v*-linux-amd64 && chmod +x mkcert && sudo mv mkcert /usr/local/bin/"
        echo "  或从 https://github.com/FiloSottile/mkcert 下载"
        exit 1
    fi
}

# 安装本地 CA
install_local_ca() {
    if [ ! -f "$(mkcert -CAROOT)/rootCA.pem" ]; then
        log_info "安装本地 CA..."
        mkcert -install
        log_success "本地 CA 已安装"
    else
        log_success "本地 CA 已存在"
    fi
}

# 生成本地证书
generate_local_certificates() {
    log_info "在当前目录生成证书..."
    cd "$CERT_DIR"

    # 清理旧的证书文件
    cleanup_old_certs

    # 生成新证书
    mkcert "${LOCAL_DOMAINS[@]}"

    # 重命名证书文件
    local cert_file=$(ls | grep -E ".*\.pem$" | grep -v key | head -1)
    local key_file=$(ls | grep -E ".*-key\.pem$" | head -1)

    if [ -n "$cert_file" ] && [ -n "$key_file" ]; then
        mv "$cert_file" "localhost.crt"
        mv "$key_file" "localhost.key"
        log_success "证书文件已生成:"
        echo "   [CERT] localhost.crt"
        echo "   [KEY] localhost.key"
    else
        log_error "无法找到生成的证书文件"
        exit 1
    fi
}

# 清理旧的证书文件
cleanup_old_certs() {
    log_info "清理旧的证书文件..."
    rm -f "$CERT_DIR/ca.crt" "$CERT_DIR/ca.key" "$CERT_DIR/openssl.cnf" "$CERT_DIR/"*.pem "$CERT_DIR/localhost.crt" "$CERT_DIR/localhost.key"
    log_success "旧证书文件已清理"
}

# 显示证书信息
show_cert_info() {
    echo ""
    log_info "证书信息:"
    echo "   [CERT] 证书文件: $CERT_DIR/localhost.crt"
    echo "   [KEY] 私钥文件: $CERT_DIR/localhost.key"
    echo "   [CA] CA 根证书: $(mkcert -CAROOT)/rootCA.pem"

    if command -v openssl >/dev/null 2>&1 && [ -f "$CERT_DIR/localhost.crt" ]; then
        echo "[DOMAINS] 证书包含的域名:"
        openssl x509 -in "$CERT_DIR/localhost.crt" -noout -text | \
            grep -A1 "Subject Alternative Name" | tail -1 | \
            tr ',' '\n' | sed 's/DNS://g' | sed 's/^/   - /'
    fi
}

# 验证证书
verify_certificates() {
    log_info "验证证书..."
    if [ -f "$CERT_DIR/localhost.crt" ] && [ -f "$CERT_DIR/localhost.key" ]; then
        log_success "证书文件存在且可访问"

        # 验证证书内容
        if command -v openssl >/dev/null 2>&1; then
            openssl x509 -in "$CERT_DIR/localhost.crt" -noout -subject
        fi
    else
        log_warning "证书文件不存在"
    fi
}

# 显示使用说明
show_usage() {
    echo "Traefik 本地证书生成脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -g, --generate      生成本地证书（默认操作）"
    echo "  -c, --cleanup       清理旧的证书文件"
    echo "  -i, --info          显示证书信息"
    echo "  -v, --verify        验证证书"
    echo "  -h, --help          显示此帮助信息"
    echo ""
    echo "说明:"
    echo "  使用 mkcert 在当前目录生成本地开发证书"
    echo "  支持的域名: *.test.local, app.local, traefik.local, logs.local, minio.local, search.local, portainer.local, localhost, 127.0.0.1, ::1"
    echo ""
    echo "示例:"
    echo "  $0                    # 生成证书"
    echo "  $0 --info            # 显示证书信息"
    echo "  $0 --cleanup         # 清理证书文件"
}

# 主函数
main() {
    case "${1:-}" in
        -g|--generate|"")
            check_mkcert
            install_local_ca
            generate_local_certificates
            show_cert_info
            ;;
        -c|--cleanup)
            cleanup_old_certs
            ;;
        -i|--info)
            show_cert_info
            ;;
        -v|--verify)
            verify_certificates
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    log_success "操作完成！"
    echo "证书文件已保存在当前目录: $CERT_DIR"
}

# 运行主函数
main "$@"
