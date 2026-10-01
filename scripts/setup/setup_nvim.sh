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

if ! declare -F state_init >/dev/null; then
  source "$DOTFILES_DIR/scripts/lib/state.sh"
fi
state_init
state_mkdir "$XDG_CONFIG_HOME"

log_info "Setting up Neovim with XDG compliance..."

# Create necessary runtime directories (separate from config)
# Note: ~/.config/nvim will be a symlink to $DOTFILES_DIR/nvim
# These directories are for Neovim's runtime data, not configuration files
state_mkdir "$XDG_DATA_HOME/nvim"        # Plugin data, site packages
state_mkdir "$XDG_STATE_HOME/nvim/undo"  # Persistent undo files
state_mkdir "$XDG_CACHE_HOME/nvim"       # Cache files, compiled plugins

# Link Neovim configuration
if [ -d "$DOTFILES_DIR/nvim" ]; then
  # Create the symlink to the entire nvim directory (state_symlink handles backup)
  state_symlink "$DOTFILES_DIR/nvim" "$XDG_CONFIG_HOME/nvim"
  log_success "Linked nvim/ → $XDG_CONFIG_HOME/nvim"
  
  # With --install-plugins, install plugins on a fresh machine (no
  # lazy.nvim yet). "Lazy! restore" blocks until done and checks out the
  # commits in lazy-lock.json; "Lazy sync" would update and rewrite the
  # tracked lockfile. An existing install is left alone.
  lazy_dir="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
  if [ "$1" = "--install-plugins" ] && command -v nvim >/dev/null 2>&1; then
    if [ -d "$lazy_dir" ]; then
      log_info "lazy.nvim already installed; skipping plugin restore."
    else
      log_info "Installing Neovim plugins from lazy-lock.json..."
      if nvim --headless "+Lazy! restore" +qa; then
        log_success "Neovim plugins installed."
      else
        log_warning "Plugin install failed; run nvim and :Lazy restore."
      fi
    fi
  fi
else
  log_error "Neovim configuration directory not found at $DOTFILES_DIR/nvim"
  log_warning "Skipping Neovim configuration."
fi

log_success "Neovim setup complete!"
echo ""
echo "Neovim configuration is now available at:"
echo "  Config directory: $XDG_CONFIG_HOME/nvim -> $DOTFILES_DIR/nvim"
echo "  Main config: $XDG_CONFIG_HOME/nvim/init.lua"
echo "  Lua modules: $XDG_CONFIG_HOME/nvim/lua/"
echo ""
echo "To install plugins, run: nvim and execute :Lazy restore"

echo ""
echo "Run $DOTFILES_DIR/scripts/nvim/check_nvim.sh to verify the setup."
