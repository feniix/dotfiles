#!/bin/bash
#
# Setup Neovim with XDG Base Directory Specification compliance
# This script sets up Neovim configuration in XDG-compliant locations

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

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

log_info "Setting up Neovim with XDG compliance..."

# Create necessary runtime directories (separate from config)
# Note: ~/.config/nvim will be a symlink to $DOTFILES_DIR/nvim
# These directories are for Neovim's runtime data, not configuration files
mkdir -p "$XDG_DATA_HOME/nvim"        # Plugin data, site packages
mkdir -p "$XDG_STATE_HOME/nvim/undo"  # Persistent undo files  
mkdir -p "$XDG_CACHE_HOME/nvim"       # Cache files, compiled plugins

# Also create directories for regular Vim
mkdir -p "$XDG_CONFIG_HOME/vim"

# Link Neovim configuration
if [ -d "$DOTFILES_DIR/nvim" ]; then
  # Remove existing nvim config directory if it exists and is not a symlink
  if [ -d "$XDG_CONFIG_HOME/nvim" ] && [ ! -L "$XDG_CONFIG_HOME/nvim" ]; then
    log_warning "Backing up existing Neovim configuration..."
    mv "$XDG_CONFIG_HOME/nvim" "$XDG_CONFIG_HOME/nvim.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  
  # Remove existing symlink if it exists (to avoid circular symlinks)
  if [ -L "$XDG_CONFIG_HOME/nvim" ]; then
    rm -f "$XDG_CONFIG_HOME/nvim"
  fi
  
  # Create the symlink to the entire nvim directory using absolute paths
  ln -sf "$(realpath "$DOTFILES_DIR/nvim")" "$XDG_CONFIG_HOME/nvim"
  log_success "Linked nvim/ → $XDG_CONFIG_HOME/nvim"
  
  # Install plugins if nvim is available and --install-plugins flag is passed
  if [ "$1" = "--install-plugins" ] && command -v nvim >/dev/null 2>&1; then
    log_info "Installing Neovim plugins..."
    # Use Lazy sync for plugin installation
    nvim --headless -c 'Lazy sync' -c 'sleep 3000m' -c 'quitall'
    log_success "Neovim plugins installed successfully."
  fi
else
  log_error "Neovim configuration directory not found at $DOTFILES_DIR/nvim"
  log_warning "Skipping Neovim configuration."
fi

# Set up .vimrc for Vim compatibility
if [ -f "$DOTFILES_DIR/.vimrc" ]; then
  # Link .vimrc to home directory
  ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  log_success "Linked .vimrc → $HOME/.vimrc"
  
  # Link .vimrc to XDG config directory for Vim
  ln -sf "$DOTFILES_DIR/.vimrc" "$XDG_CONFIG_HOME/vim/vimrc"
  log_success "Linked .vimrc → $XDG_CONFIG_HOME/vim/vimrc"
else
  log_warning "Vim configuration file not found at $DOTFILES_DIR/.vimrc"
  log_warning "Skipping Vim configuration."
fi

log_success "Neovim and Vim setup complete!"
echo ""
echo "Neovim configuration is now available at:"
echo "  Config directory: $XDG_CONFIG_HOME/nvim -> $DOTFILES_DIR/nvim"
echo "  Main config: $XDG_CONFIG_HOME/nvim/init.lua"
echo "  Lua modules: $XDG_CONFIG_HOME/nvim/lua/"
echo ""
echo "To install plugins, run: nvim and execute :Lazy sync"

# Show available nvim management scripts
echo ""
echo "Neovim management scripts are available:"
if [ -f "$DOTFILES_DIR/scripts/nvim/setup_and_check.sh" ]; then
  echo "  • Complete setup & check: $DOTFILES_DIR/scripts/nvim/setup_and_check.sh"
fi
if [ -f "$DOTFILES_DIR/scripts/nvim/health_check.sh" ]; then
  echo "  • Health check: $DOTFILES_DIR/scripts/nvim/health_check.sh"
fi
if [ -f "$DOTFILES_DIR/scripts/nvim/check_plugins.sh" ]; then
  echo "  • Plugin status: $DOTFILES_DIR/scripts/nvim/check_plugins.sh"
fi
if [ -f "$DOTFILES_DIR/scripts/nvim/nvim_help.sh" ]; then
  echo "  • Quick help: $DOTFILES_DIR/scripts/nvim/nvim_help.sh"
fi
echo ""
echo "For help: $DOTFILES_DIR/scripts/nvim/nvim_help.sh" 