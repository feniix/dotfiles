#!/bin/bash
#
# Enhanced ASDF Version Manager Setup Script
# Sets up asdf and installs plugins from .tool-versions
# Supports modern asdf 0.17+ approach and multiple platforms

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
  echo -e "${BLUE}[ASDF]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[ASDF]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[ASDF]${NC} $1"
}

log_error() {
  echo -e "${RED}[ASDF]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Configure asdf environment for modern 0.17+ usage
configure_asdf_environment() {
  log_info "Configuring asdf environment..."
  
  # Determine asdf data directory
  local asdf_data_dir="${ASDF_DATA_DIR:-$HOME/.asdf}"
  
  # Ensure shims directory is in PATH for current session
  local shims_dir="$asdf_data_dir/shims"
  if [[ ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
    log_info "Added asdf shims to PATH for current session"
  fi
  
  # Platform-specific asdf sourcing (for legacy compatibility if needed)
  case "${DOTFILES_PLATFORM:-unknown}" in
    "macos")
      # On macOS, if installed via Homebrew, source the script
      if has "brew" && [ -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]; then
        . "$(brew --prefix asdf)/libexec/asdf.sh"
        log_info "Sourced asdf via Homebrew"
      fi
      ;;
    "ubuntu"|"linux")
      # On Linux, asdf 0.17+ should work via shims in PATH
      log_info "Using modern asdf 0.17+ shims approach"
      ;;
  esac
}

# Install plugins using modern asdf 0.17+ syntax
install_plugins_modern() {
  local plugins="$1"
  
  for plugin in $plugins; do
    if ! asdf plugin list | grep -q "^$plugin$"; then
      log_info "Installing asdf plugin: $plugin"
      if asdf plugin install "$plugin"; then
        log_success "✓ Plugin $plugin installed"
      else
        log_warning "✗ Failed to install plugin $plugin"
      fi
    else
      log_info "asdf plugin already installed: $plugin"
    fi
  done
  
  # Install all tools with specified versions
  log_info "Installing tool versions specified in .tool-versions..."
  if asdf install; then
    log_success "All tool versions installed successfully"
  else
    log_warning "Some tool versions failed to install"
    log_info "You can install individual tools later with: asdf install <plugin> <version>"
  fi
}

# Install plugins using legacy asdf syntax (pre-0.17)
install_plugins_legacy() {
  local plugins="$1"
  
  for plugin in $plugins; do
    if ! asdf plugin list | grep -q "^$plugin$"; then
      log_info "Installing asdf plugin: $plugin"
      if asdf plugin add "$plugin"; then
        log_success "✓ Plugin $plugin installed"
      else
        log_warning "✗ Failed to install plugin $plugin"
      fi
    else
      log_info "asdf plugin already installed: $plugin"
    fi
  done
  
  # Install all tools with specified versions
  log_info "Installing tool versions specified in .tool-versions..."
  if asdf install; then
    log_success "All tool versions installed successfully"
  else
    log_warning "Some tool versions failed to install"
    log_info "You can install individual tools later with: asdf install <plugin> <version>"
  fi
}

# Setup asdf version manager (modern 0.17+ approach)
setup_asdf() {
  log_info "Setting up asdf version manager..."

  # Ensure asdf is installed (platform-aware)
  if ! has "asdf"; then
    log_warning "asdf not found. Please ensure asdf is installed first."
    log_info "Run the platform-specific setup script to install asdf."
    return 1
  fi

  # Configure asdf environment for modern usage
  configure_asdf_environment

  # Check asdf version for syntax compatibility
  ASDF_VERSION=$(asdf version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
  if [[ "$ASDF_VERSION" != "unknown" ]]; then
    ASDF_MAJOR=$(echo "$ASDF_VERSION" | cut -d '.' -f1)
    ASDF_MINOR=$(echo "$ASDF_VERSION" | cut -d '.' -f2)
    log_info "Detected asdf version: $ASDF_VERSION (major: $ASDF_MAJOR, minor: $ASDF_MINOR)"
  else
    log_warning "Could not detect asdf version, assuming modern 0.17+"
    ASDF_MAJOR=0
    ASDF_MINOR=17
  fi
  
  # Install plugins from asdf-tool-versions
  if [ -f "$DOTFILES_DIR/asdf-tool-versions" ]; then
    log_info "Installing asdf plugins from $DOTFILES_DIR/asdf-tool-versions..."
    
    # Ensure .tool-versions symlink exists in $HOME
    if [ ! -L "$HOME/.tool-versions" ] || [ ! -e "$HOME/.tool-versions" ]; then
      log_info "Creating symlink for .tool-versions in $HOME"
      ln -sf "$DOTFILES_DIR/asdf-tool-versions" "$HOME/.tool-versions"
    fi
    
    # Extract plugin names (first column) from asdf-tool-versions
    PLUGINS=$(awk '{print $1}' "$DOTFILES_DIR/asdf-tool-versions")
    
    # Use modern asdf 0.17+ syntax (preferred) with fallback to legacy
    if [ "$ASDF_MAJOR" -gt 0 ] || [ "$ASDF_MINOR" -ge 17 ]; then
      log_info "Using modern asdf 0.17+ syntax (detected version: $ASDF_VERSION)"
      install_plugins_modern "$PLUGINS"
    else
      log_info "Using legacy asdf syntax (detected version: $ASDF_VERSION)"
      install_plugins_legacy "$PLUGINS"
    fi
    
    log_success "All asdf plugins and versions have been installed!"
  else
    log_warning "No asdf-tool-versions file found in $DOTFILES_DIR"
  fi
  
  # No direnv setup - using asdf standalone
}

# Run the setup
setup_asdf

log_success "asdf setup completed successfully!" 