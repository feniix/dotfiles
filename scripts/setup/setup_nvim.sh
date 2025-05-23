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

echo "Setting up Neovim with XDG compliance..."

# Create necessary runtime directories (separate from config)
# Note: ~/.config/nvim will be a symlink to ~/dotfiles/nvim
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
    echo "Backing up existing Neovim configuration..."
    mv "$XDG_CONFIG_HOME/nvim" "$XDG_CONFIG_HOME/nvim.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  
  # Create the symlink to the entire nvim directory
  ln -sf "$DOTFILES_DIR/nvim" "$XDG_CONFIG_HOME/nvim"
  echo "Linked nvim/ → $XDG_CONFIG_HOME/nvim"
  
  # Install plugins if nvim is available and --install-plugins flag is passed
  if [ "$1" = "--install-plugins" ] && command -v nvim >/dev/null 2>&1; then
    echo "Installing Neovim plugins..."
    # Use Lazy sync for plugin installation
    nvim --headless -c 'Lazy sync' -c 'sleep 3000m' -c 'quitall'
    echo "Neovim plugins installed successfully."
  fi
else
  echo "Neovim configuration directory not found at $DOTFILES_DIR/nvim"
  echo "Skipping Neovim configuration."
fi

# Set up .vimrc for Vim compatibility
if [ -f "$DOTFILES_DIR/.vimrc" ]; then
  # Link .vimrc to home directory
  ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  echo "Linked .vimrc → $HOME/.vimrc"
  
  # Link .vimrc to XDG config directory for Vim
  ln -sf "$DOTFILES_DIR/.vimrc" "$XDG_CONFIG_HOME/vim/vimrc"
  echo "Linked .vimrc → $XDG_CONFIG_HOME/vim/vimrc"
else
  echo "Vim configuration file not found at $DOTFILES_DIR/.vimrc"
  echo "Skipping Vim configuration."
fi

echo "Neovim and Vim setup complete!"
echo ""
echo "Neovim configuration is now available at:"
echo "  Config directory: $XDG_CONFIG_HOME/nvim -> $DOTFILES_DIR/nvim"
echo "  Main config: $XDG_CONFIG_HOME/nvim/init.lua"
echo "  Lua modules: $XDG_CONFIG_HOME/nvim/lua/"
echo ""
echo "To install plugins, run: nvim and execute :Lazy sync" 