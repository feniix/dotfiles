#!/bin/bash
#
# Fix Circular Symlinks Utility
# Detects and fixes circular symlinks that may have been created during setup

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

# Function to check if a symlink is circular
is_circular_symlink() {
  local link_path="$1"
  
  if [ ! -L "$link_path" ]; then
    return 1  # Not a symlink
  fi
  
  # Get the target of the symlink
  local target=$(readlink "$link_path")
  
  # Check if the target contains the link name (potential circular reference)
  if [[ "$target" == *"@$(basename "$link_path")"* ]]; then
    return 0  # Circular symlink detected
  fi
  
  # Check if the symlink points to a non-existent target
  if [ ! -e "$link_path" ]; then
    return 0  # Broken symlink (might be circular)
  fi
  
  return 1  # Not circular
}

# Function to fix a circular symlink
fix_circular_symlink() {
  local link_path="$1"
  local correct_target="$2"
  
  log_warning "Fixing circular symlink: $link_path"
  
  # Remove the broken symlink
  rm -f "$link_path"
  
  # Create the correct symlink
  if [ -e "$correct_target" ]; then
    ln -sf "$(realpath "$correct_target")" "$link_path"
    log_success "Fixed: $link_path → $correct_target"
  else
    log_error "Cannot fix $link_path: target $correct_target does not exist"
    return 1
  fi
}

# Main function
main() {
  log_info "🔍 Checking for circular symlinks in dotfiles setup..."
  
  local issues_found=0
  
  # First, check for circular symlinks within source directories
  log_info "Checking for circular symlinks within source directories..."
  
  # Check for nvim/nvim circular symlink
  if [ -L "$DOTFILES_DIR/nvim/nvim" ]; then
    log_error "Circular symlink detected within source: $DOTFILES_DIR/nvim/nvim"
    rm -f "$DOTFILES_DIR/nvim/nvim"
    log_success "Removed circular symlink: $DOTFILES_DIR/nvim/nvim"
    ((issues_found++))
  fi
  
  # Check for zsh-completions/zsh-completions circular symlink
  if [ -L "$DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions" ]; then
    log_error "Circular symlink detected within source: $DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions"
    rm -f "$DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions"
    log_success "Removed circular symlink: $DOTFILES_DIR/zsh_custom/plugins/zsh-completions/zsh-completions"
    ((issues_found++))
  fi
  
  # General check for any symlinks within dotfiles directory that point back to themselves
  log_info "Scanning for other circular symlinks within dotfiles directory..."
  while IFS= read -r -d '' symlink; do
    local target=$(readlink "$symlink")
    local symlink_name=$(basename "$symlink")
    
    # Check if symlink points to a path containing the dotfiles directory and the same name
    if [[ "$target" == *"$DOTFILES_DIR"* && "$target" == *"$symlink_name"* ]]; then
      log_error "Circular symlink detected: $symlink → $target"
      rm -f "$symlink"
      log_success "Removed circular symlink: $symlink"
      ((issues_found++))
    fi
  done < <(find "$DOTFILES_DIR" -type l -print0 2>/dev/null)
  
  # Check nvim configuration
  local nvim_config="$XDG_CONFIG_HOME/nvim"
  local nvim_source="$DOTFILES_DIR/nvim"
  
  if is_circular_symlink "$nvim_config"; then
    log_error "Circular symlink detected: $nvim_config"
    if fix_circular_symlink "$nvim_config" "$nvim_source"; then
      ((issues_found++))
    fi
  elif [ -L "$nvim_config" ] && [ -e "$nvim_config" ]; then
    log_success "nvim configuration symlink is correct"
  elif [ -d "$nvim_source" ]; then
    log_warning "nvim configuration not linked. Creating symlink..."
    ln -sf "$(realpath "$nvim_source")" "$nvim_config"
    log_success "Created nvim symlink"
  fi
  
  # Check zsh-completions plugin
  local omz_custom="$HOME/.oh-my-zsh/custom"
  local zsh_completions_link="$omz_custom/plugins/zsh-completions"
  local zsh_completions_source="$DOTFILES_DIR/zsh_custom/plugins/zsh-completions"
  
  if is_circular_symlink "$zsh_completions_link"; then
    log_error "Circular symlink detected: $zsh_completions_link"
    if fix_circular_symlink "$zsh_completions_link" "$zsh_completions_source"; then
      ((issues_found++))
    fi
  elif [ -L "$zsh_completions_link" ] && [ -e "$zsh_completions_link" ]; then
    log_success "zsh-completions plugin symlink is correct"
  elif [ -d "$zsh_completions_source" ]; then
    log_warning "zsh-completions plugin not linked. Creating symlink..."
    mkdir -p "$(dirname "$zsh_completions_link")"
    ln -sf "$(realpath "$zsh_completions_source")" "$zsh_completions_link"
    log_success "Created zsh-completions symlink"
  fi
  
  # Note: Custom themes are managed in zshrc, not as symlinks
  
  # Summary
  echo ""
  if [ $issues_found -eq 0 ]; then
    log_success "✅ No circular symlinks found. All symlinks are correct!"
  else
    log_success "✅ Fixed $issues_found circular symlink(s)"
    log_info "You may need to restart your shell or reload configurations"
  fi
  
  # Show current symlink status
  echo ""
  log_info "📋 Current symlink status:"
  
  if [ -L "$nvim_config" ]; then
    echo "  nvim: $nvim_config → $(readlink "$nvim_config")"
  else
    echo "  nvim: Not linked"
  fi
  
  if [ -L "$zsh_completions_link" ]; then
    echo "  zsh-completions: $zsh_completions_link → $(readlink "$zsh_completions_link")"
  else
    echo "  zsh-completions: Not linked"
  fi
}

# Run the main function
main "$@" 