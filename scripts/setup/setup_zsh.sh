#!/bin/bash
#
# ZSH and Oh-My-ZSH Setup Script
# Sets up oh-my-zsh with custom themes and plugins

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
  if RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    log_success "Oh My Zsh has been installed successfully."
  else
    log_error "Failed to install Oh My Zsh."
    exit 1
  fi
fi

# Set up custom themes and plugins
log_info "Setting up custom themes and plugins..."

# Define directories
ZSH_CUSTOM_DIR="$DOTFILES_DIR/zsh_custom"
OMZ_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"

# Ensure our dotfiles custom directories exist
mkdir -p "$ZSH_CUSTOM_DIR/themes"
mkdir -p "$ZSH_CUSTOM_DIR/plugins"

# Ensure oh-my-zsh custom directories exist (should be created by oh-my-zsh installer, but just in case)
mkdir -p "$OMZ_CUSTOM_DIR/themes"
mkdir -p "$OMZ_CUSTOM_DIR/plugins"

# Check if our bullet-train theme exists
if [ -f "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme" ]; then
  log_info "Bullet Train theme already exists in dotfiles."
else
  log_info "Installing Bullet Train theme..."
  
      # Skip theme download in check-only mode
    if [ "$CHECK_ONLY" = false ]; then
      if curl -fsSL -o "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme" https://raw.githubusercontent.com/caiogondim/bullet-train.zsh/master/bullet-train.zsh-theme; then
      log_success "Bullet Train theme installed successfully."
    else
      log_error "Failed to install Bullet Train theme."
    fi
  fi
fi

# Create symlink from oh-my-zsh custom themes to our theme
if [ -f "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme" ]; then
  log_info "Creating symlink for bullet-train theme in oh-my-zsh directory..."
  
  # Remove existing symlink if it exists (to avoid circular symlinks)
  if [ -L "$OMZ_CUSTOM_DIR/themes/bullet-train.zsh-theme" ]; then
    rm -f "$OMZ_CUSTOM_DIR/themes/bullet-train.zsh-theme"
  fi
  
  # Create the symlink using absolute paths
  ln -sf "$(realpath "$ZSH_CUSTOM_DIR/themes/bullet-train.zsh-theme")" "$OMZ_CUSTOM_DIR/themes/bullet-train.zsh-theme"
  log_success "Theme symlink created successfully."
fi

# Check for and install zsh-completions if missing
ZSH_COMPLETIONS_DIR="$ZSH_CUSTOM_DIR/plugins/zsh-completions"
if [ -d "$ZSH_COMPLETIONS_DIR" ]; then
  log_info "zsh-completions plugin already installed in dotfiles."
  
  # Update if requested and not in check-only mode
  if [ "$CHECK_ONLY" = false ]; then
    read -p "Do you want to update zsh-completions? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Updating zsh-completions..."
      
      # Use direct git commands instead of relying on submodule
      cd "$ZSH_COMPLETIONS_DIR"
      git pull origin master
      
      log_success "zsh-completions has been updated."
      cd - > /dev/null # Return to previous directory
    fi
  fi
else
  log_info "Installing zsh-completions plugin..."
  
  # Skip plugin installation in check-only mode
  if [ "$CHECK_ONLY" = false ]; then
    # Clone directly instead of using git submodule
    if git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_COMPLETIONS_DIR"; then
      log_success "zsh-completions plugin installed successfully."
    else
      log_error "Failed to install zsh-completions plugin."
    fi
  fi
fi

# Create symlink from oh-my-zsh custom plugins to our plugins
if [ -d "$ZSH_COMPLETIONS_DIR" ]; then
  log_info "Creating symlink for zsh-completions plugin in oh-my-zsh directory..."
  
  # Remove existing symlink if it exists (to avoid circular symlinks)
  if [ -L "$OMZ_CUSTOM_DIR/plugins/zsh-completions" ]; then
    rm -f "$OMZ_CUSTOM_DIR/plugins/zsh-completions"
  fi
  
  # Create the symlink using absolute paths
  ln -sf "$(realpath "$ZSH_COMPLETIONS_DIR")" "$OMZ_CUSTOM_DIR/plugins/zsh-completions"
  log_success "Plugin symlink created successfully."
fi

# Ensure zshrc has correct paths
log_info "Verifying zshrc configuration..."
ZSHRC="$DOTFILES_DIR/zshrc"

# Check if zshrc exists
if [ -f "$ZSHRC" ]; then
  # Check if ZSH path is correctly set
  if grep -q "export ZSH=\$HOME/.oh-my-zsh" "$ZSHRC"; then
    log_success "ZSH path is correctly configured in zshrc."
  else
    log_warning "ZSH path in zshrc may not be correctly set. Please ensure it contains: export ZSH=\$HOME/.oh-my-zsh"
  fi
  
  # Check if ZSH_CUSTOM path is correctly set
  if grep -q "export ZSH_CUSTOM=\$DOTFILES_DIR/zsh_custom\|export ZSH_CUSTOM=\$HOME/dotfiles/zsh_custom" "$ZSHRC"; then
    # This is a legacy approach - we now use symlinks to connect dotfiles/zsh_custom to .oh-my-zsh/custom
    log_warning "Note: Your zshrc sets ZSH_CUSTOM to your dotfiles directory. This works but is redundant with our symlink approach."
    log_info "To simplify your configuration, you can remove the ZSH_CUSTOM line from your zshrc."
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