#!/bin/bash
#
# Setup XDG Base Directory Specification compliance for dotfiles
# This script creates the required directories and sets up necessary symlinks

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

# Create XDG Base Directories if they don't exist
log_info "Creating XDG Base Directories..."
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

log_success "XDG Base Directories created successfully."

# Zsh
log_info "Setting up Zsh with XDG compliance..."

# Note: Not creating a minimal .zshenv - the full one will be linked by setup.sh
# We're only showing a note if there's an existing non-symlinked .zshenv
if [ -f "$HOME/.zshenv" ] && [ ! -L "$HOME/.zshenv" ]; then
  log_warning "You have an existing .zshenv file that is not from your dotfiles."
  log_warning "It will be replaced with the dotfiles version for better XDG compliance."
fi

# Note about legacy config files
log_info "The actual configuration files will be linked from the dotfiles repository"
log_info "by the main setup.sh script. This script only sets up the directory structure."

# Setting up SSH
log_info "Setting up SSH with XDG compliance..."
mkdir -p "$HOME/.config/ssh"
if [ -d "$HOME/.ssh" ]; then
  log_info "For SSH, we recommend adding the following to your ~/.ssh/config file:"
  echo "Include ~/.config/ssh/config"
  echo ""
  log_info "SSH configuration remains in the standard location until you update it."
fi

log_success "XDG Base Directory setup complete!" 