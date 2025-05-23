#!/bin/bash
# Comprehensive Neovim plugin check

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Checking Neovim Plugin Status${RESET}"
echo -e "${BLUE}=========================================${RESET}"

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
  echo -e "${RED}ERROR: Neovim is not installed. Please install it first.${RESET}"
  exit 1
fi

# Get Neovim version
nvim_version=$(nvim --version | head -n 1)
echo -e "${GREEN}$nvim_version${RESET}"

# Check lazy.nvim installation
echo -e "\n${BLUE}Checking lazy.nvim installation...${RESET}"
lazy_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
if [ -d "$lazy_path" ]; then
  echo -e "${GREEN}✓ lazy.nvim is installed at $lazy_path${RESET}"
else
  echo -e "${YELLOW}! lazy.nvim not found. It will be installed on first Neovim start.${RESET}"
fi

# List installed plugins
echo -e "\n${BLUE}Listing installed plugins:${RESET}"
plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
found_plugins=0
total_plugins=0

# Check lazy directory
if [ -d "$plugin_dir" ]; then
  for plugin in "$plugin_dir"/*; do
    if [ -d "$plugin" ]; then
      name=$(basename "$plugin")
      # Skip the . and .. entries
      if [ "$name" != "." ] && [ "$name" != ".." ]; then
        echo -e "${GREEN}✓ $name${RESET}"
        ((found_plugins++))
        ((total_plugins++))
      fi
    fi
  done
fi

if [ "$found_plugins" -eq 0 ]; then
  echo -e "${YELLOW}! No lazy.nvim plugins found. They may need to be installed.${RESET}"
else
  echo -e "\n${GREEN}✓ Found $total_plugins plugins managed by lazy.nvim${RESET}"
fi

# Check for vim-plug remnants
echo -e "\n${BLUE}Checking for vim-plug remnants...${RESET}"
vimplug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
vimplug_plugins="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged"

if [ -f "$vimplug_path" ]; then
  echo -e "${YELLOW}! vim-plug is still installed at $vimplug_path${RESET}"
  echo -e "${YELLOW}  To remove it, run: rm -f $vimplug_path${RESET}"
else
  echo -e "${GREEN}✓ vim-plug is not installed${RESET}"
fi

if [ -d "$vimplug_plugins" ]; then
  echo -e "${YELLOW}! vim-plug plugins directory still exists at $vimplug_plugins${RESET}"
  echo -e "${YELLOW}  To remove it, run: rm -rf $vimplug_plugins${RESET}"
else
  echo -e "${GREEN}✓ vim-plug plugins directory not found${RESET}"
fi

# Check for Packer remnants
echo -e "\n${BLUE}Checking for Packer remnants...${RESET}"
packer_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/packer"

if [ -d "$packer_path" ]; then
  echo -e "${YELLOW}! Packer directory still exists at $packer_path${RESET}"
  echo -e "${YELLOW}  To remove it, run: rm -rf $packer_path${RESET}"
else
  echo -e "${GREEN}✓ Packer directory not found${RESET}"
fi

# Final verification
if [ "$found_plugins" -gt 0 ] && [ ! -f "$vimplug_path" ] && [ ! -d "$vimplug_plugins" ] && [ ! -d "$packer_path" ]; then
  echo -e "\n${GREEN}✓ Migration to lazy.nvim is complete!${RESET}"
fi

# Show basic instructions to run health checks
echo -e "\n${BLUE}To run detailed health checks:${RESET}"
echo -e "1. Open Neovim: ${GREEN}nvim${RESET}"
echo -e "2. Run the health check command: ${GREEN}:checkhealth user${RESET}"

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${BLUE}Plugin check complete${RESET}"
echo -e "${BLUE}=========================================${RESET}" 