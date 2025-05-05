#!/bin/bash
#
# Setup XDG Base Directory Specification compliance for dotfiles
# This script creates the required directories and sets up necessary symlinks

set -e

# Create XDG Base Directories if they don't exist
echo "Creating XDG Base Directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share"
mkdir -p "$HOME/.cache"
mkdir -p "$HOME/.local/state"

# Create subdirectories for various tools
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/tmux"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/nvim/lua"
mkdir -p "$HOME/.config/git"

# Zsh
echo "Setting up Zsh with XDG compliance..."

# Note: Not creating a minimal .zshenv - the full one will be linked by setup.sh
# We're only showing a note if there's an existing non-symlinked .zshenv
if [ -f "$HOME/.zshenv" ] && [ ! -L "$HOME/.zshenv" ]; then
  echo "NOTE: You have an existing .zshenv file that is not from your dotfiles."
  echo "      It will be replaced with the dotfiles version for better XDG compliance."
fi

# Note about legacy config files
echo "NOTE: The actual configuration files will be linked from the dotfiles repository"
echo "      by the main setup.sh script. This script only sets up the directory structure."
echo

# Setting up SSH
echo "Setting up SSH with XDG compliance..."
mkdir -p "$HOME/.config/ssh"
if [ -d "$HOME/.ssh" ]; then
  echo "For SSH, we recommend adding the following to your ~/.ssh/config file:"
  echo "Include ~/.config/ssh/config"
  echo ""
  echo "SSH configuration remains in the standard location until you update it."
fi

echo "XDG Base Directory setup complete!" 