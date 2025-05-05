#!/bin/bash
#
# Setup macOS-specific enhancements
# This script configures macOS-specific settings and key bindings

set -e

echo "Setting up macOS-specific configurations..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This script is only meant to be run on macOS systems."
  exit 1
fi

# Create a basic DefaultKeyBinding.dict for macOS text editing
echo "Setting up macOS key bindings..."
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
  echo "Created macOS DefaultKeyBinding.dict"
fi

# Copy fonts if available
if [ -d "$HOME/dotfiles/fonts" ]; then
  echo "Installing custom fonts..."
  mkdir -p "$HOME/Library/Fonts/"
  cp "$HOME/dotfiles/fonts/"*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
  echo "Fonts installed."
fi

# Apply iTerm2 preferences if available
if [ -f "$HOME/dotfiles/iterm2/com.googlecode.iterm2.plist" ]; then
  echo "Installing iTerm2 preferences..."
  mkdir -p "$HOME/Library/Preferences/"
  cp "$HOME/dotfiles/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/" 2>/dev/null || true
  echo "iTerm2 preferences installed."
  echo "For iTerm2 preferences to take effect, the OS needs to be restarted."
fi

# Apply macOS system defaults if available
if [ -f "$HOME/dotfiles/osx-defaults" ]; then
  echo "Would you like to apply custom macOS system defaults? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Applying saner defaults to macOS, you may be asked for your password..."
    sh "$HOME/dotfiles/osx-defaults"
    echo "macOS defaults applied."
  else
    echo "Skipping macOS defaults."
  fi
fi

echo "macOS-specific setup complete!" 