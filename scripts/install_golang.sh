#!/bin/bash

set -e

# Configuration
CHINA_SOURCE="${1:-true}"
GO_VERSION="${2:-1.23.3}"
INSTALL_DIR="/usr/local"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Detect platform
detect_platform() {
    local os
    local arch

    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac

    echo "$os-$arch"
}

# Set download URL
PLATFORM=$(detect_platform)
if [[ "$CHINA_SOURCE" == "true" ]]; then
    DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/golang/go${GO_VERSION}.${PLATFORM}.tar.gz"
    info "Using Tsinghua mirror..."
else
    DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.${PLATFORM}.tar.gz"
    info "Using official source..."
fi

info "Installing Go ${GO_VERSION} for ${PLATFORM}..."

# Download and install
TEMP_FILE=$(mktemp)
info "Downloading from: $DOWNLOAD_URL"

if command -v curl >/dev/null 2>&1; then
    curl -fL -o "$TEMP_FILE" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$TEMP_FILE" "$DOWNLOAD_URL"
else
    echo "Neither curl nor wget is available"
    exit 1
fi

# Remove old installation
if [[ -d "$INSTALL_DIR/go" ]]; then
    warn "Removing existing Go installation..."
    sudo rm -rf "$INSTALL_DIR/go"
fi

# Extract and install
info "Installing to $INSTALL_DIR/go..."
sudo tar -C "$INSTALL_DIR" -xzf "$TEMP_FILE"
rm -f "$TEMP_FILE"

# Set up environment
info "Setting up environment..."
{
    echo 'export PATH="/usr/local/go/bin:$PATH"'
    echo 'export GOPATH="$HOME/go"'
    echo 'export PATH="$GOPATH/bin:$PATH"'
} >> ~/.bashrc

# For zsh users
if [[ -f ~/.zshrc ]]; then
    {
        echo 'export PATH="/usr/local/go/bin:$PATH"'
        echo 'export GOPATH="$HOME/go"'
        echo 'export PATH="$GOPATH/bin:$PATH"'
    } >> ~/.zshrc
fi

# Load environment
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Verify installation
info "Verifying installation..."
go version

info "Go installation completed!"
info "Environment variables added to shell configuration."
info ""
info "Usage: $0 [china-source] [version]"
info "  $0 true 1.23.3     # Install Go 1.23.3 with Chinese mirror (default)"
info "  $0 false 1.23.3    # Install Go 1.23.3 with official source"
info "  $0 true 1.22.0     # Install Go 1.22.0 with Chinese mirror"
