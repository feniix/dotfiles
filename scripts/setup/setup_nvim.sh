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

# Create necessary directories
mkdir -p "$XDG_DATA_HOME/nvim/site/autoload"
mkdir -p "$XDG_STATE_HOME/nvim/undo"

# Install vim-plug if not already installed
if [ ! -f "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" ]; then
  echo "Installing vim-plug for Neovim..."
  curl -fLo "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "vim-plug installed successfully."
fi

# Link Neovim configuration directory
if [ -d "$DOTFILES_DIR/nvim" ]; then
  # Remove existing config directory if it's already a symlink or if it exists
  if [ -e "$XDG_CONFIG_HOME/nvim" ]; then
    if [ -L "$XDG_CONFIG_HOME/nvim" ]; then
      echo "Removing existing nvim symlink..."
      rm "$XDG_CONFIG_HOME/nvim"
    else
      echo "Backing up existing nvim configuration..."
      mv "$XDG_CONFIG_HOME/nvim" "$XDG_CONFIG_HOME/nvim.bak.$(date +%Y%m%d%H%M%S)"
    fi
  fi
  
  # Create symlink for the entire nvim directory
  ln -sf "$DOTFILES_DIR/nvim" "$XDG_CONFIG_HOME/nvim"
  echo "Linked nvim/ directory → $XDG_CONFIG_HOME/nvim"
  
  # Install plugins if nvim is available and --install-plugins flag is passed
  if [ "$1" = "--install-plugins" ] && command -v nvim >/dev/null 2>&1; then
    echo "Installing Neovim plugins..."
    nvim --headless +PlugInstall +qall
    echo "Neovim plugins installed successfully."
  fi
else
  echo "Neovim configuration directory not found at $DOTFILES_DIR/nvim"
  echo "Skipping Neovim configuration."
fi

echo "Neovim setup complete!" 