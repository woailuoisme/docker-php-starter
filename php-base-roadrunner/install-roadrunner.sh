#!/bin/sh
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${GREEN}RoadRunner Installer${NC}"
echo "================================"

# 检测架构（优先使用 FORCE_ARCH 环境变量）
if [ -n "$FORCE_ARCH" ]; then
    ARCH="$FORCE_ARCH"
    echo "Using forced architecture: ${ARCH}"
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
            echo "${RED}Unsupported architecture: $ARCH${NC}"
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
            echo "${RED}Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
fi

echo "Detected platform: ${YELLOW}${OS}/${ARCH}${NC}"

# 获取最新版本（如果未指定）
if [ -z "$ROADRUNNER_VERSION" ]; then
    echo "Fetching latest RoadRunner version..."
    ROADRUNNER_VERSION=$(curl -sSL https://api.github.com/repos/roadrunner-server/roadrunner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "$ROADRUNNER_VERSION" ]; then
        echo "${RED}Failed to fetch latest version${NC}"
        exit 1
    fi
fi

echo "Installing RoadRunner version: ${GREEN}${ROADRUNNER_VERSION}${NC}"

# 构建下载 URL
DOWNLOAD_URL="https://github.com/roadrunner-server/roadrunner/releases/download/v${ROADRUNNER_VERSION}/roadrunner-${ROADRUNNER_VERSION}-${OS}-${ARCH}.tar.gz"

echo "Downloading from: ${DOWNLOAD_URL}"

# 下载并安装
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

if ! curl -fL --progress-bar "$DOWNLOAD_URL" -o roadrunner.tar.gz; then
    echo "${RED}Failed to download RoadRunner${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "Extracting..."
tar -xzf roadrunner.tar.gz

echo "Installing to /usr/local/bin/rr..."
# 查找解压出来的可执行文件
RR_BINARY=$(find . -type f \( -name "rr" -o -name "roadrunner" \) | head -n 1)

if [ -z "$RR_BINARY" ]; then
    echo "${RED}RoadRunner binary not found after extraction${NC}"
    ls -laR
    exit 1
fi

echo "Found binary: $RR_BINARY"
file "$RR_BINARY" || true

mv "$RR_BINARY" /usr/local/bin/rr
chmod +x /usr/local/bin/rr

# 清理
cd /
rm -rf "$TMP_DIR"

# 验证安装
if /usr/local/bin/rr --version; then
    echo "${GREEN}✓ RoadRunner installed successfully!${NC}"
else
    echo "${RED}✗ Installation verification failed${NC}"
    exit 1
fi
