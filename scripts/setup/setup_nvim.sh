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
mkdir -p "$XDG_CONFIG_HOME/nvim/lua/user"
mkdir -p "$XDG_DATA_HOME/nvim/site/autoload"
mkdir -p "$XDG_STATE_HOME/nvim/undo"

# Also create directories for regular Vim
mkdir -p "$XDG_CONFIG_HOME/vim"

# Install vim-plug if not already installed
if [ ! -f "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" ]; then
  echo "Installing vim-plug for Neovim..."
  curl -fLo "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "vim-plug installed successfully."
fi

# Link Neovim configuration files
if [ -d "$DOTFILES_DIR/nvim" ]; then
  # Link the main init.vim file
  ln -sf "$DOTFILES_DIR/nvim/init.vim" "$XDG_CONFIG_HOME/nvim/init.vim"
  echo "Linked nvim/init.vim → $XDG_CONFIG_HOME/nvim/init.vim"
  
  # Link Lua configurations
  if [ -f "$DOTFILES_DIR/nvim/lua/init.lua" ]; then
    ln -sf "$DOTFILES_DIR/nvim/lua/init.lua" "$XDG_CONFIG_HOME/nvim/lua/init.lua"
    echo "Linked nvim/lua/init.lua → $XDG_CONFIG_HOME/nvim/lua/init.lua"
  fi
  
  # Link the user directory files if they exist
  if [ -d "$DOTFILES_DIR/nvim/lua/user" ]; then
    for file in "$DOTFILES_DIR/nvim/lua/user"/*.lua; do
      if [ -f "$file" ]; then
        filename=$(basename "$file")
        ln -sf "$file" "$XDG_CONFIG_HOME/nvim/lua/user/$filename"
        echo "Linked nvim/lua/user/$filename → $XDG_CONFIG_HOME/nvim/lua/user/$filename"
      fi
    done
  fi
  
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