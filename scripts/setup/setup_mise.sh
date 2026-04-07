#!/bin/bash
#
# Enhanced mise Version Manager Setup Script
# Sets up mise and installs tools from .tool-versions
# Supports mise and multiple platforms

set -e

# Get script directory and dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source platform detection if available
if [ -f "$SCRIPT_DIR/../utils/platform_detection.sh" ]; then
  source "$SCRIPT_DIR/../utils/platform_detection.sh"
  # Run detection if not already done
  if [[ -z "$DOTFILES_PLATFORM" ]]; then
    detect_platform
  fi
fi

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[mise]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[mise]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[mise]${NC} $1"
}

log_error() {
  echo -e "${RED}[mise]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Configure mise environment
configure_mise_environment() {
  log_info "Configuring mise environment..."

  # Ensure shims directory is in PATH for current session
  local shims_dir="${XDG_DATA_HOME}/mise/shims"
  if [[ ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
    log_info "Added mise shims to PATH for current session"
  fi

  log_info "Using mise shims approach"
}

# Setup mise version manager
setup_mise() {
  log_info "Setting up mise version manager..."

  # Ensure mise is installed (platform-aware)
  if ! has "mise"; then
    log_warning "mise not found. Please ensure mise is installed first."
    log_info "On macOS with Homebrew: brew install mise"
    log_info "Or visit https://mise.jdx.dev/ for installation instructions."
    return 1
  fi

  # Configure mise environment
  configure_mise_environment

  # Check mise version
  MISE_VERSION=$(mise version 2>/dev/null || echo "unknown")
  log_info "Detected mise version: $MISE_VERSION"

  # Install tools from .tool-versions
  if [ -f "$DOTFILES_DIR/asdf-tool-versions" ]; then
    log_info "Installing mise tools from $DOTFILES_DIR/asdf-tool-versions..."

    # Ensure .tool-versions symlink exists in $HOME
    if [ ! -L "$HOME/.tool-versions" ] || [ ! -e "$HOME/.tool-versions" ]; then
      log_info "Creating symlink for .tool-versions in $HOME"
      ln -sf "$DOTFILES_DIR/asdf-tool-versions" "$HOME/.tool-versions"
    fi

    # Install all tools with specified versions
    log_info "Installing tool versions from .tool-versions..."
    if mise install; then
      log_success "All tool versions installed successfully"
    else
      log_warning "Some tool versions failed to install"
      log_info "You can install individual tools later with: mise install <tool> <version>"
    fi

    log_success "All mise tools have been installed!"
  else
    log_warning "No asdf-tool-versions file found in $DOTFILES_DIR"
  fi
}

# Run the setup
setup_mise

log_success "mise setup completed successfully!"
