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

# --- Make scripts executable ---
find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "osx-defaults" \) -exec chmod +x {} \;
chmod +x "$DOTFILES_DIR/setup.sh"

# --- XDG directories ---
log_info "Creating XDG directories..."
bash "$SCRIPTS_DIR/setup/setup_xdg.sh"

# --- Symlinks ---
log_info "Creating symlinks..."

# zsh
mkdir -p "$XDG_CONFIG_HOME/zsh"
ln -sf "$DOTFILES_DIR/zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"
ln -sf "$DOTFILES_DIR/zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
log_success "zshrc, zshenv, p10k.zsh"

# git (reads XDG natively — no ~/.gitconfig needed)
mkdir -p "$XDG_CONFIG_HOME/git"
ln -sf "$DOTFILES_DIR/gitconfig" "$XDG_CONFIG_HOME/git/config"
ln -sf "$DOTFILES_DIR/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"
rm -f "$HOME/.gitconfig"
log_success "git config, git ignore"

# ssh (doesn't support XDG — use Include)
mkdir -p "$XDG_CONFIG_HOME/ssh"
ln -sf "$DOTFILES_DIR/ssh_config" "$XDG_CONFIG_HOME/ssh/config"
mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.ssh/controlmasters"
cat > "$HOME/.ssh/config" <<'EOF'
# XDG-compliant SSH configuration
Include ~/.config/ssh/config
EOF
chmod 600 "$HOME/.ssh/config"
log_success "ssh config"

# vim
if [ -f "$DOTFILES_DIR/.vimrc" ]; then
  ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  log_success ".vimrc"
fi

# --- Homebrew (install first — other scripts depend on Homebrew packages) ---
log_info "Setting up Homebrew packages..."
bash "$SCRIPTS_DIR/setup/setup_homebrew.sh"

# --- Oh-My-Zsh ---
log_info "Setting up oh-my-zsh..."
bash "$SCRIPTS_DIR/setup/setup_zsh.sh"

# --- Neovim ---
log_info "Setting up Neovim..."
bash "$SCRIPTS_DIR/setup/setup_nvim.sh"

# --- macOS ---
log_info "Setting up macOS preferences..."
bash "$SCRIPTS_DIR/setup/setup_macos.sh"

# --- GitHub ---
log_info "Setting up GitHub integration..."
bash "$SCRIPTS_DIR/setup/setup_github.sh"

# --- SSH key permissions ---
if [ -f "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" ]; then
  log_info "Fixing SSH key permissions..."
  bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" fix-permissions
fi

# --- mise ---
log_info "Setting up mise..."
bash "$SCRIPTS_DIR/setup/setup_mise.sh"

echo ""
log_success "Dotfiles setup complete! Restart your terminal to apply changes."
