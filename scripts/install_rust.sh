#!/bin/bash

set -e

# Configuration
CHINA_SOURCE="${1:-true}"
UPDATE_ONLY="${2:-false}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Set up Rust mirrors if china-source is enabled
if [[ "$CHINA_SOURCE" == "true" ]]; then
    info "Configuring Rust mirrors..."
    export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup

    # Create Cargo config
    mkdir -p ~/.cargo
    cat > ~/.cargo/config << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOF
else
    info "Using default Rust sources..."
fi

# Check if Rust is already installed
if command -v rustup >/dev/null 2>&1 && [[ "$UPDATE_ONLY" == "true" ]]; then
    info "Updating existing Rust installation..."
    source ~/.cargo/env
    rustup update
    info "Rust update completed!"
else
    # Install Rust
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Load environment
    source ~/.cargo/env

    # Verify installation
    info "Verifying installation..."
    rustc --version
    cargo --version

    info "Rust installation completed!"
fi

info "Usage: $0 [china-source] [update-only]"
info "  $0 true false    # Install with Chinese mirrors (default)"
info "  $0 false false   # Install with default sources"
info "  $0 true true     # Update existing installation with Chinese mirrors"
info "  $0 false true    # Update existing installation with default sources"
