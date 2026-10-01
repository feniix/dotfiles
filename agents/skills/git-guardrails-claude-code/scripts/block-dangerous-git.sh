#!/bin/bash
#
# Claude Code PreToolUse hook: block destructive git commands.
#
# Patched copy of mattpocock/skills' block-dangerous-git.sh, written by the
# dotfiles' scripts/agents/vendor_skills.sh (edit it there, not here).
# Unlike the upstream grep, it splits the command like a shell would, so
#   git -C . push, git  push, git -c k=v push, "git" push    are caught
#   git commit -m "do not git push"                         is allowed
# and it fails closed (exit 2) when jq is missing or the input is unreadable.
# Plain bash 3.2 (macOS /bin/bash). Git aliases are not expanded.

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: jq is not installed, so the git guardrail hook cannot read the command. Install jq (brew install jq)." >&2
  exit 2
fi

INPUT=$(cat)
if ! COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null); then
  echo "BLOCKED: the git guardrail hook could not parse its input as JSON." >&2
  exit 2
fi
[ -n "$COMMAND" ] || exit 0
export LC_ALL=C

block() {
  echo "BLOCKED: '$COMMAND' $1. The user has prevented you from doing this." >&2
  exit 2
}

# check_git <args after git...>
check_git() {
  local sub="" a del=0 force=0 staged=0 worktree=0 dashdash=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env|--attr-source)
        shift; [ $# -gt 0 ] && shift ;;
      -*) shift ;;
      *) sub="$1"; shift; break ;;
    esac
  done
  case "$sub" in
    push) block "runs git push" ;;
    reset)
      for a in "$@"; do [ "$a" = --hard ] && block "runs git reset --hard"; done ;;
    clean)
      for a in "$@"; do
        case "$a" in
          --dry-run) return 0 ;;
          --*) ;;
          -*n*) return 0 ;;
        esac
      done
      block "runs git clean without --dry-run" ;;
    branch)
      for a in "$@"; do
        case "$a" in
          --delete) del=1 ;;
          --force) force=1 ;;
          --*) ;;
          -*)
            case "$a" in *D*) del=1; force=1 ;; esac
            case "$a" in *d*) del=1 ;; esac
            case "$a" in *f*) force=1 ;; esac ;;
        esac
      done
      [ "$del" = 1 ] && [ "$force" = 1 ] && block "force-deletes a branch" ;;
    checkout)
      for a in "$@"; do
        [ "$dashdash" = 1 ] && block "discards working-tree changes"
        case "$a" in
          --) dashdash=1 ;;
          .|./|:/|*/.) block "discards working-tree changes" ;;
          --force) block "runs git checkout --force" ;;
          --*) ;;
          -*f*) block "runs git checkout -f" ;;
        esac
      done ;;
    restore)
      for a in "$@"; do
        case "$a" in
          --staged) staged=1 ;;
          --worktree) worktree=1 ;;
          --*) ;;
          -*)
            case "$a" in *S*) staged=1 ;; esac
            case "$a" in *W*) worktree=1 ;; esac ;;
        esac
      done
      if [ "$staged" = 0 ] || [ "$worktree" = 1 ]; then
        block "discards working-tree changes with git restore"
      fi ;;
  esac
  return 0
}

# check_segment: inspect one simple command (the words in toks)
check_segment() {
  local n=${#toks[@]} i j t
  i=0
  while [ "$i" -lt "$n" ]; do
    t="${toks[$i]}"
    case "${t##*/}" in
      git)
        check_git "${toks[@]:$((i + 1))}" ;;
      sh|bash|zsh|dash|ksh)
        j=$((i + 1))
        while [ "$j" -lt "$n" ]; do
          case "${toks[$j]}" in
            --*) ;;
            -*c*) [ $((j + 1)) -lt "$n" ] && check_command "${toks[$((j + 1))]}" $((depth + 1)); break ;;
            -*) ;;
            *) break ;;
          esac
          j=$((j + 1))
        done ;;
      eval)
        check_command "${toks[*]:$((i + 1))}" $((depth + 1)) ;;
    esac
    i=$((i + 1))
  done
}

# check_command <string> [depth]: split into simple commands and words,
# honouring quotes and backslashes, and check each command.
check_command() {
  local s="$1" depth="${2:-0}" n i=0 c q="" word="" inword=0
  local -a toks=()
  [ "$depth" -gt 4 ] && return 0
  n=${#s}
  while [ "$i" -lt "$n" ]; do
    c="${s:$i:1}"
    if [ "$q" = "'" ]; then
      if [ "$c" = "'" ]; then q=""; else word="$word$c"; fi
    elif [ "$q" = '"' ]; then
      case "$c" in
        '"') q="" ;;
        '\') i=$((i + 1)); word="$word${s:$i:1}" ;;
        '`') check_command "${s:$((i + 1))}" $((depth + 1)); word="$word$c" ;;
        '$')
          [ "${s:$((i + 1)):1}" = "(" ] && check_command "${s:$((i + 2))}" $((depth + 1))
          word="$word$c" ;;
        *) word="$word$c" ;;
      esac
    else
      case "$c" in
        "'"|'"') q="$c"; inword=1 ;;
        '\') i=$((i + 1)); word="$word${s:$i:1}"; inword=1 ;;
        ' '|$'\t'|'<'|'>')
          [ "$inword" = 1 ] && toks+=("$word"); word=""; inword=0 ;;
        ';'|'&'|'|'|$'\n'|'('|')'|'`')
          [ "$inword" = 1 ] && toks+=("$word"); word=""; inword=0
          [ ${#toks[@]} -gt 0 ] && check_segment
          toks=() ;;
        *) word="$word$c"; inword=1 ;;
      esac
    fi
    i=$((i + 1))
  done
  [ "$inword" = 1 ] && toks+=("$word")
  [ ${#toks[@]} -gt 0 ] && check_segment
  return 0
}

check_command "$COMMAND"
exit 0
