#!/usr/bin/env bash
#
# Vendor third-party skill bundles into the canonical skills directory.
#
# Reads agents/skills.vendor (see that file for the directive format),
# clones or updates each source repo into a local cache, copies the selected
# skill directories into agents/skills, applies renames, and writes the
# resolved commit of every source to agents/skills.lock.
#
# agents/skills is symlinked into pi, Codex and every Claude Code profile by
# scripts/setup/setup_agent_skills.sh, so one run updates all of them. This
# replaces installing the same bundles as Claude plugins, which only Claude
# could see.
#
# Usage:
#   scripts/agents/vendor_skills.sh              update to each source's <ref>
#   scripts/agents/vendor_skills.sh --frozen     use the commits in skills.lock
#   scripts/agents/vendor_skills.sh --dry-run    show what would change
#   scripts/agents/vendor_skills.sh --only <id>  limit to one source id
#
# Afterwards review `git status agents/skills` and commit.

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

DRY_RUN=0 FROZEN=0 ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --frozen)     FROZEN=1 ;;
    --only)       ONLY="$2"; shift ;;
    -h|--help)    sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
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
declare -A LOCKED=()
declare -a PREV_VENDORED=()
if [[ -f "$LOCK" ]]; then
  while read -r id sha _; do
    [[ -z "${id:-}" || "$id" == \#* ]] && continue
    if [[ "$id" == "vendored" ]]; then PREV_VENDORED+=("$sha"); else LOCKED[$id]="$sha"; fi
  done < "$LOCK"
fi
declare -A RESOLVED=()
declare -a NOW_VENDORED=()

# --- Fetch a source, return its checkout dir --------------------------------
checkout_source() {
  local id="$1" url="${SRC_URL[$1]}" ref="${SRC_REF[$1]}" dir="$CACHE/$1" want
  if [[ ! -d "$dir/.git" ]]; then
    log_info "cloning $url"
    git clone --quiet "$url" "$dir"
  else
    git -C "$dir" fetch --quiet --tags origin
  fi
  if [[ "$FROZEN" == 1 && -n "${LOCKED[$id]:-}" ]]; then
    want="${LOCKED[$id]}"
  else
    want="$(git -C "$dir" rev-parse --verify --quiet "origin/$ref" || git -C "$dir" rev-parse --verify --quiet "$ref")" \
      || { log_warning "$id: cannot resolve ref '$ref'"; return 1; }
  fi
  git -C "$dir" checkout --quiet --detach "$want"
  RESOLVED[$id]="$(git -C "$dir" rev-parse HEAD)"
}

# --- Rewrite references after a rename --------------------------------------
# In the given (staged) skill dirs, replace "name: old", /old and `old` with new.
rewrite_refs() {
  local old="$1" new="$2"; shift 2
  local f
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

# --- Main -------------------------------------------------------------------
CHANGED=0
for id in "${SRC_IDS[@]}"; do
  [[ -n "$ONLY" && "$ONLY" != "$id" ]] && continue
  log_info "source $id (${SRC_URL[$id]} @ ${SRC_REF[$id]})"
  checkout_source "$id" || continue
  dir="$CACHE/$id"
  short="${RESOLVED[$id]:0:12}"
  [[ -n "${LOCKED[$id]:-}" && "${LOCKED[$id]}" != "${RESOLVED[$id]}" ]] \
    && log_info "  ${LOCKED[$id]:0:12} -> $short"

  # collect skill dirs matching the globs
  declare -a picked=()
  for g in ${SRC_GLOBS[$id]:-}; do
    for p in "$dir"/$g; do
      [[ -f "$p/SKILL.md" ]] || continue
      picked+=("$p")
    done
  done
  [[ ${#picked[@]} -eq 0 ]] && { log_warning "  no skills matched for $id"; continue; }

  # Stage this source's skills in a temp dir, apply renames there, then diff the
  # staged result against the canonical dir. Comparing against raw upstream would
  # report renamed skills as changed on every run.
  stage="$(mktemp -d "${TMPDIR:-/tmp}/vendor-skills.XXXXXX")"
  declare -a vendored_dirs=() staged_targets=()
  for p in "${picked[@]}"; do
    name="$(basename "$p")"
    case " ${SRC_SKIPS[$id]:-} " in *" $name "*) echo "        skip   $name"; continue ;; esac
    target="$name"
    for r in ${SRC_RENAMES[$id]:-}; do
      [[ "${r%%:*}" == "$name" ]] && target="${r##*:}"
    done
    rsync -a --exclude .DS_Store --exclude .git "$p/" "$stage/$target/"
    staged_targets+=("$target")
  done
  for r in ${SRC_RENAMES[$id]:-}; do
    old="${r%%:*}"; new="${r##*:}"
    [[ ${#staged_targets[@]} -gt 0 ]] && rewrite_refs "$old" "$new" "${staged_targets[@]/#/$stage/}"
  done
  for target in "${staged_targets[@]}"; do
    if [[ -d "$DEST/$target" ]] && diff -rq -x .DS_Store "$stage/$target" "$DEST/$target" >/dev/null 2>&1; then
      echo "        same   $target"
    else
      [[ -d "$DEST/$target" ]] && echo "        update $target" || echo "        add    $target"
      run rsync -a --delete --exclude .DS_Store "$stage/$target/" "$DEST/$target/"
      CHANGED=$((CHANGED + 1))
    fi
    vendored_dirs+=("$DEST/$target")
    NOW_VENDORED+=("$target")
  done
  rm -rf "$stage"
  log_success "  $id @ $short (${#vendored_dirs[@]} skills)"
done

# --- Write lock -------------------------------------------------------------
if [[ "$DRY_RUN" != 1 && -z "$ONLY" ]]; then
  {
    echo "# Resolved commits for agents/skills.vendor — written by scripts/agents/vendor_skills.sh"
    for id in "${SRC_IDS[@]}"; do
      [[ -n "${RESOLVED[$id]:-}" ]] && echo "$id ${RESOLVED[$id]} ${SRC_URL[$id]}"
    done
    echo "# skill dirs in agents/skills that came from the sources above"
    for n in "${NOW_VENDORED[@]}"; do echo "vendored $n"; done
  } > "$LOCK"
elif [[ "$DRY_RUN" != 1 && -n "$ONLY" ]]; then
  log_warning "lock file not rewritten when using --only"
fi

# --- Orphans: vendored last time, not vendored now (removed/renamed upstream) --
if [[ -z "$ONLY" && ${#PREV_VENDORED[@]} -gt 0 ]]; then
  for n in "${PREV_VENDORED[@]}"; do
    case " ${NOW_VENDORED[*]} " in *" $n "*) continue ;; esac
    [[ -d "$DEST/$n" ]] && log_warning "orphan: $DEST/$n was vendored before but no source provides it now; remove or keep by hand"
  done
fi

echo ""
if [[ "$CHANGED" -gt 0 ]]; then
  log_info "$CHANGED skill dir(s) changed. Review and commit:"
  log_info "  git -C $DOTFILES_DIR status --short agents/skills agents/skills.lock"
else
  log_success "all vendored skills already up to date"
fi
