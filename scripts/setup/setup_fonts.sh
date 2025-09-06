#!/bin/bash
#
# Font installation script
# Installs Nerd Fonts and programming fonts for coding

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
FONTS_DIR="${DOTFILES_DIR}/fonts"
USER_FONTS_DIR="${HOME}/Library/Fonts"
# SYSTEM_FONTS_DIR="/Library/Fonts"  # Currently unused

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

# Detect system type
detect_system() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

# Create font directories if they don't exist
create_font_dirs() {
  log_info "Creating font directories..."
  
  mkdir -p "$FONTS_DIR"
  
  # Create system-specific font directories
  local system
  system=$(detect_system)
  
  if [[ "$system" == "macos" ]]; then
    mkdir -p "$USER_FONTS_DIR"
  else
    log_error "Unsupported system: $system (macOS only)"
    return 1
  fi
  
  log_success "Font directories created successfully."
}

# Download a Nerd Font from GitHub
download_nerd_font() {
  local font_name=$1
  local font_version=${2:-"v3.0.2"}  # Default to v3.0.2 if not specified
  local download_dir="$FONTS_DIR/downloaded"
  
  log_info "Downloading $font_name Nerd Font..."
  
  # Create downloads directory
  mkdir -p "$download_dir"
  
  # Construct the URL
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/${font_name}.zip"
  
  # Download the font
  if curl -fsSL --output "$download_dir/${font_name}.zip" "$url"; then
    log_success "$font_name Nerd Font downloaded successfully."
    return 0
  else
    log_error "Failed to download $font_name Nerd Font."
    return 1
  fi
}

# Extract downloaded fonts
extract_fonts() {
  local download_dir="$FONTS_DIR/downloaded"
  
  # Check if download directory exists
  if [ ! -d "$download_dir" ]; then
    log_warning "No downloaded fonts found."
    return 1
  fi
  
  log_info "Extracting downloaded fonts..."
  
  # Extract all zip files
  for font_zip in "$download_dir"/*.zip; do
    if [ -f "$font_zip" ]; then
      local font_name
      font_name=$(basename "$font_zip" .zip)
      local extract_dir="$FONTS_DIR/extracted/$font_name"
      
      mkdir -p "$extract_dir"
      unzip -q -o "$font_zip" -d "$extract_dir" 
      
      log_success "Extracted $font_name successfully."
    fi
  done
  
  return 0
}

# Install fonts on the system
install_fonts() {
  local extracted_dir="$FONTS_DIR/extracted"
  local system=$(detect_system)
  
  # Check if fonts have been extracted
  if [ ! -d "$extracted_dir" ] || [ -z "$(ls -A "$extracted_dir" 2>/dev/null)" ]; then
    log_warning "No extracted fonts found."
    return 1
  fi
  
  log_info "Installing fonts on the system..."
  
  # Install on macOS
  if [[ "$system" == "macos" ]]; then
    # Copy all .ttf and .otf files to the user's font directory
    find "$extracted_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$USER_FONTS_DIR/" \;
    
    # Clear the font cache
    if command -v atsutil &> /dev/null; then
      atsutil databases -removeUser
      log_info "macOS font cache cleared."
    fi
    
    log_success "Fonts installed successfully on macOS."
  
  else
    log_error "Unsupported operating system: $system (macOS only)"
    return 1
  fi
  
  return 0
}

# Install specific programming fonts
install_programming_fonts() {
  log_info "Installing programming fonts..."
  
  # List of recommended programming fonts
  local fonts=(
    "JetBrainsMono"
    "Hack"
    "FiraCode"
    "Meslo"
    "CascadiaCode"
  )
  
  # Download and install each font
  for font in "${fonts[@]}"; do
    if download_nerd_font "$font"; then
      log_info "$font will be installed."
    else
      log_warning "Skipping $font installation due to download failure."
    fi
  done
  
  # Extract and install the downloaded fonts
  extract_fonts
  install_fonts
  
  log_success "Programming fonts installed successfully."
}

# Clean up temporary font files to save disk space
cleanup() {
  log_info "Cleaning up temporary font files..."
  
  # Ask for confirmation
  read -p "Remove downloaded and extracted font files to save space? [y/N] " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$FONTS_DIR/downloaded"
    rm -rf "$FONTS_DIR/extracted"
    log_success "Temporary font files removed."
  else
    log_info "Temporary font files kept for future use."
  fi
}

# Main function
main() {
  log_info "Starting font installation..."
  
  # Create font directories
  create_font_dirs
  
  # Install programming fonts
  install_programming_fonts
  
  # Clean up
  cleanup
  
  log_success "Font installation completed successfully!"
  log_info "You may need to restart your applications to use the new fonts."
}

# Execute main function
main 