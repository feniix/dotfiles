#!/bin/bash
#
# GitHub integration setup script
# Installs/updates GitHub CLI and authenticates

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if ! declare -F state_init >/dev/null; then
  source "$DOTFILES_DIR/scripts/lib/state.sh"
fi
source "$DOTFILES_DIR/scripts/lib/software.sh"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Install or update GitHub CLI
state_init
log_info "Checking GitHub CLI..."
if command -v gh &>/dev/null; then
  log_success "GitHub CLI installed ($(gh --version | head -n1))"
  software_track_brew_install brew upgrade gh || log_warning "GitHub CLI upgrade failed."
else
  log_info "Installing GitHub CLI..."
  software_track_brew_install brew install gh || { log_error "Failed to install gh"; exit 1; }
  log_success "GitHub CLI installed"
fi

# Configure editor
gh config set editor nvim
state_record "GH_CONFIG" "editor" "nvim"
gh config set pager disabled
state_record "GH_CONFIG" "pager" "disabled"

# Authenticate if needed
if gh auth status &>/dev/null; then
  log_success "Already authenticated with GitHub"
  gh auth status
else
  log_info "Authenticating with GitHub..."
  gh auth login
fi

log_success "GitHub integration setup complete"
