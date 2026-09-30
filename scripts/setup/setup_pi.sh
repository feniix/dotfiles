#!/bin/bash
#
# Pi user-level config setup
# Symlinks ~/.pi/agent/ files and dirs into ~/dotfiles/pi/agent/
# so the dotfiles repo is the single source of truth for user-level pi config.
#
# What gets symlinked (from dotfiles → ~/.pi):
#   agent/settings.json
#   agent/models.json
#   agent/AGENTS.md
#   agent/agents/                (directory — written to by `pi install`)
#   agent/compound-engineering/install-manifest.json
#
# What stays as a real file/dir in ~/.pi:
#   ~/.pi/                       (own git repo, managed by extensions)
#   ~/.pi/agent/auth.json        (secrets — mode 600)
#   ~/.pi/agent/sessions/        (runtime state)
#   ~/.pi/agent/npm/             (installed package code, regenerated)
#   ~/.pi/agent/trust.json       (per-machine)
#   ~/.pi/agent/run-history.jsonl
#   ~/.pi/models/                (extension-managed)
#   ~/.pi/pi-session-manager/    (extension-managed)
#
# Skills and prompts are NOT handled here: agents/skills and agents/prompts
# are linked item-by-item into ~/.pi/agent/ by setup_agent_skills.sh.
#
# Trade-off: when you run `pi install` or `pi update`, files under
# agent/agents/ change inside the dotfiles repo. Commit those changes.

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Log helpers (kept local — setup.sh has its own copies)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
PI_DOTFILES_DIR="$DOTFILES_DIR/pi"
PI_AGENT_DIR="$HOME/.pi/agent"

log_info "Linking pi user config from $PI_DOTFILES_DIR to $PI_AGENT_DIR..."

# --- Parent directories ---
# ~/.pi and ~/.pi/agent are owned by the pi git repo / extensions;
# we don't recreate them if they exist.
state_mkdir "$HOME/.pi"
state_mkdir "$PI_AGENT_DIR"

# agent/agents is a real dir in the dotfiles and pi writes into it
# through the symlink. No separate dir create needed in ~/.pi.

# compound-engineering/ is a subdir under agent/. On a fresh install it
# may not exist yet, but we need the parent before symlinking the
# install-manifest.json file inside it.
state_mkdir "$PI_AGENT_DIR/compound-engineering"

# --- Top-level files ---
state_symlink "$PI_DOTFILES_DIR/agent/settings.json" \
              "$PI_AGENT_DIR/settings.json"
log_success "agent/settings.json"

state_symlink "$PI_DOTFILES_DIR/agent/models.json" \
              "$PI_AGENT_DIR/models.json"
log_success "agent/models.json"

state_symlink "$PI_DOTFILES_DIR/agent/AGENTS.md" \
              "$PI_AGENT_DIR/AGENTS.md"
log_success "agent/AGENTS.md"

# --- Compound engineering install manifest ---
state_symlink "$PI_DOTFILES_DIR/agent/compound-engineering/install-manifest.json" \
              "$PI_AGENT_DIR/compound-engineering/install-manifest.json"
log_success "agent/compound-engineering/install-manifest.json"

# --- Agents directory ---
# Symlinked as a whole. pi writes *.md files into agent/agents/ on
# `pi install`, which through the symlink lands in the dotfiles repo.
state_symlink "$PI_DOTFILES_DIR/agent/agents" \
              "$PI_AGENT_DIR/agents"
log_success "agent/agents/"


log_success "pi user config linked. Run 'pi' to verify."
