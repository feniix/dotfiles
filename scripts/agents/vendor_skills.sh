#!/usr/bin/env bash
#
# Vendor third-party skill bundles into the canonical skills directory.
#
# Reads agents/skills.vendor (see that file for the directive format),
# clones or updates each source repo into a local cache, copies the selected
# skill directories into agents/skills, applies renames, and writes the
# commit of every source to agents/skills.lock.
#
# Pinned by default: a source with an entry in skills.lock is used at that
# commit, so applying a skip/rename never pulls new upstream code (which would
# go live at once through the skill symlinks). Only --update re-resolves a
# source's <ref> and moves its pin. A source with no lock entry yet (new, or
# just added to the manifest) resolves its <ref> either way. After changing a
# source's <ref> or URL in the manifest, run --update <id> to apply it.
#
# agents/skills is symlinked into pi, Codex and every Claude Code profile by
# scripts/setup/setup_agent_skills.sh, so one run updates all of them. This
# replaces installing the same bundles as Claude plugins, which only Claude
# could see.
#
# Usage:
#   scripts/agents/vendor_skills.sh               re-apply the manifest at the pinned commits
#   scripts/agents/vendor_skills.sh --update      re-resolve every source's <ref>, move the pins
#   scripts/agents/vendor_skills.sh --update <id> re-resolve that source only
#   scripts/agents/vendor_skills.sh --frozen      pinned commits only; fail if a source has no pin
#   scripts/agents/vendor_skills.sh --dry-run     show what would change
#   scripts/agents/vendor_skills.sh --only <id>   limit to one source id
#
# The manifest is declarative: after a run, agents/skills holds exactly what
# each source provides at its pinned commit. Skills a source provided before but
# no longer does (removed upstream, or you repinned to an older ref, or you
# removed a skill/source line) are DELETED. Only skills recorded in the lock as
# owned by that source are ever deleted; your own skills are never touched.
#
# Afterwards run scripts/setup/setup_agent_skills.sh (links new skills, prunes
# links to deleted ones), review `git status agents` and commit.

set -euo pipefail

# Needs bash >= 4 for associative arrays (macOS /bin/bash is 3.2; brew install bash)
if (( BASH_VERSINFO[0] < 4 )); then
  echo "vendor_skills.sh needs bash 4+; found $BASH_VERSION (try: brew install bash)" >&2
  exit 1
fi

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
MANIFEST="$DOTFILES_DIR/agents/skills.vendor"
LOCK="$DOTFILES_DIR/agents/skills.lock"
DEST="$DOTFILES_DIR/agents/skills"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-vendor-skills"

DRY_RUN=0 FROZEN=0 UPDATE=0 UPDATE_ID="" ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --frozen)     FROZEN=1 ;;
    --update)     UPDATE=1
                  if [[ $# -gt 1 && "$2" != -* ]]; then UPDATE_ID="$2"; shift; fi ;;
    --only)       ONLY="$2"; shift ;;
    -h|--help)    sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
if [[ "$FROZEN" == 1 && "$UPDATE" == 1 ]]; then
  echo "--frozen and --update cannot be combined" >&2; exit 2
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
run() { if [[ "$DRY_RUN" == 1 ]]; then echo "        would: $*"; else "$@"; fi; }

[[ -f "$MANIFEST" ]] || { log_warning "manifest not found: $MANIFEST"; exit 1; }
[[ -d "$DEST" ]] || { log_warning "canonical skills dir not found: $DEST"; exit 1; }
command -v rsync >/dev/null || { log_warning "rsync is required"; exit 1; }
[[ "$DRY_RUN" == 1 ]] && log_warning "DRY RUN — nothing will be changed"
mkdir -p "$CACHE"

# --- Parse manifest ---------------------------------------------------------
declare -a SRC_IDS=()
declare -A SRC_URL=() SRC_REF=() SRC_GLOBS=() SRC_SKIPS=() SRC_RENAMES=()
while read -r kind a b c _; do
  [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
  case "$kind" in
    source) SRC_IDS+=("$a"); SRC_URL[$a]="$b"; SRC_REF[$a]="${c:-main}" ;;
    skill)  SRC_GLOBS[$a]="${SRC_GLOBS[$a]:-} $b" ;;
    skip)   SRC_SKIPS[$a]="${SRC_SKIPS[$a]:-} $b" ;;
    rename) SRC_RENAMES[$a]="${SRC_RENAMES[$a]:-} $b:$c" ;;
    *) log_warning "ignoring unknown directive: $kind $a $b $c" ;;
  esac
done < "$MANIFEST"

# --- Lock file helpers ------------------------------------------------------
# Lock lines:  <id> <sha> <url>          resolved commit per source
#             vendored <id> <name>       skill dir owned by that source
#             vendored <name>            legacy (no owner); never deleted
declare -A LOCKED=() PREV_OWNED=() OWNER=()
declare -a PREV_LEGACY=() LOCK_IDS=()
if [[ -f "$LOCK" ]]; then
  while read -r a b c _; do
    [[ -z "${a:-}" || "$a" == \#* ]] && continue
    if [[ "$a" == "vendored" ]]; then
      if [[ -n "${c:-}" ]]; then PREV_OWNED[$b]="${PREV_OWNED[$b]:-} $c"; OWNER[$c]="$b"; else PREV_LEGACY+=("$b"); fi
    else
      LOCKED[$a]="$b"; LOCK_IDS+=("$a")
    fi
  done < "$LOCK"
fi
declare -A RESOLVED=() NOW_OWNED=() IN_MANIFEST=() NOW_OWNER=()
declare -a NOW_VENDORED=() PROCESSED=()
for id in "${SRC_IDS[@]}"; do IN_MANIFEST[$id]=1; done

# wants_update <id>: true when --update covers this source
wants_update() { [[ "$UPDATE" == 1 && ( -z "$UPDATE_ID" || "$UPDATE_ID" == "$1" ) ]]; }

# --- Fetch a source, return its checkout dir --------------------------------
checkout_source() {
  local id="$1" url="${SRC_URL[$1]}" ref="${SRC_REF[$1]}" dir="$CACHE/$1" want
  if [[ ! -d "$dir/.git" ]]; then
    log_info "cloning $url"
    git clone --quiet "$url" "$dir" || return 1
  else
    # --force: let a tag the upstream moved (a re-tagged release) follow it.
    # The pin in the lock, not the local tag, is what guards against drift.
    git -C "$dir" fetch --quiet --force --tags origin \
      || { log_warning "$id: fetching $url into $dir failed"; return 1; }
  fi
  if [[ -n "${LOCKED[$id]:-}" ]] && ! wants_update "$id"; then
    want="${LOCKED[$id]}"
    log_info "  pinned at ${want:0:12} (--update $id follows $ref)"
  elif [[ "$FROZEN" == 1 ]]; then
    log_warning "$id: no pinned commit in $LOCK and --frozen given"; return 1
  else
    want="$(git -C "$dir" rev-parse --verify --quiet "origin/$ref" || git -C "$dir" rev-parse --verify --quiet "$ref")" \
      || { log_warning "$id: cannot resolve ref '$ref'"; return 1; }
  fi
  git -C "$dir" checkout --quiet --detach "$want" || return 1
  RESOLVED[$id]="$(git -C "$dir" rev-parse HEAD)" || return 1
}

# --- Rewrite references after a rename --------------------------------------
# In the given (staged) skill dirs, replace "name: old", /old and `old` with new.
# Only *.md and *.txt files are rewritten (see agents/skills.vendor).
rewrite_refs() {
  local old new f
  # Escape the names for an ERE pattern / sed replacement (# is the delimiter),
  # so e.g. a "." in a skill name only matches a literal dot.
  old="$(printf '%s' "$1" | sed 's/[][\.*^$+?(){}|#]/\\&/g')"
  new="$(printf '%s' "$2" | sed 's/[\&#]/\\&/g')"
  shift 2
  for d in "$@"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do
      if grep -q -E "(^name: ${old}\$|/${old}([^a-z0-9-]|\$)|\`${old}\`)" "$f"; then
        sed -i.vendor-bak -E \
          -e "s#^name: ${old}\$#name: ${new}#" \
          -e "s#/${old}([^a-z0-9-]|\$)#/${new}\1#g" \
          -e "s#\`${old}\`#\`${new}\`#g" "$f"
        rm -f "$f.vendor-bak"
      fi
    done < <(find "$d" -type f \( -name '*.md' -o -name '*.txt' \) -print0)
  done
}

# --- Local patches ----------------------------------------------------------
# Vendored skills are otherwise copied verbatim; these run on the staged copy,
# so they survive every re-vendor.

# mattpocock/git-guardrails-claude-code ships a PreToolUse hook that greps the
# raw command string: `git -C . push`, `git  push`, `git clean -xdf`,
# `git branch --delete --force` and `git checkout -- .` get through, a commit
# message mentioning "git push" is blocked, and it fails open without jq.
# Replace it with a tokenizing version. The hash is the upstream script the
# replacement was written against (v1.2.3); a mismatch means upstream changed
# it and the replacement should be reviewed.
GUARDRAILS_UPSTREAM_SHA256=234922b83c0a1737ee7300806c21ac0f389b07aaeb65c2d71ccedafbc5e1ea4b
guardrail_hook() {
  cat <<'GUARDRAIL_HOOK'
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
GUARDRAIL_HOOK
}
# patch_git_guardrails <staged skill dir>
patch_git_guardrails() {
  local f="$1/scripts/block-dangerous-git.sh" sum
  if [[ ! -f "$f" ]]; then
    log_warning "  $f not found upstream; git guardrail hook left unpatched"
    return 0
  fi
  sum="$(shasum -a 256 "$f" | cut -d' ' -f1)"
  [[ "$sum" == "$GUARDRAILS_UPSTREAM_SHA256" ]] \
    || log_warning "  upstream block-dangerous-git.sh changed; review guardrail_hook in $0 against it"
  guardrail_hook > "$f"
  chmod 755 "$f"
  echo "        patch  $(basename "$1")/scripts/block-dangerous-git.sh"
}

# --- Ownership -------------------------------------------------------------
# clash_with <id> <name>: print who else holds agents/skills/<name>, if anyone.
# A source may only write a dir the lock says it owns, or a name nobody holds.
# Anything else (a first-party skill, a legacy unowned entry, or a dir owned
# by another source) is left alone.
clash_with() {
  local id="$1" name="$2" owner
  owner="${NOW_OWNER[$name]:-}"
  if [[ -n "$owner" && "$owner" != "$id" ]]; then
    echo "source $owner (vendored earlier in this run)"; return
  fi
  owner="${OWNER[$name]:-}"
  if [[ -n "$owner" && "$owner" != "$id" ]]; then
    echo "source $owner (per $LOCK)"; return
  fi
  if [[ -z "$owner" && -e "$DEST/$name" ]]; then
    echo "a first-party skill (not owned by any source in $LOCK)"
  fi
}

# --- Main -------------------------------------------------------------------
CHANGED=0 CLASHES=0
for id in "${SRC_IDS[@]}"; do
  [[ -n "$ONLY" && "$ONLY" != "$id" ]] && continue
  log_info "source $id (${SRC_URL[$id]} @ ${SRC_REF[$id]})"
  checkout_source "$id" || exit 1
  dir="$CACHE/$id"
  short="${RESOLVED[$id]:0:12}"
  [[ -n "${LOCKED[$id]:-}" && "${LOCKED[$id]}" != "${RESOLVED[$id]}" ]] \
    && log_info "  ${LOCKED[$id]:0:12} -> $short"

  # collect skill dirs matching the globs
  # Split the glob list with globbing off, so a pattern can only expand
  # against the clone below, never against the current directory.
  declare -a picked=() globs=()
  set -f; read -r -a globs <<< "${SRC_GLOBS[$id]:-}"; set +f
  for g in "${globs[@]}"; do
    for p in "$dir"/$g; do
      [[ -f "$p/SKILL.md" ]] || continue
      picked+=("$p")
    done
  done
  if [[ ${#picked[@]} -eq 0 && -n "${SRC_GLOBS[$id]:-}" ]]; then
    log_warning "  no skills matched for $id; refusing to change ownership or the lock"
    exit 1
  fi
  # No skill directives (or skipping all matches below) explicitly selects
  # nothing. Process that empty result so old owned entries are removed.

  # Stage this source's skills in a temp dir, apply renames there, then diff the
  # staged result against the canonical dir. Comparing against raw upstream would
  # report renamed skills as changed on every run.
  stage="$(mktemp -d "${TMPDIR:-/tmp}/vendor-skills.XXXXXX")"
  declare -a vendored_dirs=() staged_targets=()
  guardrails=""
  for p in "${picked[@]}"; do
    name="$(basename "$p")"
    case " ${SRC_SKIPS[$id]:-} " in *" $name "*) echo "        skip   $name"; continue ;; esac
    target="$name"
    for r in ${SRC_RENAMES[$id]:-}; do
      [[ "${r%%:*}" == "$name" ]] && target="${r##*:}"
    done
    rsync -a --exclude .DS_Store --exclude .git "$p/" "$stage/$target/"
    staged_targets+=("$target")
    [[ "$id" == mattpocock && "$name" == git-guardrails-claude-code ]] && guardrails="$target"
  done
  for r in ${SRC_RENAMES[$id]:-}; do
    old="${r%%:*}"; new="${r##*:}"
    [[ ${#staged_targets[@]} -gt 0 ]] && rewrite_refs "$old" "$new" "${staged_targets[@]/#/$stage/}"
  done
  [[ -n "$guardrails" ]] && patch_git_guardrails "$stage/$guardrails"
  for target in "${staged_targets[@]}"; do
    other="$(clash_with "$id" "$target")"
    if [[ -n "$other" ]]; then
      echo -e "        ${RED}CLASH${NC}  $target: $id wants $DEST/$target, which belongs to $other; left untouched" >&2
      CLASHES=$((CLASHES + 1))
      continue
    fi
    NOW_OWNER[$target]="$id"
    if [[ -d "$DEST/$target" ]] && diff -rq -x .DS_Store "$stage/$target" "$DEST/$target" >/dev/null 2>&1; then
      echo "        same   $target"
    else
      [[ -d "$DEST/$target" ]] && echo "        update $target" || echo "        add    $target"
      # --checksum: a same-size edit within the same second as the last copy
      # would otherwise be skipped by rsync's size+mtime check
      run rsync -a --checksum --delete --exclude .DS_Store "$stage/$target/" "$DEST/$target/"
      CHANGED=$((CHANGED + 1))
    fi
    vendored_dirs+=("$DEST/$target")
    NOW_VENDORED+=("$target")
    NOW_OWNED[$id]="${NOW_OWNED[$id]:-} $target"
  done
  PROCESSED+=("$id")
  rm -rf "$stage"
  log_success "  $id @ $short (${#vendored_dirs[@]} skills)"
done

# --- Remove skills a source no longer provides -------------------------------
# Candidates: skills owned by a processed source that it did not produce this
# run, plus (full runs only) everything owned by a source dropped from the
# manifest. Never delete a name some source produced this run.
REMOVED=0
remove_owned() {
  local id="$1" why="$2" n
  for n in ${PREV_OWNED[$id]:-}; do
    case " ${NOW_OWNED[$id]:-} " in *" $n "*) continue ;; esac
    case " ${NOW_VENDORED[*]:-} " in *" $n "*) continue ;; esac
    [[ -d "$DEST/$n" ]] || continue
    echo "        remove $n  ($why)"
    run rm -rf "${DEST:?}/$n"
    REMOVED=$((REMOVED + 1))
  done
}
for id in "${PROCESSED[@]}"; do
  remove_owned "$id" "no longer provided by $id @ ${SRC_REF[$id]}"
done
if [[ -z "$ONLY" ]]; then
  for id in "${LOCK_IDS[@]}"; do
    [[ -n "${IN_MANIFEST[$id]:-}" ]] || remove_owned "$id" "source $id removed from manifest"
  done
  # legacy entries (no recorded owner): warn only
  for n in "${PREV_LEGACY[@]}"; do
    case " ${NOW_VENDORED[*]:-} " in *" $n "*) continue ;; esac
    [[ -d "$DEST/$n" ]] && log_warning "unowned: $DEST/$n came from an older lock without an owner; remove or keep by hand"
  done
fi

# --- Write lock -------------------------------------------------------------
# Processed sources get their new commit and skill list; with --only, the
# other sources keep what the old lock said.
if [[ "$DRY_RUN" != 1 ]]; then
  {
    echo "# Resolved commits for agents/skills.vendor — written by scripts/agents/vendor_skills.sh"
    for id in "${SRC_IDS[@]}"; do
      sha="${RESOLVED[$id]:-${LOCKED[$id]:-}}"
      [[ -n "$sha" ]] && echo "$id $sha ${SRC_URL[$id]}"
    done
    echo "# skill dirs in agents/skills and the source that owns them"
    for id in "${SRC_IDS[@]}"; do
      if [[ -n "${RESOLVED[$id]:-}" ]]; then owned="${NOW_OWNED[$id]:-}"; else owned="${PREV_OWNED[$id]:-}"; fi
      for n in $owned; do echo "vendored $id $n"; done
    done
  } > "$LOCK"
fi

echo ""
if [[ "$CHANGED" -gt 0 || "$REMOVED" -gt 0 ]]; then
  log_info "$CHANGED skill dir(s) added/updated, $REMOVED removed."
  log_info "Next: scripts/setup/setup_agent_skills.sh   (link new skills, prune removed ones)"
  log_info "Then review and commit:"
  log_info "  git -C $DOTFILES_DIR status --short agents/skills agents/skills.lock"
else
  log_success "all vendored skills already up to date"
fi
if [[ "$CLASHES" -gt 0 ]]; then
  echo -e "${RED}[ERROR]${NC} $CLASHES vendored skill(s) clash with an existing skill of the same name and were skipped." >&2
  echo -e "${RED}[ERROR]${NC} Resolve each with a rename/skip line in $MANIFEST, then re-run." >&2
  exit 1
fi
