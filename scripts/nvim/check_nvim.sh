#!/bin/bash
#
# Neovim health check — structure, plugins, and legacy cleanup

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
NVIM_DIR="$DOTFILES_DIR/nvim"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${BLUE}Neovim Check${RESET}"
echo "==========================================="

# Check nvim is installed
if ! command -v nvim &>/dev/null; then
  echo -e "${RED}Neovim is not installed${RESET}"
  exit 1
fi
echo -e "${GREEN}OK${RESET} $(nvim --version | head -n1)"

# Check config symlink
echo ""
echo -e "${BLUE}Structure${RESET}"
if [ -L "$XDG_CONFIG_HOME/nvim" ]; then
  target=$(readlink "$XDG_CONFIG_HOME/nvim")
  if [ "$target" = "$NVIM_DIR" ]; then
    echo -e "${GREEN}OK${RESET} $XDG_CONFIG_HOME/nvim -> $NVIM_DIR"
  else
    echo -e "${YELLOW}WARN${RESET} Symlink points to $target (expected $NVIM_DIR)"
  fi
elif [ -d "$XDG_CONFIG_HOME/nvim" ]; then
  echo -e "${YELLOW}WARN${RESET} $XDG_CONFIG_HOME/nvim is a directory, not a symlink"
else
  echo -e "${RED}MISSING${RESET} $XDG_CONFIG_HOME/nvim symlink"
fi

# Check essential files
for file in init.lua lua lazy-lock.json; do
  if [ -e "$NVIM_DIR/$file" ]; then
    echo -e "${GREEN}OK${RESET} $file"
  else
    echo -e "${RED}MISSING${RESET} $file"
  fi
done

# Check for circular symlinks
circular=$(find "$NVIM_DIR" -type l -name "nvim" 2>/dev/null || true)
if [ -n "$circular" ]; then
  echo -e "${RED}CIRCULAR${RESET} Found circular symlinks in nvim dir:"
  echo "$circular"
else
  echo -e "${GREEN}OK${RESET} No circular symlinks"
fi

# Plugins
echo ""
echo -e "${BLUE}Plugins (lazy.nvim)${RESET}"
lazy_path="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
if [ -d "$lazy_path" ]; then
  echo -e "${GREEN}OK${RESET} lazy.nvim installed"
else
  echo -e "${YELLOW}WARN${RESET} lazy.nvim not found (will install on first nvim start)"
fi

plugin_dir="$XDG_DATA_HOME/nvim/lazy"
count=0
if [ -d "$plugin_dir" ]; then
  count=$(find "$plugin_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
fi
echo -e "${GREEN}OK${RESET} $count plugins installed"

# Legacy plugin managers
echo ""
echo -e "${BLUE}Legacy cleanup${RESET}"
for path in \
  "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" \
  "$XDG_DATA_HOME/nvim/plugged" \
  "$XDG_DATA_HOME/nvim/site/pack/packer"; do
  if [ -e "$path" ]; then
    echo -e "${YELLOW}FOUND${RESET} $path (can be removed)"
  fi
done
echo -e "${GREEN}OK${RESET} No legacy plugin managers" 2>/dev/null || true

echo ""
echo "Run :checkhealth user in nvim for detailed diagnostics"
