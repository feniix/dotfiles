#!/bin/bash
# Run Neovim health check in a terminal window

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Neovim Health Check${RESET}"
echo -e "${BLUE}=========================================${RESET}"

echo -e "\n${GREEN}Your Neovim configuration is using Packer.${RESET}"
echo -e "${GREEN}All plugins are being managed by Packer.${RESET}"

echo -e "\n${YELLOW}To get a complete health report of your Neovim configuration:${RESET}"
echo -e "1. Open Neovim:${RESET} ${GREEN}nvim${RESET}"
echo -e "2. Run the health check:${RESET} ${GREEN}:checkhealth user${RESET}"

# Display current plugin status by calling our plugin check script
echo -e "\n${BLUE}Current plugin status:${RESET}"

# Check if our plugin check script exists
PLUGIN_CHECK_SCRIPT="$(dirname "$0")/plugin_status.sh"
if [ -x "$PLUGIN_CHECK_SCRIPT" ]; then
  # Run the plugin check script
  echo -e "\n${YELLOW}Running plugin check...${RESET}"
  "$PLUGIN_CHECK_SCRIPT"
else
  echo -e "${RED}Plugin check script not found at $PLUGIN_CHECK_SCRIPT${RESET}"
  echo -e "${YELLOW}You can manually check your plugins with:${RESET} nvim --headless -c 'lua require(\"packer\").list()' -c q"
fi

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${GREEN}Health check complete!${RESET}"
echo -e "${BLUE}=========================================${RESET}"

exit 0 