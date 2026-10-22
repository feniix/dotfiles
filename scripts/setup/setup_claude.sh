#!/bin/bash
#
# Claude Code user settings, applied to every profile (~/.claude and each
# ~/.claude-<name> CLAUDE_CONFIG_DIR home).
#
# Claude Code owns and rewrites settings.json, so the files are not linked:
# only the keys below are set, each tracked on its own so uninstall restores
# that key and leaves the rest of the file alone.
#
#   pluginConfigs.cc-plugin-agents-md@builtin.options.instructionFiles
#     = claude-md-and-agents-md: read CLAUDE.md and AGENTS.md together, so a
#     CLAUDE.local.md does not hide a repo's AGENTS.md. Claude Code ignores
#     this key in project settings, hence user settings.

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Log helpers (kept local — setup.sh has its own copies)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${BLUE}[WARN]${NC} $1"; }
if ! declare -F state_init >/dev/null; then
  source "$DOTFILES_DIR/scripts/lib/state.sh"
fi
source "$(dirname "${BASH_SOURCE[0]}")/../lib/claude.sh"
state_init

command -v jq >/dev/null || { log_warning "jq is not installed (it is in the Brewfile)."; exit 1; }

claude_homes
if (( ${#CLAUDE_HOMES[@]} == 0 )); then
  log_info "No Claude Code profiles found; nothing to configure."
  exit 0
fi

for home in "${CLAUDE_HOMES[@]}"; do
  state_json_key "$home/settings.json" \
    '["pluginConfigs","cc-plugin-agents-md@builtin","options","instructionFiles"]' \
    '"claude-md-and-agents-md"'
  log_success "$home: reads CLAUDE.md and AGENTS.md"
done
