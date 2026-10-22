#!/bin/bash
# Claude Code profiles: default home plus any extra CLAUDE_CONFIG_DIR homes
# following the ~/.claude-<name> convention. Only existing homes count, and a
# ~/.claude-* dir counts only if it looks like a profile (Claude Code writes
# settings.json / .claude.json there), so e.g. ~/.claude-backup-* is skipped.
claude_homes() {
  local d
  CLAUDE_HOMES=()
  [[ -d "$HOME/.claude" ]] && CLAUDE_HOMES+=("$HOME/.claude")
  for d in "$HOME"/.claude-*; do
    [[ -d "$d" && ( -f "$d/settings.json" || -f "$d/.claude.json" ) ]] && CLAUDE_HOMES+=("$d")
  done
  return 0
}
