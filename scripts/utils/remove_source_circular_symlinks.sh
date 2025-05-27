#!/bin/bash
#
# Remove Circular Symlinks from Source Directories
# This script specifically removes circular symlinks that may exist within
# the dotfiles source directories themselves

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

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

log_info "🔍 Removing circular symlinks from source directories..."

removed_count=0

# Remove nvim/nvim if it exists
if [ -L "$DOTFILES_DIR/nvim/nvim" ]; then
  log_error "Found circular symlink: $DOTFILES_DIR/nvim/nvim"
  rm -f "$DOTFILES_DIR/nvim/nvim"
  log_success "Removed: nvim/nvim"
  ((removed_count++))
fi

# Remove zsh-completions/zsh-completions if it exists
if [ -L "$DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions" ]; then
  log_error "Found circular symlink: $DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions"
  rm -f "$DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions"
  log_success "Removed: zsh_custom/plugins/zsh-completions/zsh-completions"
  ((removed_count++))
fi

# Find and remove any other circular symlinks within the dotfiles directory
log_info "Scanning for other circular symlinks..."

while IFS= read -r -d '' symlink; do
  if [ -L "$symlink" ]; then
    local target=$(readlink "$symlink")
    local symlink_name=$(basename "$symlink")
    local symlink_relative=${symlink#$DOTFILES_DIR/}
    
    # Check if symlink points back to dotfiles directory with same name
    if [[ "$target" == *"$DOTFILES_DIR"* && "$target" == *"$symlink_name"* ]]; then
      log_error "Found circular symlink: $symlink_relative → $target"
      rm -f "$symlink"
      log_success "Removed: $symlink_relative"
      ((removed_count++))
    fi
  fi
done < <(find "$DOTFILES_DIR" -type l -print0 2>/dev/null)

echo ""
if [ $removed_count -eq 0 ]; then
  log_success "✅ No circular symlinks found in source directories"
else
  log_success "✅ Removed $removed_count circular symlink(s) from source directories"
  log_info "You may want to run the main fix script now:"
  log_info "  ./scripts/utils/fix_circular_symlinks.sh"
fi 