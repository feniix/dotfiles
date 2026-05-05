#!/bin/bash
#
# Dotfiles Setup Script
# Sets up macOS development environment with XDG Base Directory Specification compliance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "Setting up dotfiles from $DOTFILES_DIR"

# --- State tracking ---
source "$SCRIPTS_DIR/lib/state.sh"
state_init

# --- Make scripts executable ---
find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "osx-defaults" \) -exec chmod +x {} \;
chmod +x "$DOTFILES_DIR/setup.sh"

# --- XDG directories ---
log_info "Creating XDG directories..."
source "$SCRIPTS_DIR/setup/setup_xdg.sh"

# --- Symlinks ---
log_info "Creating symlinks..."

# zsh
state_mkdir "$XDG_CONFIG_HOME/zsh"
state_symlink "$DOTFILES_DIR/zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"
state_symlink "$DOTFILES_DIR/zshenv" "$HOME/.zshenv"
state_symlink "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
log_success "zshrc, zshenv, p10k.zsh"

# git (reads XDG natively — no ~/.gitconfig needed)
state_mkdir "$XDG_CONFIG_HOME/git"
state_symlink "$DOTFILES_DIR/gitconfig" "$XDG_CONFIG_HOME/git/config"
state_symlink "$DOTFILES_DIR/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"
state_symlink "$DOTFILES_DIR/git_allowed_signers" "$XDG_CONFIG_HOME/git/allowed_signers"
state_delete_file "$HOME/.gitconfig"
log_success "git config, git ignore, allowed signers"

# ssh (doesn't support XDG — use Include)
state_mkdir "$XDG_CONFIG_HOME/ssh"
state_symlink "$DOTFILES_DIR/ssh_config" "$XDG_CONFIG_HOME/ssh/config"
state_mkdir "$HOME/.ssh"
state_mkdir "$HOME/.ssh/controlmasters"
state_write_file "$HOME/.ssh/config"
cat > "$HOME/.ssh/config" <<'EOF'
# XDG-compliant SSH configuration
Include ~/.config/ssh/config
EOF
chmod 600 "$HOME/.ssh/config"
log_success "ssh config"

# vim
if [ -f "$DOTFILES_DIR/.vimrc" ]; then
  state_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  log_success ".vimrc"
fi

# --- Homebrew (install first — other scripts depend on Homebrew packages) ---
log_info "Setting up Homebrew packages..."
source "$SCRIPTS_DIR/setup/setup_homebrew.sh"

# --- Oh-My-Zsh ---
log_info "Setting up oh-my-zsh..."
source "$SCRIPTS_DIR/setup/setup_zsh.sh"

# --- Neovim ---
log_info "Setting up Neovim..."
source "$SCRIPTS_DIR/setup/setup_nvim.sh"

# --- macOS ---
log_info "Setting up macOS preferences..."
source "$SCRIPTS_DIR/setup/setup_macos.sh"

# --- GitHub ---
log_info "Setting up GitHub integration..."
source "$SCRIPTS_DIR/setup/setup_github.sh"

# --- SSH key permissions ---
if [ -f "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" ]; then
  log_info "Fixing SSH key permissions..."
  bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" fix-permissions
fi

# --- mise ---
log_info "Setting up mise..."
source "$SCRIPTS_DIR/setup/setup_mise.sh"

echo ""
log_success "Dotfiles setup complete! Restart your terminal to apply changes."
