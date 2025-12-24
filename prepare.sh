#!/bin/bash

# ==============================================================================
# Haven Start9 Package - Build Environment Preparation Script
# ==============================================================================

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

# ==============================================================================
# Check System Requirements
# ==============================================================================

check_system() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
        log_warn "Unsupported OS: $OSTYPE"
        log_warn "This script is tested on Linux and macOS only"
    fi
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root"
        exit 1
    fi
    
    log_info "System check passed"
}

# ==============================================================================
# Install Dependencies
# ==============================================================================

install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Check for package manager
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v brew &> /dev/null; then
        PKG_MANAGER="brew"
    else
        log_warn "No supported package manager found"
        log_warn "Please install dependencies manually"
        return
    fi
    
    log_info "Package manager: $PKG_MANAGER"
}

# ==============================================================================
# Install Start9 SDK
# ==============================================================================

install_start9_sdk() {
    log_info "Checking Start9 SDK..."
    
    if command -v start-sdk &> /dev/null; then
        SDK_VERSION=$(start-sdk --version 2>&1 | head -n1 || echo "unknown")
        log_info "Start9 SDK is already installed: $SDK_VERSION"
        return 0
    fi
    
    log_warn "Start9 SDK not found"
    log_info "Installing Start9 SDK..."
    
    # Download and install SDK
    if curl -sSL https://get.start9.com/sdk | bash 2>&1; then
        log_info "Start9 SDK installed successfully"
        return 0
    else
        log_warn "Failed to install Start9 SDK automatically"
        log_warn "SDK is only needed for final packaging (.s9pk creation)"
        log_warn "You can still build and test Docker images without it"
        log_warn ""
        log_warn "To install manually later, visit: https://docs.start9.com"
        return 0  # Continue anyway
    fi
}

# ==============================================================================
# Install Docker Buildx
# ==============================================================================

install_docker_buildx() {
    log_info "Checking Docker..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        log_error "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | tr -d ',')
    log_info "Docker version: $DOCKER_VERSION"
    
    log_info "Checking Docker Buildx..."
    
    if docker buildx version &> /dev/null; then
        BUILDX_VERSION=$(docker buildx version | cut -d ' ' -f2)
        log_info "Docker Buildx is available: $BUILDX_VERSION"
    else
        log_info "Docker Buildx not available (optional)"
    fi
    
    # Using Docker's native Rosetta emulation on Apple Silicon
    log_info "Using native Docker emulation for cross-platform builds..."
    
    log_info "Docker Buildx setup complete"
}

# ==============================================================================
# Install yq (YAML processor)
# ==============================================================================

install_yq() {
    log_info "Checking yq (YAML processor)..."
    
    if command -v yq &> /dev/null; then
        YQ_VERSION=$(yq --version 2>&1 | head -n1 || echo "unknown")
        log_info "yq is already installed: $YQ_VERSION"
        return
    fi
    
    log_info "Installing yq..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            YQ_ARCH="amd64"
            ;;
        aarch64|arm64)
            YQ_ARCH="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    # Download yq
    YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_${OS}_${YQ_ARCH}"
    
    log_debug "Downloading from: $YQ_URL"
    
    if command -v sudo &> /dev/null && [ -w /usr/local/bin ]; then
        # Try without sudo first
        if wget -qO /usr/local/bin/yq "$YQ_URL" 2>/dev/null; then
            chmod +x /usr/local/bin/yq
        else
            log_warn "Need sudo to install yq to /usr/local/bin"
            sudo wget -qO /usr/local/bin/yq "$YQ_URL"
            sudo chmod +x /usr/local/bin/yq
        fi
    else
        # Install to user directory
        mkdir -p "$HOME/.local/bin"
        wget -qO "$HOME/.local/bin/yq" "$YQ_URL"
        chmod +x "$HOME/.local/bin/yq"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log_warn "Please add $HOME/.local/bin to your PATH:"
            log_warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    fi
    
    if command -v yq &> /dev/null; then
        log_info "yq installed successfully"
    else
        log_warn "Failed to install yq"
        log_warn "yq is optional - you can still build Docker images"
        log_warn "For YAML processing, Python's yaml module will be used as fallback"
    fi
}

# ==============================================================================
# Check Haven Submodule
# ==============================================================================

check_haven_submodule() {
    log_info "Checking Haven submodule..."
    
    if [ ! -d "haven" ] || [ ! -f "haven/main.go" ]; then
        log_warn "Haven submodule not initialized"
        log_info "Initializing Haven submodule..."
        
        git submodule update --init --recursive
        
        if [ ! -f "haven/main.go" ]; then
            log_error "Failed to initialize Haven submodule"
            log_error "Please run: git submodule update --init --recursive"
            exit 1
        fi
    fi
    
    log_info "Haven submodule is ready"
    
    # Show Haven version
    if [ -f "haven/go.mod" ]; then
        HAVEN_VERSION=$(grep "^module" haven/go.mod | awk '{print $2}')
        log_info "Haven version: $HAVEN_VERSION"
    fi
}

# ==============================================================================
# Create Required Directories
# ==============================================================================

create_directories() {
    log_info "Creating required directories..."
    
    mkdir -p assets/compat
    mkdir -p .build
    mkdir -p releases
    
    log_info "Directories created"
}

# ==============================================================================
# Verify Installation
# ==============================================================================

verify_installation() {
    log_info "Verifying installation..."
    
    ERRORS=0
    WARNINGS=0
    
    # Check Start9 SDK (optional)
    if ! command -v start-sdk &> /dev/null; then
        log_warn "start-sdk not found (optional - needed only for final packaging)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check Docker (required)
    if ! command -v docker &> /dev/null; then
        log_error "docker not found (required)"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check yq (required)
    if ! command -v yq &> /dev/null; then
        log_warn "yq not found (attempting to use alternative methods)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check Haven submodule
    if [ ! -f "haven/main.go" ]; then
        log_error "Haven submodule not initialized"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check required files
    REQUIRED_FILES=(
        "Dockerfile"
        "docker_entrypoint.sh"
        "manifest.yaml"
        "instructions.md"
        "LICENSE"
        "Makefile"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Required file missing: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
    
    if [ $ERRORS -gt 0 ]; then
        log_error "Verification failed with $ERRORS error(s)"
        exit 1
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        log_warn "Verification completed with $WARNINGS warning(s)"
        log_info "You can proceed with Docker image building"
    else
        log_info "Verification passed"
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    echo ""
    log_info "=========================================="
    log_info "  Haven Start9 Package"
    log_info "  Build Environment Preparation"
    log_info "=========================================="
    echo ""
    
    check_system
    install_dependencies
    install_start9_sdk
    install_docker_buildx
    install_yq
    check_haven_submodule
    create_directories
    verify_installation
    
    echo ""
    log_info "=========================================="
    log_info "  ✅ Build environment ready!"
    log_info "=========================================="
    echo ""
    log_info "Next steps:"
    log_info "  1. Run 'make build' to build the package"
    log_info "  2. Run 'make verify' to verify the package"
    log_info "  3. Run 'make install' to install on Start9"
    echo ""
    log_info "For more commands, run: make help"
    echo ""
}

# Run main function
main

