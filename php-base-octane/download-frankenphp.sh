#!/bin/bash

# FrankenPHP Binary Download Script
# Simple script to download FrankenPHP binary for current platform

set -e

# Default configuration
VERSION="${1:-1.10.1}"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="frankenphp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Detect platform
detect_platform() {
    local os
    local arch

    # Detect OS
    case "$(uname -s)" in
        Darwin) os="mac" ;;
        Linux) os="linux" ;;
        *) error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64)
            if [[ "$os" == "mac" ]]; then
                arch="arm64"
            else
                arch="aarch64"
            fi
            ;;
        *) error "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac

    echo "$os-$arch"
}

# Verify binary file
verify_binary() {
    local file="$1"

    # Check if file exists and has content
    if [[ ! -s "$file" ]]; then
        error "Downloaded file is empty or corrupted"
        return 1
    fi

    # Check if it's an ELF binary
    if ! file "$file" 2>/dev/null | grep -q "ELF"; then
        # Check if it's HTML (error page)
        if head -c 100 "$file" | grep -q "<html"; then
            error "Download returned an HTML error page instead of binary"
            return 1
        else
            warning "Downloaded file may not be a valid ELF binary"
        fi
    fi

    # Check architecture
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" || "$arch" == "amd64" ]]; then
        if ! file "$file" 2>/dev/null | grep -q "x86-64"; then
            warning "Binary architecture doesn't match system architecture"
        fi
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        if ! file "$file" 2>/dev/null | grep -q "aarch64\|ARM"; then
            warning "Binary architecture doesn't match system architecture"
        fi
    fi

    return 0
}

# Show usage
usage() {
    echo "Usage: $0 [VERSION]"
    echo ""
    echo "Download and install FrankenPHP binary."
    echo ""
    echo "Examples:"
    echo "  $0              # Download v1.10.1"
    echo "  $0 1.9.1        # Download v1.9.1"
    echo ""
    echo "Available versions: 1.10.1, 1.9.1, 1.9.0, 1.8.0, 1.7.0, 1.6.0"
}

# Main function
main() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    PLATFORM=$(detect_platform)
    TARGET_PATH="$INSTALL_DIR/$BINARY_NAME"

    # Check if platform is macOS and provide guidance
    if [[ "$PLATFORM" == mac-* ]]; then
        info "Detected macOS platform: $PLATFORM"
        info "Note: For macOS, consider using Homebrew for easier installation:"
        info "  brew install frankenphp"
        echo ""
    fi

    # Try multiple download sources
    DOWNLOAD_SOURCES=(
        "https://github.com/php/frankenphp/releases/download/v$VERSION/frankenphp-$PLATFORM"
        "https://github.com/dunglas/frankenphp/releases/download/v$VERSION/frankenphp-$PLATFORM"
        "https://sourceforge.net/projects/frankenphp.mirror/files/v$VERSION/frankenphp-$PLATFORM/download"
    )

    info "Downloading FrankenPHP v$VERSION for $PLATFORM..."
    info "To: $TARGET_PATH"

    # Check if binary exists
    if [[ -f "$TARGET_PATH" ]]; then
        read -p "Binary exists. Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Installation cancelled"
            exit 0
        fi
    fi

    # Create temp file for download
    TEMP_FILE=$(mktemp)

    # Try downloading from multiple sources
    DOWNLOAD_SUCCESS=false
    for DOWNLOAD_URL in "${DOWNLOAD_SOURCES[@]}"; do
        info "Trying source: $DOWNLOAD_URL"

        # Download binary to temp file first with progress
        info "Downloading from: $(echo "$DOWNLOAD_URL" | cut -d'/' -f1-5)..."

        if command -v curl >/dev/null 2>&1; then
            # Download with curl (no progress)
            if curl -fL -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
                DOWNLOAD_SUCCESS=true
                break
            else
                warning "Download from this source failed, trying next..."
                rm -f "$TEMP_FILE"
            fi
        elif command -v wget >/dev/null 2>&1; then
            # Download with wget (no progress)
            if wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
                DOWNLOAD_SUCCESS=true
                break
            else
                warning "Download from this source failed, trying next..."
                rm -f "$TEMP_FILE"
            fi
        else
            error "Neither curl nor wget is available"
            exit 1
        fi
    done

    if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
        error "All download sources failed for FrankenPHP v$VERSION"
        error "Please check:"
        error "  - Version $VERSION exists"
        error "  - Network connection"
        error "  - Available at: https://github.com/dunglas/frankenphp/releases"
        exit 1
    fi

    # Verify downloaded file
    info "Verifying downloaded binary..."
    if ! verify_binary "$TEMP_FILE"; then
        rm -f "$TEMP_FILE"
        error "Binary verification failed"
        exit 1
    fi

    # Make executable and move to target location
    chmod +x "$TEMP_FILE"

    # Move to final location
    if [[ -w "$INSTALL_DIR" ]]; then
        mv "$TEMP_FILE" "$TARGET_PATH"
    else
        sudo mv "$TEMP_FILE" "$TARGET_PATH"
        sudo chmod +x "$TARGET_PATH"
    fi

    # Verify installation
    if [[ -x "$TARGET_PATH" ]]; then
        success "FrankenPHP installed successfully!"
        info "Version: $($TARGET_PATH --version 2>/dev/null || echo 'Unknown')"
        echo ""
        info "Usage:"
        echo "  $BINARY_NAME --version"
        echo "  php artisan octane:install --server=frankenphp"
    else
        error "Installation failed - file is not executable"
        exit 1
    fi
}

main "$@"
