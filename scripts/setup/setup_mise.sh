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
if ! declare -F state_init >/dev/null; then
  source "$DOTFILES_DIR/scripts/lib/state.sh"
fi
source "$DOTFILES_DIR/scripts/lib/software.sh"

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
    log_info "Installing mise with Homebrew..."
    software_track_brew_install brew install mise || return 1
  fi
  command -v jq >/dev/null || { log_error "jq is required for software ownership tracking."; return 1; }

  configure_mise_environment

  MISE_VERSION=$(mise version 2>/dev/null || echo "unknown")
  log_info "Detected mise version: $MISE_VERSION"

  # Check for mise config.toml
  local mise_config="$XDG_CONFIG_HOME/mise/config.toml"
  state_mkdir "$XDG_CONFIG_HOME/mise"
  state_symlink "$DOTFILES_DIR/mise/config.toml" "$mise_config"
  if [ -f "$mise_config" ]; then
    log_info "Found mise configuration at $mise_config"

    log_info "Installing tool versions from config.toml..."
    if software_install_mise; then
      log_success "All tool versions installed successfully"
    else
      log_error "Tool installation failed; any added versions remain tracked."
      log_info "You can install individual tools later with: mise install <tool>@<version>"
      return 1
    fi

    log_success "All mise tools have been installed!"
  else
    log_warning "No mise config found at $mise_config"
    log_info "Create one with: mise use <tool>@<version>"
  fi
}

# Run the setup
state_init
setup_mise

log_success "mise setup completed successfully!"
