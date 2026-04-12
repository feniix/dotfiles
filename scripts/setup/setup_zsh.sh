#!/bin/bash
#
# ZSH and Oh-My-ZSH Setup Script
# Sets up oh-my-zsh with Powerlevel10k (installed via Homebrew)

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  if [[ "$CHECK_ONLY" == "true" ]]; then
    echo -e "${BLUE}[INFO]${NC} $1" >&2
  else
    echo -e "${BLUE}[INFO]${NC} $1"
  fi
}

log_success() {
  if [[ "$CHECK_ONLY" == "true" ]]; then
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
  else
    echo -e "${GREEN}[SUCCESS]${NC} $1"
  fi
}

log_warning() {
  if [[ "$CHECK_ONLY" == "true" ]]; then
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
  else
    echo -e "${YELLOW}[WARNING]${NC} $1"
  fi
}

log_error() {
  if [[ "$CHECK_ONLY" == "true" ]]; then
    echo -e "${RED}[ERROR]${NC} $1" >&2
  else
    echo -e "${RED}[ERROR]${NC} $1"
  fi
}

# Check for --check-only flag
CHECK_ONLY=false
if [[ "$1" == "--check-only" ]]; then
  CHECK_ONLY=true
fi

# Check if oh-my-zsh is already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
  log_info "Oh My Zsh is already installed at $HOME/.oh-my-zsh"

  # Ask if the user wants to update
  if [ "$CHECK_ONLY" = false ]; then
    read -p "Do you want to update oh-my-zsh? [y/N] " -n 1 -r || true
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Updating oh-my-zsh..."

      env ZSH="$HOME/.oh-my-zsh" sh -c '
        cd "$ZSH"
        git fetch --quiet origin
        git reset --hard origin/master
      '

      log_success "Oh My Zsh has been updated."
    fi
  fi
else
  log_info "Oh My Zsh is not installed. Installing now..."

  if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install git first."
    exit 1
  fi

  if [ "$CHECK_ONLY" = true ]; then
    log_error "Oh My Zsh is not installed (check-only mode)."
    exit 1
  fi

  if RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    state_record "SOFTWARE" "omz" "$HOME/.oh-my-zsh"
    log_success "Oh My Zsh has been installed successfully."
  else
    log_error "Failed to install Oh My Zsh."
    exit 1
  fi
fi

# Verify Powerlevel10k is installed via Homebrew
log_info "Checking Powerlevel10k installation..."
if [ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]; then
  log_success "Powerlevel10k is installed via Homebrew."
else
  log_warning "Powerlevel10k is not installed via Homebrew."
  if [ "$CHECK_ONLY" = false ]; then
    log_info "Install it with: brew install powerlevel10k"
  fi
fi

# Verify zsh-completions is installed via Homebrew
log_info "Checking zsh-completions installation..."
if brew list zsh-completions &>/dev/null; then
  log_success "zsh-completions is installed via Homebrew."
else
  log_warning "zsh-completions is not installed via Homebrew."
  if [ "$CHECK_ONLY" = false ]; then
    log_info "Install it with: brew install zsh-completions"
  fi
fi

# Ensure zshrc has correct paths
log_info "Verifying zshrc configuration..."
ZSHRC="$DOTFILES_DIR/zshrc"

if [ -f "$ZSHRC" ]; then
  if grep -q "export ZSH=\$HOME/.oh-my-zsh" "$ZSHRC"; then
    log_success "ZSH path is correctly configured in zshrc."
  else
    log_warning "ZSH path in zshrc may not be correctly set. Please ensure it contains: export ZSH=\$HOME/.oh-my-zsh"
  fi
else
  log_error "zshrc file not found at $ZSHRC. Please check your configuration."
fi

# Skip final message in check-only mode
if [ "$CHECK_ONLY" = false ]; then
  log_success "Zsh setup completed successfully!"
  log_info "If you haven't already, restart your terminal to apply changes."
fi
