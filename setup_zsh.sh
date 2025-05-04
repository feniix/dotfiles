#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for --check-only flag
CHECK_ONLY=false
if [[ "$1" == "--check-only" ]]; then
  CHECK_ONLY=true
  log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
  }
  
  log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
  }
  
  log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
  }
  
  log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
  }
else
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
fi

# Check if oh-my-zsh is already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
  log_info "Oh My Zsh is already installed at $HOME/.oh-my-zsh"
  
  # Ask if the user wants to update
  if [ "$CHECK_ONLY" = false ]; then
    read -p "Do you want to update oh-my-zsh? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Updating oh-my-zsh..."
      
      # Use the official update script
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
  
  # Check if git is installed
  if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install git first."
    exit 1
  fi
  
  # Skip actual installation if we're just checking
  if [ "$CHECK_ONLY" = true ]; then
    log_error "Failed to install Oh My Zsh."
    exit 1
  fi
  
  # Install oh-my-zsh using the official installer
  # But we disable auto-setting the shell since we'll handle that
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  
  if [ $? -eq 0 ]; then
    log_success "Oh My Zsh has been installed successfully."
  else
    log_error "Failed to install Oh My Zsh."
    exit 1
  fi
fi

# Set up custom themes and plugins
log_info "Setting up custom themes and plugins..."

# Ensure zsh_custom directory exists
ZSH_CUSTOM_DIR="$HOME/dotfiles/zsh_custom"
mkdir -p "$ZSH_CUSTOM_DIR/themes"
mkdir -p "$ZSH_CUSTOM_DIR/plugins"

# Check if our bullet-train theme exists
if [ -f "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme" ]; then
  log_info "Bullet Train theme already installed."
else
  log_info "Installing Bullet Train theme..."
  
  # Skip theme download in check-only mode
  if [ "$CHECK_ONLY" = false ]; then
    curl -fsSL -o "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme" https://raw.githubusercontent.com/caiogondim/bullet-train.zsh/master/bullet-train.zsh-theme
    
    if [ $? -eq 0 ]; then
      log_success "Bullet Train theme installed successfully."
    else
      log_error "Failed to install Bullet Train theme."
    fi
  fi
fi

# Check for and install zsh-completions if missing
ZSH_COMPLETIONS_DIR="$ZSH_CUSTOM_DIR/plugins/zsh-completions"
if [ -d "$ZSH_COMPLETIONS_DIR" ]; then
  log_info "zsh-completions plugin already installed."
  
  # Update if requested and not in check-only mode
  if [ "$CHECK_ONLY" = false ]; then
    read -p "Do you want to update zsh-completions? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Updating zsh-completions..."
      
      cd "$ZSH_COMPLETIONS_DIR"
      git pull origin master
      
      log_success "zsh-completions has been updated."
    fi
  fi
else
  log_info "Installing zsh-completions plugin..."
  
  # Skip plugin installation in check-only mode
  if [ "$CHECK_ONLY" = false ]; then
    git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_COMPLETIONS_DIR"
    
    if [ $? -eq 0 ]; then
      log_success "zsh-completions plugin installed successfully."
    else
      log_error "Failed to install zsh-completions plugin."
    fi
  fi
fi

# Ensure zshrc has correct paths
log_info "Verifying zshrc configuration..."
ZSHRC="$HOME/dotfiles/zshrc"

# Check if zshrc exists
if [ -f "$ZSHRC" ]; then
  # Check if ZSH path is correctly set
  if grep -q "export ZSH=\$HOME/.oh-my-zsh" "$ZSHRC"; then
    log_success "ZSH path is correctly configured in zshrc."
  else
    log_warning "ZSH path in zshrc may not be correctly set. Please ensure it contains: export ZSH=\$HOME/.oh-my-zsh"
  fi
  
  # Check if ZSH_CUSTOM path is correctly set
  if grep -q "export ZSH_CUSTOM=\$HOME/dotfiles/zsh_custom" "$ZSHRC"; then
    log_success "ZSH_CUSTOM path is correctly configured in zshrc."
  else
    log_warning "ZSH_CUSTOM path in zshrc may not be correctly set. Please ensure it contains: export ZSH_CUSTOM=\$HOME/dotfiles/zsh_custom"
  fi
else
  log_error "zshrc file not found at $ZSHRC. Please check your configuration."
fi

# Skip final message in check-only mode
if [ "$CHECK_ONLY" = false ]; then
  # Final message
  log_success "Zsh setup completed successfully!"
  log_info "If you haven't already, run 'source ~/.zshrc' or restart your terminal to apply changes."
fi 