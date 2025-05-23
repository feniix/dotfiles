#!/bin/bash
# Comprehensive Neovim setup and verification script
# This script sets up Neovim configuration and runs health checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}${BOLD}=========================================${RESET}"
echo -e "${BLUE}${BOLD}Neovim Setup and Health Check${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}ERROR: Neovim is not installed.${RESET}"
    echo -e "${YELLOW}Install it with:${RESET}"
    echo -e "  macOS: ${GREEN}brew install neovim${RESET}"
    echo -e "  Linux: ${GREEN}apt install neovim${RESET} or ${GREEN}pacman -S neovim${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Neovim is installed${RESET}"

# Step 1: Setup Neovim configuration
echo -e "\n${BLUE}Step 1: Setting up Neovim configuration...${RESET}"
if [ -x "$SCRIPT_DIR/../setup/setup_nvim.sh" ]; then
    "$SCRIPT_DIR/../setup/setup_nvim.sh" --install-plugins
    echo -e "${GREEN}✓ Neovim configuration setup complete${RESET}"
else
    echo -e "${YELLOW}! Setup script not found, skipping configuration setup${RESET}"
fi

# Step 2: Run plugin checks
echo -e "\n${BLUE}Step 2: Checking plugin status...${RESET}"
if [ -x "$SCRIPT_DIR/check_plugins.sh" ]; then
    "$SCRIPT_DIR/check_plugins.sh"
else
    echo -e "${RED}✗ Plugin check script not found${RESET}"
fi

# Step 3: Run health checks
echo -e "\n${BLUE}Step 3: Running health checks...${RESET}"
echo -e "${YELLOW}Running comprehensive health check...${RESET}"
nvim --headless -c 'checkhealth user' -c 'quitall' 2>/dev/null || {
    echo -e "${YELLOW}! Health check completed with warnings (check manually with :checkhealth user)${RESET}"
}

# Step 4: Test colorscheme
echo -e "\n${BLUE}Step 4: Testing colorscheme setup...${RESET}"
if [ -x "$SCRIPT_DIR/test_colorbuddy.sh" ]; then
    "$SCRIPT_DIR/test_colorbuddy.sh"
else
    echo -e "${YELLOW}! Colorbuddy test script not found${RESET}"
fi

# Final summary
echo -e "\n${BLUE}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD}Setup Complete!${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

echo -e "\n${GREEN}Your Neovim configuration is now ready to use.${RESET}"
echo -e "\n${YELLOW}Next steps:${RESET}"
echo -e "1. Open Neovim: ${GREEN}nvim${RESET}"
echo -e "2. Run health check: ${GREEN}:checkhealth user${RESET}"
echo -e "3. Install/update plugins: ${GREEN}:Lazy sync${RESET}"
echo -e "4. Toggle theme: ${GREEN}:ToggleTheme${RESET}"

echo -e "\n${YELLOW}Available scripts:${RESET}"
echo -e "• Health check: ${GREEN}$SCRIPT_DIR/health_check.sh${RESET}"
echo -e "• Plugin status: ${GREEN}$SCRIPT_DIR/plugin_status.sh${RESET}"
echo -e "• Full plugin check: ${GREEN}$SCRIPT_DIR/check_plugins.sh${RESET}"
echo -e "• Test colorscheme: ${GREEN}$SCRIPT_DIR/test_colorbuddy.sh${RESET}"

exit 0 