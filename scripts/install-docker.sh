#!/bin/bash

# 跨平台Docker安装脚本 - 支持Ubuntu和CentOS，使用阿里云镜像
set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限或sudo运行此脚本"
        exit 1
    fi
}

# 检查Docker是否已安装
check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3-)
        log_success "Docker已安装: $DOCKER_VERSION"
        return 0
    else
        log_info "Docker未安装"
        return 1
    fi
}

# 检查Docker Compose是否已安装
check_docker_compose_installed() {
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null | head -n1)
        log_success "Docker Compose已安装: $DOCKER_COMPOSE_VERSION"
        return 0
    else
        log_info "Docker Compose未安装"
        return 1
    fi
}

# Ubuntu系统安装Docker
install_docker_ubuntu() {
    log_info "在Ubuntu上安装Docker..."

    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

    mkdir -p /etc/apt/keyrings
    curl -fsSL http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# CentOS系统安装Docker
install_docker_centos() {
    log_info "在CentOS上安装Docker..."

    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# 配置Docker服务
configure_docker() {
    log_info "启动和配置Docker服务..."

    systemctl start docker
    systemctl enable docker

    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m"},
  "storage-driver": "overlay2"
}
EOF

    systemctl daemon-reload
    systemctl restart docker
}

# 测试安装
test_installation() {
    log_info "测试Docker安装..."
    docker --version
    log_info "测试Docker Compose安装..."
    docker compose version
}

# 添加用户到docker组
setup_user_permissions() {
    if [ -n "$SUDO_USER" ]; then
        log_info "添加用户 $SUDO_USER 到docker组..."
        usermod -aG docker "$SUDO_USER"
        log_warning "用户 $SUDO_USER 已添加到docker组"
        log_warning "请重新登录或运行: newgrp docker"
    fi
}

# 主安装函数
main() {
    log_info "开始检查Docker安装状态..."

    check_root
    detect_os
    log_info "检测到系统: $OS $VERSION"

    # 检查是否已安装
    if check_docker_installed && check_docker_compose_installed; then
        log_success "Docker和Docker Compose均已安装，跳过安装"
        echo ""
        log_info "当前版本:"
        docker --version
        docker compose version
        exit 0
    fi

    # 只安装Docker Compose
    if check_docker_installed && ! check_docker_compose_installed; then
        log_warning "Docker已安装但Docker Compose缺失，仅安装Docker Compose..."

        case $OS in
            ubuntu)
                apt-get update && apt-get install -y docker-compose-plugin
                ;;
            centos|rhel|rocky|almalinux)
                yum install -y docker-compose-plugin
                ;;
        esac

        log_success "Docker Compose安装成功"
        docker compose version
        exit 0
    fi

    # 完整安装
    log_info "开始完整Docker安装..."

    case $OS in
        ubuntu) install_docker_ubuntu ;;
        centos|rhel|rocky|almalinux) install_docker_centos ;;
        *)
            log_error "不支持的操作系统: $OS"
            log_info "支持的系统: Ubuntu, CentOS, RHEL, Rocky Linux, AlmaLinux"
            exit 1
            ;;
    esac

    configure_docker
    test_installation
    setup_user_permissions

    echo ""
    log_success "Docker安装完成! 🎉"
    echo ""
    log_info "使用示例:"
    echo "  docker ps                          # 查看运行中的容器"
    echo "  docker compose up -d               # 后台启动服务"
    echo "  docker compose down                # 停止服务"
    echo "  docker compose logs [service]      # 查看服务日志"
    echo ""
    log_warning "如果被添加到docker组，请重新登录或运行: newgrp docker"
}

# 运行主函数
main "$@"
