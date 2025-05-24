#!/bin/bash
#
# Setup macOS-specific enhancements
# This script configures macOS-specific settings and key bindings

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

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

log_info "Setting up macOS-specific configurations..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  log_error "This script is only meant to be run on macOS systems."
  exit 1
fi

# Create a basic DefaultKeyBinding.dict for macOS text editing
log_info "Setting up macOS key bindings..."
mkdir -p "$HOME/Library/KeyBindings"
if [ ! -f "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" ]; then
  cat > "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" << 'EOF'
{
    /* Remap Home / End to be correct */
    "\UF729"  = "moveToBeginningOfLine:";                   /* Home         */
    "\UF72B"  = "moveToEndOfLine:";                         /* End          */
    "$\UF729" = "moveToBeginningOfLineAndModifySelection:"; /* Shift + Home */
    "$\UF72B" = "moveToEndOfLineAndModifySelection:";       /* Shift + End  */
    
    /* Option+Left/Right for word movement */
    "~\UF702" = "moveWordLeft:";                            /* Option + Left */
    "~\UF703" = "moveWordRight:";                           /* Option + Right */
    "~$\UF702" = "moveWordLeftAndModifySelection:";         /* Shift + Option + Left */
    "~$\UF703" = "moveWordRightAndModifySelection:";        /* Shift + Option + Right */
}
EOF
  log_success "Created macOS DefaultKeyBinding.dict"
fi

# Copy fonts if available
if [ -d "$DOTFILES_DIR/fonts" ]; then
  log_info "Installing custom fonts..."
  mkdir -p "$HOME/Library/Fonts/"
  cp "$DOTFILES_DIR/fonts/"*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
  log_success "Fonts installed."
fi

# Apply iTerm2 preferences if available
if [ -f "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" ]; then
  log_info "Installing iTerm2 preferences..."
  mkdir -p "$HOME/Library/Preferences/"
  cp "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/" 2>/dev/null || true
  log_success "iTerm2 preferences installed."
  log_warning "For iTerm2 preferences to take effect, the OS needs to be restarted."
fi

# Apply macOS system defaults if available
if [ -f "$DOTFILES_DIR/osx-defaults" ]; then
  read -p "Would you like to apply custom macOS system defaults? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Applying saner defaults to macOS, you may be asked for your password..."
    sh "$DOTFILES_DIR/osx-defaults"
    log_success "macOS defaults applied."
  else
    log_info "Skipping macOS defaults."
  fi
fi

log_success "macOS-specific setup complete!" 