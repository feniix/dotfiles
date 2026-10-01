#!/bin/bash
# Reverse tracked changes. Unresolved and optional entries remain retryable.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
source "$DOTFILES_DIR/scripts/lib/state.sh"
source "$DOTFILES_DIR/scripts/lib/defaults.sh"

log_info()    { printf '[INFO] %s\n' "$1"; }
log_success() { printf '[OK] %s\n' "$1"; }
log_warning() { printf '[WARN] %s\n' "$1"; }
log_error()   { printf '[ERROR] %s\n' "$1"; }

DRY_RUN=false REMOVE_SOFTWARE=false RESTORE_DEFAULTS=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --software) REMOVE_SOFTWARE=true ;;
    --defaults) RESTORE_DEFAULTS=true ;;
    --everything) REMOVE_SOFTWARE=true; RESTORE_DEFAULTS=true ;;
    *) log_error "Unknown flag: $arg"; exit 1 ;;
  esac
done
[[ -f "$STATE_MANIFEST" ]] || { log_error "No state manifest at $STATE_MANIFEST"; exit 1; }

run() {
  if [[ "$DRY_RUN" == true ]]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi
}

if [[ "$DRY_RUN" != true ]]; then
  echo "Restore tracked originals and remove owned additions; unresolved backups will be kept."
  read -p "Continue? [y/N] " -n 1 -r
  echo
  [[ "$REPLY" =~ ^[Yy]$ ]] || exit 0
fi

entries=() resolved=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  entries+=("$line")
  resolved+=("false")
done < "$STATE_MANIFEST"

original_for() {
  awk -F '|' -v path="$1" '$1 == "ORIGINAL" && $3 == path {print $4}' "$STATE_MANIFEST"
}

restore_path() {
  local path="$1" backup="$2"
  if [[ "$backup" != ABSENT ]]; then
    [[ -n "$backup" && ( -e "$STATE_BACKUPS/$backup" || -L "$STATE_BACKUPS/$backup" ) ]] ||
      { log_warning "No original backup for $path; keeping state."; return 1; }
  fi
  log_info "Restoring original state: $path"
  run rm -rf "$path" || return 1
  if [[ "$backup" != ABSENT ]]; then
    run mkdir -p "$(dirname "$path")" || return 1
    run cp -a "$STATE_BACKUPS/$backup" "$path" || return 1
  fi
}

undo_managed() {
  local path="$1" expected="$2" backup contents
  backup="$(original_for "$path")"
  [[ -n "$backup" ]] || return 1
  if [[ -e "$path" || -L "$path" ]]; then
    case "$expected" in
      link:*) [[ -L "$path" && "$(readlink "$path")" == "${expected#link:}" ]] || return 1 ;;
      file:*) [[ -f "$path" && ! -L "$path" && "$(_state_file_hash "$path")" == "${expected#file:}" ]] || return 1 ;;
      directory)
        [[ -d "$path" && ! -L "$path" ]] || return 1
        # Refuse to delete user additions or any unresolved child entries.
        contents="$(find "$path" -mindepth 1 -maxdepth 1 -print -quit)" || return 1
        [[ -z "$contents" ]] || return 1
        ;;
      *) return 1 ;;
    esac
  fi
  restore_path "$path" "$backup"
}

undo_legacy_path() {
  local type="$1" path="$2" extra="$3" count
  count="$(awk -F '|' -v path="$path" \
    '$3 == path && $1 ~ /^(SYMLINK|SYMLINK_OVER_FILE|FILE_WRITTEN|FILE_CREATED|FILE_DELETED|FILE_COPIED)$/ {n++} END {print n+0}' \
    "$STATE_MANIFEST")"
  [[ "$count" == 1 ]] || { log_warning "Ambiguous legacy history: $path"; return 1; }
  case "$type" in
    SYMLINK)
      [[ ! -e "$path" && ! -L "$path" ]] && return 0
      [[ -L "$path" && "$(readlink "$path")" == "$extra" ]] || return 1
      run rm "$path"
      ;;
    SYMLINK_OVER_FILE)
      if [[ -e "$path" || -L "$path" ]]; then
        [[ -L "$path" && "$(readlink "$path")" == "$DOTFILES_DIR/"* ]] || return 1
      fi
      restore_path "$path" "$extra"
      ;;
    FILE_CREATED)
      # Old records have no content fingerprint; do not delete user changes.
      [[ ! -e "$path" && ! -L "$path" ]]
      ;;
    *)
      [[ ! -e "$path" && ! -L "$path" ]] || return 1
      restore_path "$path" "$extra"
      ;;
  esac
}

# Run after every DEFAULTS_KEY entry had its turn. A domain with per-key
# records keeps settings osx-defaults never wrote; only legacy domains and
# SNAPSHOT keys (values a key record cannot hold) import the whole snapshot.
undo_defaults_domain() {
  local domain_path="$1" backup="$2" j key_type key_path key_extra
  local keys=() snapshot=false pending=false
  for ((j=0; j<${#entries[@]}; j++)); do
    IFS='|' read -r key_type _ key_path key_extra <<< "${entries[$j]}"
    [[ "$key_type" == DEFAULTS_KEY && "$key_path" == "$domain_path:"* ]] || continue
    keys+=("$j")
    [[ "$key_extra" != SNAPSHOT ]] || snapshot=true
    [[ "${resolved[$j]}" == true ]] || pending=true
  done
  if (( ${#keys[@]} )) && [[ "$snapshot" != true ]]; then
    # Every tracked key is back; the snapshot was only a fallback.
    [[ "$pending" != true ]]
    return
  fi
  defaults_restore_domain "$domain_path" "$backup" || return 1
  for j in "${keys[@]}"; do resolved[$j]=true; done
}

undo_entry() {
  local type="$1" path="$2" extra="$3"
  case "$type" in
    MANAGED) undo_managed "$path" "$extra" ;;
    ORIGINAL) return 1 ;; # consumed with its MANAGED entry
    SYMLINK|SYMLINK_OVER_FILE|FILE_WRITTEN|FILE_CREATED|FILE_DELETED|FILE_COPIED)
      undo_legacy_path "$type" "$path" "$extra"
      ;;
    DIR_CREATED)
      [[ ! -d "$path" ]] || run rmdir "$path"
      ;;
    DIR_EXISTED) return 0 ;;
    DEFAULTS_KEY)
      # Status 2 keeps it quietly: its domain entry reports the retention.
      [[ "$RESTORE_DEFAULTS" == true ]] || return 2
      defaults_restore_key "$path" "$extra"
      ;;
    DEFAULTS_DOMAIN)
      [[ "$RESTORE_DEFAULTS" == true ]] || return 1
      undo_defaults_domain "$path" "$extra"
      ;;
    DEFAULTS_BACKUP)
      log_warning "Legacy all-domain dump at $path cannot be safely imported. Keeping it for manual recovery."
      return 1
      ;;
    BREW_FORMULA|BREW_CASK)
      [[ "$REMOVE_SOFTWARE" == true ]] || return 1
      command -v brew >/dev/null || return 1
      if [[ "$type" == BREW_FORMULA ]]; then
        local installed leaves
        installed="$(brew list --formula)" || return 1
        printf '%s\n' "$installed" | grep -Fxq -- "$path" || return 0
        leaves="$(brew leaves)" || return 1
        printf '%s\n' "$leaves" | grep -Fxq -- "$path" || return 1
        run brew uninstall --formula "$path"
      else
        local casks
        casks="$(brew list --cask)" || return 1
        printf '%s\n' "$casks" | grep -Fxq -- "$path" || return 0
        run brew uninstall --cask "$path"
      fi
      ;;
    MISE_VERSION)
      [[ "$REMOVE_SOFTWARE" == true ]] || return 1
      command -v mise >/dev/null || return 1
      run mise uninstall --yes "$path"
      ;;
    SOFTWARE)
      [[ "$REMOVE_SOFTWARE" == true ]] || return 1
      case "$path" in
        omz)
          [[ "$extra" == "$HOME/.oh-my-zsh" ]] || return 1
          # OMZ's uninstaller also rewrites shell configuration; remove only its directory.
          run rm -rf "$extra"
          ;;
        *) log_warning "Legacy $path record has no ownership inventory; keeping software."; return 1 ;;
      esac
      ;;
    *)
      log_warning "Keeping unsupported/legacy entry: $type ($path)"
      return 1
      ;;
  esac
}

# Defaults domains go last: whether one is imported depends on its keys.
for pass in main domains; do
  for ((i=${#entries[@]}-1; i>=0; i--)); do
    IFS='|' read -r type _ path extra <<< "${entries[$i]}"
    [[ "${resolved[$i]}" == true ]] && continue
    if [[ "$pass" == main ]]; then
      [[ "$type" != DEFAULTS_DOMAIN ]] || continue
    else
      [[ "$type" == DEFAULTS_DOMAIN ]] || continue
    fi
    status=0
    undo_entry "$type" "$path" "$extra" || status=$?
    if [[ "$status" == 0 ]]; then
      resolved[$i]=true
      if [[ "$type" == MANAGED ]]; then
        for ((j=0; j<${#entries[@]}; j++)); do
          IFS='|' read -r other_type _ other_path _ <<< "${entries[$j]}"
          [[ "$other_type" == ORIGINAL && "$other_path" == "$path" ]] && resolved[$j]=true
        done
      fi
    # ORIGINAL is consumed with its MANAGED entry; a deferred key (status 2)
    # is reported or imported with its domain.
    elif [[ "$type" != ORIGINAL && "$type$status" != DEFAULTS_KEY2 ]]; then
      log_warning "Unresolved: $type ($path). Preserving its records and backups."
    fi
  done
done

# Removing an owned dependent may make another owned formula a leaf.
# Retry until there is no progress; never force removal of shared dependencies.
if [[ "$REMOVE_SOFTWARE" == true && "$DRY_RUN" != true ]]; then
  progress=true
  while [[ "$progress" == true ]]; do
    progress=false
    for ((i=${#entries[@]}-1; i>=0; i--)); do
      [[ "${resolved[$i]}" != true ]] || continue
      IFS='|' read -r type _ path extra <<< "${entries[$i]}"
      [[ "$type" == BREW_FORMULA ]] || continue
      if undo_entry "$type" "$path" "$extra"; then
        resolved[$i]=true
        progress=true
      fi
    done
  done
fi

if [[ "$DRY_RUN" != true ]]; then
  remaining=0
  {
    echo "# Dotfiles state manifest — unresolved entries retained"
    for ((i=0; i<${#entries[@]}; i++)); do
      if [[ "${resolved[$i]}" != true ]]; then
        printf '%s\n' "${entries[$i]}"
        remaining=$((remaining + 1))
      fi
    done
  } > "$STATE_MANIFEST.tmp"
  mv "$STATE_MANIFEST.tmp" "$STATE_MANIFEST"
  # A restored path has completed its lifecycle even if optional software or
  # unrelated failures keep the manifest alive. Do not reuse its old baseline.
  for ((i=0; i<${#entries[@]}; i++)); do
    [[ "${resolved[$i]}" == true ]] || continue
    IFS='|' read -r type _ path extra <<< "${entries[$i]}"
    [[ "$type" == ORIGINAL && "$extra" != ABSENT ]] || continue
    if ! awk -F '|' -v backup="$extra" \
      '$4 == backup {found=1} END {exit !found}' "$STATE_MANIFEST"; then
      rm -rf "${STATE_BACKUPS:?}/${extra:?}"
    fi
  done
  if [[ "$remaining" == 0 && ! -d "$STATE_BACKUPS/agent-skills-conflicts" ]]; then
    rm -rf "$STATE_DIR"
  else
    log_warning "Recovery state retained at $STATE_DIR ($remaining pending entries)."
  fi
fi
log_success "Uninstall pass complete."
[[ "$DRY_RUN" != true ]] || log_info "Dry-run: no changes made."
