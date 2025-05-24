#!/bin/bash
#
# Run Neovim health check in a terminal window
# Provides health status and plugin information

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
RESET='\033[0m'

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

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Neovim Health Check${RESET}"
echo -e "${BLUE}=========================================${RESET}"

echo -e "\n${GREEN}Your Neovim configuration is using lazy.nvim.${RESET}"
echo -e "${GREEN}All plugins are being managed by lazy.nvim.${RESET}"

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
  echo -e "${YELLOW}You can manually check your plugins with:${RESET} nvim -c 'Lazy' -c q"
fi

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${GREEN}Health check complete!${RESET}"
echo -e "${BLUE}=========================================${RESET}"

exit 0 