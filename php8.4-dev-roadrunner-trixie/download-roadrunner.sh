#!/bin/sh
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo "${BLUE}[INFO]${NC} $1"; }
success() { echo "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo "${RED}[ERROR]${NC} $1"; }
warning() { echo "${YELLOW}[WARNING]${NC} $1"; }

info "RoadRunner Installer"
echo "================================"

# 检测架构（优先使用 TARGETARCH 环境变量）
if [ -n "$TARGETARCH" ]; then
    info "使用 Docker BuildKit TARGETARCH: $TARGETARCH"
    case "$TARGETARCH" in
        amd64) ARCH="amd64" ;;
        arm64) ARCH="arm64" ;;
        *) error "Unsupported TARGETARCH: $TARGETARCH"; exit 1 ;;
    esac
elif [ -n "$FORCE_ARCH" ]; then
    ARCH="$FORCE_ARCH"
    info "Using forced architecture: ${ARCH}"
else
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
fi

# 检测操作系统（Docker 构建时强制使用 linux）
if [ -f "/.dockerenv" ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    OS="linux"
else
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $OS in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
fi

info "Detected platform: ${OS}/${ARCH}"

# 获取最新版本（如果未指定）
if [ -z "$ROADRUNNER_VERSION" ]; then
    info "Fetching latest RoadRunner version..."
    ROADRUNNER_VERSION=$(curl -sSL https://api.github.com/repos/roadrunner-server/roadrunner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "$ROADRUNNER_VERSION" ]; then
        error "Failed to fetch latest version"
        exit 1
    fi
fi

info "Installing RoadRunner version: ${ROADRUNNER_VERSION}"

# 多个下载源
DOWNLOAD_SOURCES="
https://github.com/roadrunner-server/roadrunner/releases/download/v${ROADRUNNER_VERSION}/roadrunner-${ROADRUNNER_VERSION}-${OS}-${ARCH}.tar.gz
https://github.com/spiral/roadrunner/releases/download/v${ROADRUNNER_VERSION}/roadrunner-${ROADRUNNER_VERSION}-${OS}-${ARCH}.tar.gz
"

# 下载并安装
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

DOWNLOADED=false
for DOWNLOAD_URL in $DOWNLOAD_SOURCES; do
    info "尝试从以下地址下载: $DOWNLOAD_URL"
    
    if curl -fL --progress-bar "$DOWNLOAD_URL" -o roadrunner.tar.gz 2>/dev/null; then
        success "成功下载自: $DOWNLOAD_URL"
        DOWNLOADED=true
        break
    else
        warning "下载失败: $DOWNLOAD_URL"
    fi
done

if [ "$DOWNLOADED" = "false" ]; then
    error "所有下载源均失败"
    rm -rf "$TMP_DIR"
    exit 1
fi

info "Extracting..."
tar -xzf roadrunner.tar.gz

info "Installing to /usr/local/bin/rr..."
# 查找解压出来的可执行文件
RR_BINARY=$(find . -type f \( -name "rr" -o -name "roadrunner" \) | head -n 1)

if [ -z "$RR_BINARY" ]; then
    error "RoadRunner binary not found after extraction"
    ls -laR
    rm -rf "$TMP_DIR"
    exit 1
fi

info "Found binary: $RR_BINARY"
file "$RR_BINARY" || true

mv "$RR_BINARY" /usr/local/bin/rr
chmod +x /usr/local/bin/rr

# 清理
cd /
rm -rf "$TMP_DIR"

# 验证安装
if /usr/local/bin/rr --version; then
    success "RoadRunner installed successfully!"
else
    error "Installation verification failed"
    exit 1
fi
