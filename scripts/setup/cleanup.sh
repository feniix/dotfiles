#!/bin/bash
#
# Cleanup script for dotfiles repository
# Removes legacy files that have been moved to the new directory structure

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

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

# Files that have been moved to scripts/setup/
SETUP_FILES=(
  "setup_xdg.sh"
  "setup_macos.sh"
  "setup_nvim.sh"
  "setup_zsh.sh"
)

# Files that have been moved to scripts/macos/
MACOS_FILES=(
  "osx-defaults"
)

# Files that have been moved or are no longer needed
DEPRECATED_FILES=(
  "vimrc"
  "update.sh"
  "create_symlinks.sh"
  "modify_config.sh"
  "fix_treesitter.sh"
  "stripped_init.lua"
  "use_minimal_config.sh"
  "cleanup_nvim.sh"
  "debug_theme.sh"
)

# Directories that are no longer needed
DEPRECATED_DIRS=(
  "history"
)

# Remove setup files that have been moved
remove_setup_files() {
  log_info "Checking for setup files that have been moved to scripts/setup/..."
  
  for file in "${SETUP_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
      if [ -f "$SCRIPTS_DIR/setup/$file" ]; then
        log_info "Removing $file (moved to scripts/setup/)"
        rm "$DOTFILES_DIR/$file"
      else
        log_warning "File $file exists but hasn't been moved to scripts/setup/ yet"
      fi
    fi
  done
  
  log_success "Setup files cleanup completed"
}

# Remove macOS files that have been moved
remove_macos_files() {
  log_info "Checking for macOS files that have been moved to scripts/macos/..."
  
  for file in "${MACOS_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
      if [ -f "$SCRIPTS_DIR/macos/$file" ]; then
        log_info "Removing $file (moved to scripts/macos/)"
        rm "$DOTFILES_DIR/$file"
      else
        log_warning "File $file exists but hasn't been moved to scripts/macos/ yet"
      fi
    fi
  done
  
  log_success "macOS files cleanup completed"
}

# Remove deprecated files
remove_deprecated_files() {
  log_info "Checking for deprecated files..."
  
  for file in "${DEPRECATED_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
      log_info "Removing deprecated file: $file"
      rm "$DOTFILES_DIR/$file"
    fi
    
    # Also check in sbin directory
    if [ -f "$DOTFILES_DIR/sbin/$file" ]; then
      log_info "Removing deprecated file from sbin: $file"
      rm "$DOTFILES_DIR/sbin/$file"
    fi
  done
  
  log_success "Deprecated files cleanup completed"
}

# Remove deprecated directories
remove_deprecated_dirs() {
  log_info "Checking for deprecated directories..."
  
  for dir in "${DEPRECATED_DIRS[@]}"; do
    if [ -d "$DOTFILES_DIR/$dir" ]; then
      log_info "Removing deprecated directory: $dir"
      rm -rf "$DOTFILES_DIR/$dir"
    fi
  done
  
  log_success "Deprecated directories cleanup completed"
}

# Main function
main() {
  log_info "Starting dotfiles cleanup process..."
  
  # Ask for confirmation before proceeding
  read -p "This will remove old files that have been moved to the new directory structure. Continue? [y/N] " -n 1 -r
  echo
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cleanup cancelled."
    exit 0
  fi
  
  # Remove files that have been moved
  remove_setup_files
  remove_macos_files
  
  # Remove deprecated files and directories
  remove_deprecated_files
  remove_deprecated_dirs
  
  log_success "Dotfiles cleanup completed successfully!"
}

# Execute main function
main 