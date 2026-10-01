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
state_symlink "$DOTFILES_DIR/p10k.zsh" "$XDG_CONFIG_HOME/zsh/.p10k.zsh"
log_success "zshrc, zshenv, p10k.zsh"

# git (reads XDG natively — no ~/.gitconfig needed)
state_mkdir "$XDG_CONFIG_HOME/git"
state_symlink "$DOTFILES_DIR/gitconfig" "$XDG_CONFIG_HOME/git/config"
state_symlink "$DOTFILES_DIR/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"
state_symlink "$DOTFILES_DIR/git_allowed_signers" "$XDG_CONFIG_HOME/git/allowed_signers"
state_symlink "$DOTFILES_DIR/scripts/git/sops-textconv" "$XDG_CONFIG_HOME/git/sops-textconv"
state_delete_file "$HOME/.gitconfig"
log_success "git config, git ignore, allowed signers"

# ssh (doesn't support XDG — use Include)
state_mkdir "$XDG_CONFIG_HOME/ssh"
state_symlink "$DOTFILES_DIR/ssh_config" "$XDG_CONFIG_HOME/ssh/config"
state_mkdir "$HOME/.ssh"
state_mkdir "$HOME/.ssh/controlmasters"
# Other tools (gcloud, OrbStack, VS Code) append hosts here, so only ensure the
# Include is present, ahead of any Host block, instead of owning the file.
SSH_INCLUDE='Include ~/.config/ssh/config'
if [[ -L "$HOME/.ssh/config" ]] ||
  ! grep -Eq '^[[:space:]]*Include[[:space:]]+~/\.config/ssh/config[[:space:]]*$' "$HOME/.ssh/config" 2>/dev/null; then
  SSH_EXISTING="$(cat "$HOME/.ssh/config" 2>/dev/null || true)"
  state_write_file "$HOME/.ssh/config"
  {
    echo "# XDG-compliant SSH configuration"
    echo "$SSH_INCLUDE"
    [[ -z "$SSH_EXISTING" ]] || printf '\n%s\n' "$SSH_EXISTING"
  } > "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  state_finish_file "$HOME/.ssh/config"
fi
log_success "ssh config"

# tmux (in the Brewfile; until now only the unused Home Manager config linked it)
state_mkdir "$XDG_CONFIG_HOME/tmux"
state_symlink "$DOTFILES_DIR/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
log_success "tmux.conf"

# vim
if [ -f "$DOTFILES_DIR/.vimrc" ]; then
  state_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  log_success ".vimrc"
fi

# --- Setup steps ---
# Each step runs as its own process so one failure (a refused mas install, a
# cancelled gh login) cannot stop the rest; failures are summarized at the end.
export DOTFILES_DIR XDG_CONFIG_HOME
FAILED_STEPS=()
run_step() {
  local label="$1"
  shift
  log_info "$label..."
  if ! "$@"; then
    log_warning "$label failed; continuing."
    FAILED_STEPS+=("$label")
  fi
}

# Homebrew first: every later step installs or checks packages with it.
run_step "Setting up Homebrew packages" bash "$SCRIPTS_DIR/setup/setup_homebrew.sh"
# A fresh install only put brew on PATH inside that step's process.
if ! command -v brew >/dev/null; then
  for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew" ]] && eval "$("$brew" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null; then
  echo "Homebrew is not installed; the remaining steps all need it. Fix that and rerun." >&2
  exit 1
fi

run_step "Setting up oh-my-zsh" bash "$SCRIPTS_DIR/setup/setup_zsh.sh"
run_step "Setting up Neovim" bash "$SCRIPTS_DIR/setup/setup_nvim.sh"
run_step "Setting up macOS preferences" bash "$SCRIPTS_DIR/setup/setup_macos.sh"
run_step "Setting up GitHub integration" bash "$SCRIPTS_DIR/setup/setup_github.sh"
run_step "Fixing SSH key permissions" bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" fix-permissions
run_step "Checking the git signing key" bash "$SCRIPTS_DIR/ssh/manage_ssh_keys.sh" signing-key
run_step "Setting up mise" bash "$SCRIPTS_DIR/setup/setup_mise.sh"
run_step "Linking pi user config" bash "$SCRIPTS_DIR/setup/setup_pi.sh"
run_step "Linking shared agent skills and prompts" bash "$SCRIPTS_DIR/setup/setup_agent_skills.sh"

echo ""
if (( ${#FAILED_STEPS[@]} )); then
  log_warning "Setup finished with ${#FAILED_STEPS[@]} failed step(s):"
  printf '  - %s\n' "${FAILED_STEPS[@]}"
  echo "Fix them and rerun ./setup.sh; completed steps are skipped or adopted."
  exit 1
fi
log_success "Dotfiles setup complete! Restart your terminal to apply changes."
