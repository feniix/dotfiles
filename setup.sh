#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Create necessary XDG directories
setup_xdg() {
  echo "Setting up XDG Base Directory structure..."
  
  # Run the dedicated XDG setup script
  sh "$DOTFILES_DIR/setup_xdg.sh"
}

# Setup macOS-specific configurations
setup_macos() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Setting up macOS-specific configurations..."
    
    # Run the dedicated macOS setup script
    sh "$DOTFILES_DIR/setup_macos.sh"
  else
    echo "Not on macOS - skipping macOS-specific setup."
  fi
}

# Install or update dotfiles
install_dotfiles() {
  echo "Setting up dotfiles in XDG locations..."
  
  # Clone the repository if it doesn't exist yet
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone --recursive https://github.com/feniix/dotfiles.git "$DOTFILES_DIR"
  fi
  
  # Set up XDG directory structure
  setup_xdg
  
  # Link config files to XDG locations
  echo "Creating symlinks for configuration files..."
  
  # ZSH configuration
  if [ -f "$DOTFILES_DIR/zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"
    echo "Linked zshrc → $XDG_CONFIG_HOME/zsh/.zshrc"
  fi
  
  # Create/update zshenv in home directory
  if [ -f "$DOTFILES_DIR/zshenv" ]; then
    ln -sf "$DOTFILES_DIR/zshenv" "$HOME/.zshenv"
    echo "Linked zshenv → $HOME/.zshenv"
  fi
  
  # tmux configuration
  if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
    ln -sf "$DOTFILES_DIR/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
    echo "Linked tmux.conf → $XDG_CONFIG_HOME/tmux/tmux.conf"
    
    # Create a minimal .tmux.conf in home that sources the XDG config
    if [ ! -f "$HOME/.tmux.conf" ] || ! grep -q "source-file.*tmux\.conf" "$HOME/.tmux.conf"; then
      echo "# XDG compliant tmux configuration" > "$HOME/.tmux.conf"
      echo "source-file $XDG_CONFIG_HOME/tmux/tmux.conf" >> "$HOME/.tmux.conf"
      echo "Created minimal .tmux.conf that sources the XDG config"
    fi
  fi
  
  # Neovim configuration
  if [ -d "$DOTFILES_DIR/nvim" ]; then
    # Link the main init.vim file
    ln -sf "$DOTFILES_DIR/nvim/init.vim" "$XDG_CONFIG_HOME/nvim/init.vim"
    echo "Linked nvim/init.vim → $XDG_CONFIG_HOME/nvim/init.vim"
    
    # Make sure Neovim lua directory exists
    mkdir -p "$XDG_CONFIG_HOME/nvim/lua"
    
    # Link Lua configurations
    if [ -f "$DOTFILES_DIR/nvim/lua/init.lua" ]; then
      ln -sf "$DOTFILES_DIR/nvim/lua/init.lua" "$XDG_CONFIG_HOME/nvim/lua/init.lua"
      echo "Linked nvim/lua/init.lua → $XDG_CONFIG_HOME/nvim/lua/init.lua"
    fi
    
    # Link the user directory if it exists
    if [ -d "$DOTFILES_DIR/nvim/lua/user" ]; then
      mkdir -p "$XDG_CONFIG_HOME/nvim/lua/user"
      for file in "$DOTFILES_DIR/nvim/lua/user"/*.lua; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")
          ln -sf "$file" "$XDG_CONFIG_HOME/nvim/lua/user/$filename"
          echo "Linked nvim/lua/user/$filename → $XDG_CONFIG_HOME/nvim/lua/user/$filename"
        fi
      done
    fi
  fi
  
  # Git configuration
  if [ -f "$DOTFILES_DIR/gitconfig" ]; then
    ln -sf "$DOTFILES_DIR/gitconfig" "$XDG_CONFIG_HOME/git/config"
    echo "Linked gitconfig → $XDG_CONFIG_HOME/git/config"
  fi
  
  if [ -f "$DOTFILES_DIR/gitignore_global" ]; then
    ln -sf "$DOTFILES_DIR/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"
    echo "Linked gitignore_global → $XDG_CONFIG_HOME/git/ignore"
    
    # Create .gitconfig in home that includes the XDG config
    if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "include.*git/config" "$HOME/.gitconfig"; then
      echo "[include]" > "$HOME/.gitconfig"
      echo "    path = $XDG_CONFIG_HOME/git/config" >> "$HOME/.gitconfig"
      echo "Created minimal .gitconfig that includes the XDG config"
    fi
  fi
  
  # SSH configuration
  if [ -f "$DOTFILES_DIR/ssh_config" ]; then
    ln -sf "$DOTFILES_DIR/ssh_config" "$XDG_CONFIG_HOME/ssh/config"
    echo "Linked ssh_config → $XDG_CONFIG_HOME/ssh/config"
    
    # Check if we need to update ~/.ssh/config to include our XDG config
    if [ -f "$HOME/.ssh/config" ]; then
      if ! grep -q "Include.*config/ssh/config" "$HOME/.ssh/config"; then
        echo "NOTE: To use your SSH config, add this line to ~/.ssh/config:"
        echo "Include ~/.config/ssh/config"
      fi
    else
      # Create a basic ~/.ssh/config that includes our XDG config
      mkdir -p "$HOME/.ssh"
      echo "# XDG-compliant SSH configuration" > "$HOME/.ssh/config"
      echo "Include ~/.config/ssh/config" >> "$HOME/.ssh/config"
      chmod 600 "$HOME/.ssh/config"
      echo "Created minimal ~/.ssh/config that includes the XDG config"
    fi
  fi
  
  # Create additional symlinks for tools that don't fully support XDG
  if [ -d "$DOTFILES_DIR/oh-my-zsh" ]; then
    ln -sf "$DOTFILES_DIR/oh-my-zsh" "$XDG_DATA_HOME/oh-my-zsh"
    echo "Linked oh-my-zsh → $XDG_DATA_HOME/oh-my-zsh"
  fi
  
  if [ -d "$DOTFILES_DIR/sbin" ]; then
    ln -sf "$DOTFILES_DIR/sbin" "$HOME/sbin"
    echo "Linked sbin → $HOME/sbin"
  fi
  
  # Run macOS-specific setup if on macOS
  setup_macos
  
  echo "XDG-compliant dotfiles installation completed!"
}

# Make scripts executable
make_scripts_executable() {
  echo "Making scripts executable..."
  [ -f "$DOTFILES_DIR/setup_xdg.sh" ] && chmod +x "$DOTFILES_DIR/setup_xdg.sh"
  [ -f "$DOTFILES_DIR/setup_macos.sh" ] && chmod +x "$DOTFILES_DIR/setup_macos.sh"
  [ -f "$DOTFILES_DIR/osx-defaults" ] && chmod +x "$DOTFILES_DIR/osx-defaults"
  [ -f "$DOTFILES_DIR/setup.sh" ] && chmod +x "$DOTFILES_DIR/setup.sh"
}

# Main script logic
echo "╔════════════════════════════════════════╗"
echo "║     XDG-compliant Dotfiles Setup       ║"
echo "╚════════════════════════════════════════╝"

if [ -d "$DOTFILES_DIR" ]; then
  # Make sure scripts are executable
  make_scripts_executable
  
  echo "Dotfiles directory already exists."
  echo "1. Update existing dotfiles to XDG format"
  echo "2. Run XDG setup only (for migrating existing configs)"
  echo "3. Run macOS-specific setup only"
  echo "4. Exit"
  
  read -p "Enter your choice (1-4): " choice
  
  case $choice in
    1)
      install_dotfiles
      ;;
    2)
      setup_xdg
      echo "XDG Base Directory structure set up."
      ;;
    3)
      setup_macos
      echo "macOS-specific setup complete."
      ;;
    4)
      echo "Exiting without changes."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
else
  # Fresh install
  install_dotfiles
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║             Setup Complete!            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Your dotfiles now follow the XDG Base Directory Specification."
echo "Restart your terminal to apply all changes."
