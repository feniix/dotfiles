#!/bin/bash
#
# Setup Homebrew and install packages
# This script installs Homebrew if missing and manages packages via Brewfile

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

# Detect architecture
detect_arch() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "arm64"
  else
    echo "x86_64"
  fi
}

# Detect system type
detect_system() {
  local arch=$(detect_arch)
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$arch" == "arm64" ]]; then
      echo "macos-apple-silicon"
    else
      echo "macos-intel"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Install Homebrew if not already installed
install_homebrew() {
  if ! command -v brew &> /dev/null; then
    log_info "Homebrew not found. Installing Homebrew..."
    
    # Run the Homebrew installer
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    local system=$(detect_system)
    if [[ "$system" == "macos-apple-silicon" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      log_info "Added Homebrew to the current PATH for Apple Silicon Mac"
    elif [[ "$system" == "macos-intel" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
      log_info "Added Homebrew to the current PATH for Intel Mac"
    elif [[ "$system" == "linux" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      log_info "Added Homebrew to the current PATH for Linux"
    fi
    
    # Verify installation
    if command -v brew &> /dev/null; then
      log_success "Homebrew installed successfully!"
    else
      log_error "Homebrew installation failed. Please install manually and try again."
      exit 1
    fi
  else
    log_info "Homebrew is already installed."
  fi
}

# Setup Brewfile in XDG location
setup_brewfile() {
  log_info "Setting up Brewfile in XDG location..."
  
  # Create XDG directory for Homebrew
  mkdir -p "${XDG_CONFIG_HOME}/homebrew"
  
  # Link Brewfile to XDG location if it exists
  if [ -f "$BREWFILE" ]; then
    ln -sf "$BREWFILE" "$BREWFILE_XDG"
    log_success "Linked Brewfile → $BREWFILE_XDG"
  else
    log_warning "Brewfile not found at $BREWFILE"
  fi
}

# Install packages from Brewfile
install_packages() {
  log_info "Installing packages from Brewfile..."
  
  # Check if Brewfile exists in either location
  if [ -f "$BREWFILE_XDG" ]; then
    log_info "Using Brewfile at $BREWFILE_XDG"
    brew bundle --file="$BREWFILE_XDG"
  elif [ -f "$BREWFILE" ]; then
    log_info "Using Brewfile at $BREWFILE"
    brew bundle --file="$BREWFILE"
  else
    log_error "No Brewfile found. Skipping package installation."
    return 1
  fi
  
  log_success "Homebrew packages installed successfully!"
}

# Homebrew post-installation setup
post_install_setup() {
  log_info "Running post-installation setup..."
  
  # Detect system
  local system=$(detect_system)
  
  # Create a Brewfile.lock.json in the XDG location
  if [ -f "$BREWFILE_XDG" ]; then
    touch "${XDG_CONFIG_HOME}/homebrew/Brewfile.lock.json"
  fi
  
  # Apply specific fixes based on architecture
  if [[ "$system" == "macos-apple-silicon" ]]; then
    log_info "Applying Apple Silicon specific configurations..."
    
    # Fix any potential Rosetta-related issues
    # This is a preventive measure for packages that might need Rosetta
    if ! pgrep oahd >/dev/null 2>&1; then
      log_info "Rosetta not detected. You may want to install it using:"
      log_info "  softwareupdate --install-rosetta"
    fi
  fi
  
  log_success "Post-installation setup completed."
}

# Main function
main() {
  log_info "Starting Homebrew setup..."
  
  # Install Homebrew
  install_homebrew
  
  # Update Homebrew
  log_info "Updating Homebrew..."
  brew update
  
  # Setup Brewfile
  setup_brewfile
  
  # Install packages
  install_packages
  
  # Run post-installation setup
  post_install_setup
  
  log_success "Homebrew setup completed successfully!"
}

# Execute main function
main 