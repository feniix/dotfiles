#!/bin/bash
#
# mise Version Manager Setup Script
# Sets up mise and installs tools from ~/.config/mise/config.toml

set -e

# Get script directory and dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

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

  local shims_dir="${XDG_DATA_HOME}/mise/shims"
  if [[ ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
    log_info "Added mise shims to PATH for current session"
  fi
}

# Setup mise version manager
setup_mise() {
  log_info "Setting up mise version manager..."

  if ! has "mise"; then
    log_warning "mise not found. Please ensure mise is installed first."
    log_info "On macOS with Homebrew: brew install mise"
    log_info "Or visit https://mise.jdx.dev/ for installation instructions."
    return 1
  fi

  configure_mise_environment

  MISE_VERSION=$(mise version 2>/dev/null || echo "unknown")
  log_info "Detected mise version: $MISE_VERSION"

  # Check for mise config.toml
  local mise_config="$XDG_CONFIG_HOME/mise/config.toml"
  if [ -f "$mise_config" ]; then
    log_info "Found mise configuration at $mise_config"

    log_info "Installing tool versions from config.toml..."
    if mise install; then
      state_record "SOFTWARE" "mise" "$mise_config"
      log_success "All tool versions installed successfully"
    else
      log_warning "Some tool versions failed to install"
      log_info "You can install individual tools later with: mise install <tool>@<version>"
    fi

    log_success "All mise tools have been installed!"
  else
    log_warning "No mise config found at $mise_config"
    log_info "Create one with: mise use <tool>@<version>"
  fi
}

# Run the setup
setup_mise

log_success "mise setup completed successfully!"
