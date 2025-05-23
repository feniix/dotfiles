#!/bin/bash
# Test the NeoSolarized setup in Neovim

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Setting Up NeoSolarized for Neovim${RESET}"
echo -e "${BLUE}=========================================${RESET}"

# First, make sure all plugins are installed
echo -e "\n${YELLOW}Installing plugins with lazy.nvim...${RESET}"
nvim --headless -c "Lazy sync" -c "sleep 3000m" -c "q" > /dev/null 2>&1

echo -e "\n${GREEN}✓ Plugins installation initiated${RESET}"
echo -e "${YELLOW}Wait a few seconds for installation to complete...${RESET}"
sleep 5

# Now show instructions to use NeoSolarized
echo -e "\n${BLUE}NeoSolarized Usage:${RESET}"
echo -e "1. Open Neovim:${RESET} ${GREEN}nvim${RESET}"
echo -e "2. Toggle between light and dark Solarized:${RESET} ${GREEN}:ToggleTheme${RESET}"
echo -e "3. To customize the Solarized theme, edit:${RESET} ${GREEN}~/dotfiles/nvim/lua/user/colorbuddy_setup.lua${RESET}"

echo -e "\n${YELLOW}If you see 'NeoSolarized not found' warning, exit nvim and try again after installation completes.${RESET}"

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${GREEN}NeoSolarized Setup Complete!${RESET}"
echo -e "${BLUE}=========================================${RESET}"

exit 0 