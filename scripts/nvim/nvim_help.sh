#!/bin/bash
# Neovim Configuration Quick Reference
# Shows available scripts and common commands

# Colors for output
# RED='\033[0;31m'  # Currently unused
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}${BOLD}=========================================${RESET}"
echo -e "${BLUE}${BOLD}Neovim Configuration Quick Reference${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

echo -e "\n${YELLOW}${BOLD}Available Scripts:${RESET}"
echo -e "${GREEN}• Complete setup:${RESET}      $SCRIPT_DIR/setup_and_check.sh"
echo -e "${GREEN}• Health check:${RESET}        $SCRIPT_DIR/health_check.sh"
echo -e "${GREEN}• Plugin status:${RESET}       $SCRIPT_DIR/plugin_status.sh"
echo -e "${GREEN}• Full plugin check:${RESET}   $SCRIPT_DIR/check_plugins.sh"
echo -e "${GREEN}• Structure check:${RESET}     $SCRIPT_DIR/check_structure.sh"
echo -e "${GREEN}• General structure:${RESET}   ./scripts/utils/check_dotfiles_structure.sh"

echo -e "\n${YELLOW}${BOLD}Quick Setup Commands:${RESET}"
echo -e "${GREEN}• Full setup:${RESET}          ./scripts/nvim/setup_and_check.sh"
echo -e "${GREEN}• Quick health:${RESET}        ./scripts/nvim/health_check.sh"
echo -e "${GREEN}• Check plugins:${RESET}       ./scripts/nvim/check_plugins.sh"

echo -e "\n${YELLOW}${BOLD}Neovim Commands (in nvim):${RESET}"
echo -e "${GREEN}• Health check:${RESET}        :checkhealth user"
echo -e "${GREEN}• Plugin manager:${RESET}      :Lazy"
echo -e "${GREEN}• Install plugins:${RESET}     :Lazy sync"
echo -e "${GREEN}• Update plugins:${RESET}      :Lazy update"
echo -e "${GREEN}• Clean plugins:${RESET}       :Lazy clean"
echo -e "${GREEN}• Toggle theme:${RESET}        :ToggleTheme"
echo -e "${GREEN}• User config check:${RESET}   :UserConfig"

echo -e "\n${YELLOW}${BOLD}Configuration Files:${RESET}"
echo -e "${GREEN}• Main config:${RESET}         ~/.config/nvim/init.lua"
echo -e "${GREEN}• Core settings:${RESET}       ~/.config/nvim/lua/core/"
echo -e "${GREEN}• Plugin specs:${RESET}        ~/.config/nvim/lua/plugins/specs/"
echo -e "${GREEN}• Plugin configs:${RESET}      ~/.config/nvim/lua/plugins/config/"
echo -e "${GREEN}• User overrides:${RESET}      ~/.config/nvim/lua/user/"
echo -e "${GREEN}• Colorscheme:${RESET}         ~/.config/nvim/lua/plugins/config/catppuccin.lua"

echo -e "\n${YELLOW}${BOLD}Common Issues & Solutions:${RESET}"
echo -e "${GREEN}• Plugins not found:${RESET}   Run :Lazy sync in Neovim"
echo -e "${GREEN}• Health check fails:${RESET}  Check :checkhealth user for details"
echo -e "${GREEN}• Theme not working:${RESET}   Check :ToggleTheme command in Neovim"
echo -e "${GREEN}• Config not loaded:${RESET}   Check ~/.config/nvim symlink"
echo -e "${GREEN}• Circular symlinks:${RESET}   Run ./scripts/nvim/check_structure.sh"
echo -e "${GREEN}• Repository issues:${RESET}   Run ./scripts/utils/check_dotfiles_structure.sh"

echo -e "\n${YELLOW}${BOLD}Environment Variables:${RESET}"
echo -e "${GREEN}• Config dir:${RESET}          \$XDG_CONFIG_HOME/nvim (${XDG_CONFIG_HOME:-$HOME/.config}/nvim)"
echo -e "${GREEN}• Data dir:${RESET}            \$XDG_DATA_HOME/nvim (${XDG_DATA_HOME:-$HOME/.local/share}/nvim)"
echo -e "${GREEN}• Cache dir:${RESET}           \$XDG_CACHE_HOME/nvim (${XDG_CACHE_HOME:-$HOME/.cache}/nvim)"

echo -e "\n${BLUE}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD}For more help, see: nvim/lua/user/README.md${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

exit 0 