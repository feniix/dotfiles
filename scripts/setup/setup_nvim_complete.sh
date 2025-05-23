#!/bin/bash
#
# Complete Neovim Setup Script
# Integrates with both main setup system and nvim-specific scripts
# This is a bridge script that can be called from the main setup

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log_info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

echo -e "${BLUE}${BOLD}=========================================${RESET}"
echo -e "${BLUE}${BOLD}Complete Neovim Setup${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

# Step 1: Run the basic setup script
log_info "Step 1: Running basic Neovim configuration setup..."
if [ -f "$SCRIPTS_DIR/setup/setup_nvim.sh" ]; then
  bash "$SCRIPTS_DIR/setup/setup_nvim.sh" --install-plugins
  log_success "Basic Neovim setup complete"
else
  log_error "Basic setup script not found at $SCRIPTS_DIR/setup/setup_nvim.sh"
  exit 1
fi

# Step 2: Run comprehensive setup and check if available
log_info "Step 2: Running comprehensive setup and health check..."
if [ -f "$SCRIPTS_DIR/nvim/setup_and_check.sh" ]; then
  bash "$SCRIPTS_DIR/nvim/setup_and_check.sh"
  log_success "Comprehensive setup and health check complete"
else
  log_warning "Comprehensive setup script not found, running manual checks..."
  
  # Manual health check
  if command -v nvim >/dev/null 2>&1; then
    log_info "Running Neovim health check..."
    nvim --headless -c 'checkhealth user' -c 'quitall' 2>/dev/null || log_warning "Some health checks failed"
  fi
fi

# Step 3: Show available management scripts
echo -e "\n${BLUE}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD}Setup Complete!${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

echo -e "\n${GREEN}Your Neovim configuration is ready to use!${RESET}"

if [ -d "$SCRIPTS_DIR/nvim" ]; then
  echo -e "\n${YELLOW}Available Neovim management scripts:${RESET}"
  
  if [ -f "$SCRIPTS_DIR/nvim/nvim_help.sh" ]; then
    echo -e "${GREEN}• Quick help & reference:${RESET} $SCRIPTS_DIR/nvim/nvim_help.sh"
  fi
  
  if [ -f "$SCRIPTS_DIR/nvim/health_check.sh" ]; then
    echo -e "${GREEN}• Health check:${RESET} $SCRIPTS_DIR/nvim/health_check.sh"
  fi
  
  if [ -f "$SCRIPTS_DIR/nvim/check_plugins.sh" ]; then
    echo -e "${GREEN}• Plugin status:${RESET} $SCRIPTS_DIR/nvim/check_plugins.sh"
  fi
  
  if [ -f "$SCRIPTS_DIR/nvim/test_colorbuddy.sh" ]; then
    echo -e "${GREEN}• Test colorscheme:${RESET} $SCRIPTS_DIR/nvim/test_colorbuddy.sh"
  fi
  
  echo -e "\n${YELLOW}For a complete reference, run:${RESET} $SCRIPTS_DIR/nvim/nvim_help.sh"
fi

echo -e "\n${GREEN}Next steps:${RESET}"
echo -e "1. Open Neovim: ${GREEN}nvim${RESET}"
echo -e "2. Check health: ${GREEN}:checkhealth user${RESET}"
echo -e "3. Toggle theme: ${GREEN}:ToggleTheme${RESET}"

exit 0 