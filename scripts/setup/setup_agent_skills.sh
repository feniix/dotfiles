#!/bin/bash
#
# Shared agent skills + prompts setup
#
# The dotfiles repo holds the single copy of user-level skills and prompts for
# every coding agent on this machine:
#
#   canonical skills   $DOTFILES_DIR/agents/skills/<name>/
#   canonical prompts  $DOTFILES_DIR/agents/prompts/<name>.md
#
# Each tool keeps its own REAL skills/prompts directory, and every entry inside
# it is a symlink to the canonical item (one link per skill dir / prompt file,
# not one link for the whole directory):
#
#   skills  ->  ~/.pi/agent/skills/<name>       (pi)
#               ~/.agents/skills/<name>         (Codex user scope, Agent Skills standard)
#               ~/.claude/skills/<name>         (Claude Code, default profile)
#               ~/.claude-*/skills/<name>       (Claude Code, extra CLAUDE_CONFIG_DIR profiles)
#
#   prompts ->  ~/.pi/agent/prompts/<name>.md   (pi prompt templates)
#               ~/.codex/prompts/<name>.md      (Codex custom prompts)
#               ~/.claude/commands/<name>.md    (Claude Code slash commands)
#               ~/.claude-*/commands/<name>.md
#
# Per-item links keep tool-managed content (Claude's claude.ai `synced/`
# bucket, plugin caches, etc.) out of dotfiles, and are the documented mode for
# Claude Code. The trade-off: something a tool installs into its own directory
# is NOT in dotfiles until this script runs again. Each run reconciles:
#
#   real entry in a tool dir, not in canonical   -> moved into canonical, linked
#   real entry identical to canonical            -> replaced by a link
#   real entry different from canonical          -> copied to a conflicts dir,
#                                                   then replaced by a link
#   canonical entry missing from a tool dir      -> linked
#   dangling link into canonical (item removed)  -> deleted
#   synced/, .bucket-*, .DS_Store                -> left alone
#
# So the workflow is: install or write a skill anywhere, run this script,
# commit dotfiles.
#
# Plugin-installed skills (Claude marketplaces, pi packages) live in each
# tool's own cache and are intentionally NOT covered here.
#
# Usage:
#   ./scripts/setup/setup_agent_skills.sh [--dry-run]
#   or sourced from setup.sh (set AGENT_SKILLS_DRY_RUN=1 for a dry run)

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN="${AGENT_SKILLS_DRY_RUN:-0}"
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

# --- Log helpers (kept local — setup.sh has its own copies) ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- State tracking (when run standalone rather than sourced from setup.sh) ---
if ! declare -F state_symlink >/dev/null 2>&1; then
  # shellcheck source=../lib/state.sh
  source "$DOTFILES_DIR/scripts/lib/state.sh"
  state_init
fi

if [[ "$DRY_RUN" == 1 ]]; then
  log_warning "DRY RUN — nothing will be changed"
fi

# run <cmd...>: execute, or print when dry-running
run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    echo "        would: $*"
  else
    "$@"
  fi
}

SKILLS_SRC="$DOTFILES_DIR/agents/skills"
PROMPTS_SRC="$DOTFILES_DIR/agents/prompts"
CONFLICTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-conflicts/agent-skills/$(date -u +%Y%m%dT%H%M%SZ)-$$"
CONFLICTS=0
MOVED=0
LINKED=0
PRUNED=0

# --- Targets ---
# Claude Code profiles: default home plus any extra CLAUDE_CONFIG_DIR homes
# following the ~/.claude-<name> convention. Only existing homes are linked.
CLAUDE_HOMES=()
for d in "$HOME/.claude" "$HOME"/.claude-*; do
  [[ -d "$d" ]] && CLAUDE_HOMES+=("$d")
done

SKILL_TARGETS=("$HOME/.pi/agent/skills" "$HOME/.agents/skills")
PROMPT_TARGETS=("$HOME/.pi/agent/prompts")
[[ -d "$HOME/.codex" ]] && PROMPT_TARGETS+=("$HOME/.codex/prompts")
for h in "${CLAUDE_HOMES[@]}"; do
  SKILL_TARGETS+=("$h/skills")
  PROMPT_TARGETS+=("$h/commands")
done

# --- Canonical directories must exist ---
[[ -d "$SKILLS_SRC" ]] || { log_warning "canonical skills dir missing: $SKILLS_SRC"; return 1 2>/dev/null || exit 1; }
if [[ ! -d "$PROMPTS_SRC" ]]; then
  log_info "creating canonical prompts dir $PROMPTS_SRC"
  run mkdir -p "$PROMPTS_SRC"
fi

# ignored_name <name>: tool-managed entries we never touch
ignored_name() {
  case "$1" in
    .DS_Store|synced|.bucket-*|.last-complete-round|manifest.json) return 0 ;;
    .*) return 0 ;;  # any other dotfile/dir
  esac
  return 1
}

# ensure_real_dir <target>
# Make <target> a real directory. Converts the old whole-directory symlink
# layout (or any other symlink) into a real dir; the link is just removed
# because the content it pointed at still lives in canonical.
ensure_real_dir() {
  local target="$1"
  if [[ -L "$target" ]]; then
    log_info "$target is a symlink to $(readlink "$target"); replacing with a real directory"
    run rm "$target"            # removes the link only, never its target
    run mkdir -p "$target"
  elif [[ -e "$target" && ! -d "$target" ]]; then
    log_warning "$target exists and is not a directory; backing up and replacing"
    [[ "$DRY_RUN" == 1 ]] || state_delete_file "$target"
    run mkdir -p "$target"
  elif [[ ! -d "$target" ]]; then
    [[ "$DRY_RUN" == 1 ]] && echo "        would: mkdir -p $target" || state_mkdir "$target"
  fi
}

# absorb <canonical> <target>
# Move real entries of <target> into <canonical> (or set aside conflicts) so
# they can be replaced by links.
absorb() {
  local canonical="$1" target="$2" entry name dest
  local escaped="${target//\//__}"

  for entry in "$target"/* "$target"/.[!.]*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="$(basename "$entry")"
    ignored_name "$name" && continue
    [[ -L "$entry" ]] && continue          # links are handled by link_items/prune
    dest="$canonical/$name"

    if [[ ! -e "$dest" ]]; then
      echo "        move   $name  -> canonical"
      run mv "$entry" "$dest"
      MOVED=$((MOVED + 1))
    elif diff -rq -x .DS_Store "$entry" "$dest" >/dev/null 2>&1; then
      echo "        same   $name  (replaced by link)"
      run rm -rf "$entry"
    else
      echo "        DIFF   $name  -> $CONFLICTS_DIR/$escaped/$name  (canonical wins)"
      run mkdir -p "$CONFLICTS_DIR/$escaped"
      run cp -a "$entry" "$CONFLICTS_DIR/$escaped/$name"
      run rm -rf "$entry"
      CONFLICTS=$((CONFLICTS + 1))
    fi
  done
}

# link_items <canonical> <target>
# One symlink per canonical entry.
link_items() {
  local canonical="$1" target="$2" src name link
  for src in "$canonical"/*; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    ignored_name "$name" && continue
    link="$target/$name"
    if [[ -L "$link" && "$(readlink "$link")" == "$src" ]]; then
      [[ "$DRY_RUN" == 1 ]] || state_symlink "$src" "$link"   # ensure recorded
      continue
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      echo "        would: link $link -> $src"
    else
      state_symlink "$src" "$link"
    fi
    LINKED=$((LINKED + 1))
  done
}

# prune <canonical> <target>
# Remove links that point into canonical but whose target no longer exists.
prune() {
  local canonical="$1" target="$2" entry dest
  for entry in "$target"/*; do
    [[ -L "$entry" ]] || continue
    dest="$(readlink "$entry")"
    [[ "$dest" == "$canonical"/* ]] || continue
    if [[ ! -e "$dest" ]]; then
      echo "        prune  $(basename "$entry")  (dangling -> $dest)"
      run rm "$entry"
      PRUNED=$((PRUNED + 1))
    fi
  done
}

# sync_dir <canonical> <target>
sync_dir() {
  local canonical="$1" target="$2"
  ensure_real_dir "$target"
  if [[ -d "$target" ]]; then
    absorb "$canonical" "$target"
    prune "$canonical" "$target"
  fi
  link_items "$canonical" "$target"
  log_success "$target"
}

# --- Skills ---
log_info "Skills: canonical $SKILLS_SRC"
for t in "${SKILL_TARGETS[@]}"; do
  sync_dir "$SKILLS_SRC" "$t"
done

# --- Prompts / commands ---
log_info "Prompts: canonical $PROMPTS_SRC"
for t in "${PROMPT_TARGETS[@]}"; do
  sync_dir "$PROMPTS_SRC" "$t"
done

# --- pi reads both ~/.pi/agent/skills and ~/.agents/skills natively; both now
# hold links to the same skills, so exclude one or pi finds every skill twice.
# Also exclude Claude's synced/ bucket in case it ever lands next to the links.
PI_EXCLUDES='["!**/.agents/skills/**","!**/synced/**"]'
add_pi_exclusion() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if jq -e --argjson want "$PI_EXCLUDES" '($want - (.skills // [])) == []' "$f" >/dev/null 2>&1; then
    return 0
  fi
  log_info "adding skills exclusions $PI_EXCLUDES to $f"
  if [[ "$DRY_RUN" != 1 ]]; then
    local tmp="$f.tmp.$$"
    jq --indent 2 --argjson want "$PI_EXCLUDES" '.skills = ((.skills // []) + $want | unique)' "$f" > "$tmp"
    state_write_file "$f"
    mv "$tmp" "$f"
    state_finish_file "$f"
  fi
}
if command -v jq >/dev/null 2>&1; then
  add_pi_exclusion "$DOTFILES_DIR/pi/agent/settings.json"
  # If ~/.pi/agent/settings.json is a real file (not yet linked by setup_pi.sh), fix it too.
  if [[ -f "$HOME/.pi/agent/settings.json" && ! -L "$HOME/.pi/agent/settings.json" ]]; then
    add_pi_exclusion "$HOME/.pi/agent/settings.json"
  fi
else
  log_warning "jq not found; add $PI_EXCLUDES to the skills array in pi settings.json by hand"
fi

# --- Summary ---
echo ""
[[ "$LINKED" -gt 0 ]] && log_info "$LINKED link(s) created"
[[ "$PRUNED" -gt 0 ]] && log_info "$PRUNED dangling link(s) removed"
if [[ "$MOVED" -gt 0 ]]; then
  log_info "$MOVED item(s) moved into dotfiles — review and commit: git -C $DOTFILES_DIR status agents"
fi
if [[ "$CONFLICTS" -gt 0 ]]; then
  log_warning "$CONFLICTS item(s) differed from the canonical copy and were set aside in:"
  log_warning "  $CONFLICTS_DIR"
  log_warning "Diff them against $SKILLS_SRC / $PROMPTS_SRC and merge by hand."
fi
log_success "agent skills and prompts linked. Restart pi / Codex / Claude sessions to pick them up."
