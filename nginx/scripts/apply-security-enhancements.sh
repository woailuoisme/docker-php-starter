#!/bin/bash

# Nginx 安全配置增强部署脚本
# 用于快速应用推荐的安全增强配置
# 使用方法: ./apply-security-enhancements.sh [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件路径
NGINX_CONF="/etc/nginx/nginx.conf"
SNIPPETS_DIR="/etc/nginx/snippets"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# 检查是否在 Docker 容器中运行
check_environment() {
    if [ -f /.dockerenv ]; then
        print_info "检测到 Docker 环境"
        NGINX_CONF="./nginx.conf"
        SNIPPETS_DIR="./snippets"
    else
        print_info "检测到主机环境"
    fi
}

# 备份配置文件
backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="./backups/${timestamp}"

    print_info "备份当前配置到: ${backup_dir}"
    mkdir -p "${backup_dir}"

    if [ -f "${NGINX_CONF}" ]; then
        cp "${NGINX_CONF}" "${backup_dir}/"
        print_success "已备份 nginx.conf"
    fi

    if [ -d "${SNIPPETS_DIR}" ]; then
        cp -r "${SNIPPETS_DIR}" "${backup_dir}/"
        print_success "已备份 snippets 目录"
    fi

    echo "${backup_dir}" > .last_backup
}

# 检查配置文件语法
check_nginx_syntax() {
    print_info "检查 Nginx 配置语法..."

    if command -v docker &> /dev/null; then
        if docker compose exec -T nginx nginx -t 2>&1 | grep -q "successful"; then
            print_success "配置语法检查通过"
            return 0
        else
            print_error "配置语法检查失败"
            return 1
        fi
    else
        print_warning "未检测到 Docker，跳过语法检查"
        return 0
    fi
}

# 应用请求安全增强配置
apply_request_security() {
    print_header "应用请求安全增强配置"

    # 检查文件是否存在
    if [ ! -f "${SNIPPETS_DIR}/security-requests.conf" ]; then
        print_warning "security-requests.conf 不存在，跳过"
        return
    fi

    # 检查是否已经引入
    if grep -q "security-requests.conf" "${NGINX_CONF}"; then
        print_info "请求安全配置已引入，跳过"
        return
    fi

    print_info "在 nginx.conf HTTP 块中添加请求安全配置..."

    # 这里只提示用户手动添加，因为自动修改可能有风险
    print_warning "请手动在 nginx.conf 的 http 块中添加以下行："
    echo -e "${YELLOW}include /etc/nginx/snippets/security-requests.conf;${NC}"
}

# 应用 SSL 增强配置
apply_ssl_enhancements() {
    print_header "应用 SSL 增强配置"

    if [ ! -f "${SNIPPETS_DIR}/ssl-enhanced.conf" ]; then
        print_warning "ssl-enhanced.conf 不存在，跳过"
        return
    fi

    print_info "SSL 增强配置已创建"
    print_warning "需要在每个 HTTPS server 块中引入:"
    echo -e "${YELLOW}include /etc/nginx/snippets/ssl-enhanced.conf;${NC}"

    # 检查是否需要生成 DH 参数
    if [ ! -f "/etc/nginx/ssl/dhparam.pem" ] && [ ! -f "./ssl/dhparam.pem" ]; then
        print_warning "未找到 DH 参数文件"
        echo -e "建议生成 DH 参数文件（可能需要几分钟）:"
        echo -e "${YELLOW}openssl dhparam -out ssl/dhparam.pem 4096${NC}"
    fi
}

# 应用连接限制
apply_connection_limits() {
    print_header "应用连接数限制"

    print_info "连接限制已在 security-requests.conf 中配置"
    print_info "需要在 server 块中应用:"
    echo -e "${YELLOW}limit_conn perip 10;${NC}"
    echo -e "${YELLOW}limit_conn perserver 100;${NC}"
}

# 生成测试脚本
generate_test_script() {
    print_header "生成测试脚本"

    local test_file="./test-security-enhancements.sh"

    cat > "${test_file}" << 'EOF'
#!/bin/bash

# 安全增强配置测试脚本
# 用于验证新配置是否正常工作

DOMAIN="${1:-http://localhost}"

echo "测试目标: ${DOMAIN}"
echo "======================================"

# 测试 1: 正常请求
echo -n "1. 正常请求: "
code=$(curl -s -o /dev/null -w "%{http_code}" "${DOMAIN}/")
if [ "$code" -eq 200 ] || [ "$code" -eq 404 ]; then
    echo "✓ 通过 ($code)"
else
    echo "✗ 失败 ($code)"
fi

# 测试 2: 连接数限制
echo -n "2. 连接数限制: "
for i in {1..15}; do
    curl -s -o /dev/null "${DOMAIN}/" &
done
wait
echo "✓ 已发送 15 个并发请求"

# 测试 3: SSL 配置（如果是 HTTPS）
if [[ "${DOMAIN}" == https* ]]; then
    echo -n "3. SSL 配置: "
    if command -v openssl &> /dev/null; then
        if echo | openssl s_client -connect ${DOMAIN#https://}:443 2>/dev/null | grep -q "TLSv1.3"; then
            echo "✓ TLS 1.3 支持"
        elif echo | openssl s_client -connect ${DOMAIN#https://}:443 2>/dev/null | grep -q "TLSv1.2"; then
            echo "✓ TLS 1.2 支持"
        else
            echo "✗ SSL 配置可能有问题"
        fi
    else
        echo "⊘ 未安装 openssl，跳过"
    fi
fi

# 测试 4: 安全响应头
echo "4. 安全响应头:"
curl -sI "${DOMAIN}/" | grep -E "(Strict-Transport|X-Frame|X-Content|X-XSS)" | while read line; do
    echo "   ✓ $line"
done

echo "======================================"
echo "测试完成"
EOF

    chmod +x "${test_file}"
    print_success "已生成测试脚本: ${test_file}"
}

# 生成部署报告
generate_report() {
    print_header "部署报告"

    local report_file="./security-enhancements-report.txt"

    cat > "${report_file}" << EOF
Nginx 安全配置增强部署报告
生成时间: $(date)
========================================

已部署的安全配置:
-----------------
✓ 恶意请求防护 (security-checks.conf)
✓ 敏感文件保护 (security-filters.conf)
✓ 安全响应头 (security-headers.conf)
✓ 限流配置 (nginx.conf)
✓ SSL/TLS 基础配置 (ssl.conf)
✓ 错误页面配置 (error-pages-*.conf)

推荐的增强配置:
-----------------
○ 请求安全增强 (security-requests.conf)
  - 缓冲区溢出防护
  - 请求超时控制
  - 连接数限制

○ SSL 增强配置 (ssl-enhanced.conf)
  - SSL Session 优化
  - OCSP Stapling
  - DH 参数

待办事项:
---------
1. 在 nginx.conf HTTP 块中引入 security-requests.conf
2. 在 HTTPS server 块中引入 ssl-enhanced.conf
3. 在 server 块中应用连接限制 (limit_conn)
4. 生成 DH 参数文件（可选）
5. 配置 OCSP stapling（需要证书链）
6. 运行测试脚本验证配置

下一步操作:
-----------
1. 备份文件位置: $(cat .last_backup 2>/dev/null || echo "无")
2. 运行测试: ./test-security-enhancements.sh https://your-domain.com
3. 检查语法: docker compose exec nginx nginx -t
4. 重载配置: docker compose exec nginx nginx -s reload
5. 监控日志: docker compose logs -f nginx

文档参考:
---------
- 完整安全清单: ./SECURITY-CHECKLIST.md
- 安全配置详解: ./SECURITY-CONFIG.md
- 快速部署指南: ./QUICK-START.md

========================================
EOF

    print_success "已生成部署报告: ${report_file}"
    echo ""
    cat "${report_file}"
}

# 显示帮助信息
show_help() {
    cat << EOF
Nginx 安全配置增强部署脚本

使用方法:
  $0 [选项]

选项:
  -h, --help              显示此帮助信息
  -b, --backup            仅备份当前配置
  -t, --test              生成测试脚本
  -r, --report            生成部署报告
  -a, --all               执行完整部署流程（推荐）

示例:
  $0 --all                执行完整部署
  $0 --backup             仅备份配置
  $0 --test               生成测试脚本

注意事项:
  1. 运行前请确保已经备份配置
  2. 建议先在测试环境验证
  3. 部分配置需要手动应用
  4. 检查配置语法后再重载 Nginx

更多信息请查看: ./SECURITY-CHECKLIST.md
EOF
}

# 主函数
main() {
    print_header "Nginx 安全配置增强部署工具"

    check_environment

    # 解析命令行参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--backup)
            backup_config
            exit 0
            ;;
        -t|--test)
            generate_test_script
            exit 0
            ;;
        -r|--report)
            generate_report
            exit 0
            ;;
        -a|--all)
            print_info "执行完整部署流程..."
            ;;
        "")
            print_info "使用默认部署流程..."
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac

    # 执行部署流程
    backup_config
    apply_request_security
    apply_ssl_enhancements
    apply_connection_limits
    generate_test_script
    generate_report

    print_header "部署完成"
    print_info "下一步操作:"
    echo "  1. 检查配置: docker compose exec nginx nginx -t"
    echo "  2. 重载配置: docker compose exec nginx nginx -s reload"
    echo "  3. 运行测试: ./test-security-enhancements.sh"
    echo ""
    print_warning "请仔细查看部署报告和文档，手动应用必要的配置"
}

# 执行主函数
main "$@"
