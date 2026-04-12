#!/bin/bash
#
# Homebrew Setup Script
# Installs Homebrew and packages from Brewfile

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BREWFILE="${DOTFILES_DIR}/Brewfile"

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

    if [[ $(uname -m) == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully!"
  else
    log_info "Homebrew is already installed."
  fi
}

# Install packages from Brewfile
install_packages() {
  log_info "Installing packages from Brewfile..."

  if [ ! -f "$BREWFILE" ]; then
    log_error "Brewfile not found at $BREWFILE"
    return 1
  fi

  log_info "Updating Homebrew..."
  brew update

  log_info "Installing packages (this may take a while)..."
  brew bundle install --file="$BREWFILE" --verbose

  log_success "All packages installed successfully!"
}

# Main setup function
setup_homebrew() {
  log_info "Setting up Homebrew and packages..."

  install_homebrew

  read -p "Install all packages from Brewfile? This may take a while. [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_packages
  else
    log_info "Skipping package installation. Run 'brew bundle install --file=$BREWFILE' later to install packages."
  fi

  log_success "Homebrew setup completed!"
}

# Run the setup
setup_homebrew
