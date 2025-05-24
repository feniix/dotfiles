#!/bin/bash
#
# Homebrew Setup Script
# Installs Homebrew and packages from Brewfile

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BREWFILE="${DOTFILES_DIR}/Brewfile"
BREWFILE_XDG="${XDG_CONFIG_HOME}/homebrew/Brewfile"

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

# Check if a command exists
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Install Homebrew if not present
install_homebrew() {
  if ! has "brew"; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Set up Homebrew environment based on platform
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    log_success "Homebrew installed successfully!"
  else
    log_info "Homebrew is already installed."
    
    # Ensure shell environment is set up
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi
}

# Setup XDG-compliant Brewfile location
setup_xdg_brewfile() {
  log_info "Setting up XDG-compliant Brewfile location..."
  
  mkdir -p "${XDG_CONFIG_HOME}/homebrew"
  
  if [ -f "$BREWFILE" ]; then
    # Create symlink to XDG location
    if [ ! -L "$BREWFILE_XDG" ]; then
      ln -sf "$BREWFILE" "$BREWFILE_XDG"
      log_success "Linked Brewfile → $BREWFILE_XDG"
    fi
    
    # Set Homebrew to use XDG location
    export HOMEBREW_BREWFILE="$BREWFILE_XDG"
    log_success "Set HOMEBREW_BREWFILE to $BREWFILE_XDG"
  else
    log_error "Brewfile not found at $BREWFILE"
    return 1
  fi
}

# Install packages from Brewfile
install_packages() {
  log_info "Installing packages from Brewfile..."
  
  if [ ! -f "$BREWFILE" ]; then
    log_error "Brewfile not found at $BREWFILE"
    return 1
  fi
  
  # Update Homebrew first
  log_info "Updating Homebrew..."
  brew update
  
  # Install packages
  log_info "Installing packages (this may take a while)..."
  brew bundle install --file="$BREWFILE" --verbose
  
  # Create Brewfile.lock.json in XDG location
  if [ -f "${DOTFILES_DIR}/Brewfile.lock.json" ]; then
    mkdir -p "${XDG_CONFIG_HOME}/homebrew"
    cp "${DOTFILES_DIR}/Brewfile.lock.json" "${XDG_CONFIG_HOME}/homebrew/Brewfile.lock.json"
    log_success "Copied Brewfile.lock.json to XDG location"
  else
    # Create empty lock file if it doesn't exist
    touch "${XDG_CONFIG_HOME}/homebrew/Brewfile.lock.json"
  fi
  
  log_success "All packages installed successfully!"
}

# Main setup function
setup_homebrew() {
  log_info "Setting up Homebrew and packages..."
  
  # Install Homebrew if needed
  install_homebrew
  
  # Setup XDG-compliant Brewfile
  setup_xdg_brewfile
  
  # Ask user if they want to install packages
  read -p "Install all packages from Brewfile? This may take a while. [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_packages
  else
    log_info "Skipping package installation. Run 'brew bundle install' later to install packages."
  fi
  
  log_success "Homebrew setup completed!"
}

# Run the setup
setup_homebrew 