#!/bin/bash
#
# ASDF Version Manager Setup Script
# Sets up asdf and installs plugins from .tool-versions

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
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
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Setup asdf version manager
setup_asdf() {
  log_info "Setting up asdf version manager..."

  # Ensure asdf is installed via Homebrew
  if ! has "asdf"; then
    log_warning "asdf not found. Installing with Homebrew..."
    if has "brew"; then
      brew install asdf
    else
      log_error "Homebrew not installed. Please install Homebrew first."
      return 1
    fi
  fi

  # Source asdf
  . "$(brew --prefix asdf)/libexec/asdf.sh"

  # Check asdf version for syntax compatibility
  ASDF_VERSION=$(asdf version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
  ASDF_MAJOR=$(echo $ASDF_VERSION | cut -d '.' -f1)
  ASDF_MINOR=$(echo $ASDF_VERSION | cut -d '.' -f2)
  log_info "Detected asdf version: $ASDF_VERSION (major: $ASDF_MAJOR, minor: $ASDF_MINOR)"
  
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
    
    # Determine if we're using new (0.17.0+) or legacy syntax
    if [ "$ASDF_MAJOR" -gt 0 ] || [ "$ASDF_MINOR" -ge 17 ]; then
      log_info "Using asdf 0.17.0+ syntax (detected version: $ASDF_VERSION)"
      
      for plugin in $PLUGINS; do
        if ! asdf plugin list | grep -q "^$plugin$"; then
          log_info "Installing asdf plugin: $plugin"
          asdf plugin install "$plugin"
        else
          log_info "asdf plugin already installed: $plugin"
        fi
      done
      
      # Install all tools with specified versions
      log_info "Installing tool versions specified in .tool-versions..."
      asdf install
    else
      log_info "Using legacy asdf syntax (detected version: $ASDF_VERSION)"
      
      for plugin in $PLUGINS; do
        if ! asdf plugin list | grep -q "^$plugin$"; then
          log_info "Installing asdf plugin: $plugin"
          asdf plugin add "$plugin"
        else
          log_info "asdf plugin already installed: $plugin"
        fi
      done
      
      # Install all tools with specified versions
      log_info "Installing tool versions specified in .tool-versions..."
      asdf install
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