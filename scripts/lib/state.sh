#!/bin/bash
#
# Dotfiles state tracking library
# Records every filesystem side effect so uninstall.sh can reverse them
#
# Usage: source this file from setup scripts, then use state_* functions
# instead of bare mkdir/ln/rm/cp.

STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-state"
STATE_MANIFEST="$STATE_DIR/manifest"
STATE_BACKUPS="$STATE_DIR/backups"

_STATE_INITIALIZED=false
# Outside STATE_DIR so a completed uninstall never deletes the user's copies.
STATE_CONFLICTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-conflicts/setup/$(date -u +%Y%m%dT%H%M%SZ)-$$"

# --- Internal helpers ---

_state_timestamp() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

_state_backup_name() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1 ".orig"}'
}

_state_backup_exists() {
  local path="$1"
  local backup_name
  backup_name="$(_state_backup_name "$path")"
  [[ -e "$STATE_BACKUPS/$backup_name" || -L "$STATE_BACKUPS/$backup_name" ]]
}

_state_backup_file() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return 1
  fi
  if _state_backup_exists "$path"; then
    local existing
    existing="$(_state_backup_name "$path")"
    # Reuse only an active baseline, not an orphan from a completed uninstall.
    if awk -F '|' -v backup="$existing" \
      '$4 == backup {found=1} END {exit !found}' "$STATE_MANIFEST"; then
      return 0
    fi
    # Keep an unreferenced old backup available for manual recovery.
    mv "$STATE_BACKUPS/$existing" "$STATE_BACKUPS/$existing.retired-$(_state_timestamp)-$$" || return 1
  fi
  local backup_name
  backup_name="$(_state_backup_name "$path")"
  cp -a "$path" "$STATE_BACKUPS/$backup_name"
}

# Check if a manifest entry already exists for a given type+path
_state_has_entry() {
  local type="$1"
  local path="$2"
  [[ -f "$STATE_MANIFEST" ]] &&
    AWK_PATH="$path" awk -F '|' -v type="$type" \
      'BEGIN { path = ENVIRON["AWK_PATH"] } $1 == type && $3 == path {found=1} END {exit !found}' "$STATE_MANIFEST"
}

# Remove an existing entry for type+path (for updates on re-run)
_state_remove_entry() {
  local type="$1"
  local path="$2"
  if [[ -f "$STATE_MANIFEST" ]]; then
    # Callers run under `|| return 1`, which disables errexit, so a failed
    # write must not reach the mv or it replaces the manifest with nothing.
    local tmp
    tmp="$(mktemp "$STATE_MANIFEST.XXXXXX")" || return 1
    if ! AWK_PATH="$path" awk -F '|' -v type="$type" \
      'BEGIN { path = ENVIRON["AWK_PATH"] } !($1 == type && $3 == path)' "$STATE_MANIFEST" > "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
    mv -f "$tmp" "$STATE_MANIFEST" || { rm -f "$tmp"; return 1; }
  fi
}

# The baseline is immutable; only MANAGED changes on subsequent setup runs.
# Legacy records without a unique baseline are kept untouched for manual review.
_state_capture_original() {
  local path="$1" adopt_link="${2:-false}" legacy count type backup
  _state_has_entry ORIGINAL "$path" && return 0
  legacy="$(AWK_PATH="$path" awk -F '|' \
    'BEGIN { path = ENVIRON["AWK_PATH"] } $3 == path && $1 ~ /^(SYMLINK|SYMLINK_OVER_FILE|FILE_WRITTEN|FILE_CREATED|FILE_DELETED|FILE_COPIED)$/ {print}' \
    "$STATE_MANIFEST")"
  if [[ -n "$legacy" ]]; then
    count="$(printf '%s\n' "$legacy" | wc -l | tr -d ' ')"
    if [[ "$count" != 1 ]]; then
      log_warning "Ambiguous legacy history for $path — preserving records and backups; resolve manually."
      return 1
    fi
    IFS='|' read -r type _ _ backup <<< "$legacy"
    case "$type" in
      SYMLINK|FILE_CREATED) backup="ABSENT" ;;
      *)
        if [[ ! -e "$STATE_BACKUPS/$backup" && ! -L "$STATE_BACKUPS/$backup" ]]; then
          log_warning "Missing legacy backup for $path — refusing to replace it."
          return 1
        fi
        ;;
    esac
    state_record ORIGINAL "$path" "$backup" || return 1
    _state_remove_entry "$type" "$path" || return 1
  else
    backup="ABSENT"
    if [[ "$adopt_link" != true && ( -e "$path" || -L "$path" ) ]]; then
      _state_backup_file "$path" || return 1
      backup="$(_state_backup_name "$path")"
    fi
    state_record ORIGINAL "$path" "$backup"
  fi
}

# On a rerun the baseline is already captured, so anything at a managed path
# that setup did not leave there is the user's work: move it aside, not away.
_state_set_aside_changes() {
  local path="$1" managed
  _state_has_entry ORIGINAL "$path" || return 0
  [[ -e "$path" || -L "$path" ]] || return 0
  managed="$(AWK_PATH="$path" awk -F '|' \
    'BEGIN { path = ENVIRON["AWK_PATH"] } $1 == "MANAGED" && $3 == path {print $4}' "$STATE_MANIFEST")"
  if [[ -L "$path" ]]; then
    [[ "$managed" == "link:$(readlink "$path")" ]] && return 0
  elif [[ -d "$path" ]]; then
    [[ "$managed" == directory ]] && return 0
  fi
  local dest="$STATE_CONFLICTS_DIR/${path#/}"
  mkdir -p "$(dirname "$dest")" || return 1
  mv "$path" "$dest" || return 1
  log_warning "$path was changed outside setup — moved it to $dest"
}

# Fails (rather than printing an empty hash) when the file cannot be read, so
# an unreadable file is never treated as matching an empty fingerprint.
_state_file_hash() {
  local out
  out="$(shasum -a 256 "$1")" || return 1
  printf '%s\n' "${out%% *}"
}

# --- Public API ---

# Initialize state tracking. Call once at the start of setup.sh.
state_init() {
  if [[ "$_STATE_INITIALIZED" == true ]]; then
    return 0
  fi

  mkdir -p "$STATE_DIR"
  mkdir -p "$STATE_BACKUPS"

  if [[ ! -f "$STATE_MANIFEST" ]]; then
    touch "$STATE_MANIFEST"
    echo "# Dotfiles state manifest — do not edit manually" > "$STATE_MANIFEST"
    echo "# Format: TYPE|TIMESTAMP|PATH|EXTRA" >> "$STATE_MANIFEST"
    # Existing files are backed up before replacement; only paths that already
    # link into dotfiles are adopted without a recoverable original.
    log_warning "Starting state tracking in $STATE_DIR. Paths already linked to dotfiles are adopted as-is; anything else is backed up before it is replaced."
  fi

  _STATE_INITIALIZED=true
}

# Low-level: append a record to the manifest
state_record() {
  local type="$1"
  local path="$2"
  local extra="${3:-}"

  # The manifest is one line of |-separated fields per record.
  if [[ "$path" == *"|"* || "$path" == *$'\n'* ]]; then
    log_warning "Cannot track $path: '|' and newlines are not supported in managed paths."
    return 1
  fi

  # Deduplicate: update existing entry rather than appending
  _state_remove_entry "$type" "$path" || return 1

  echo "${type}|$(_state_timestamp)|${path}|${extra}" >> "$STATE_MANIFEST"
}

# Create a directory. Records whether it already existed or we created it.
# Handles nested paths: walks upward to find the first existing ancestor,
# records DIR_CREATED for each new directory and DIR_EXISTED for existing ones.
state_mkdir() {
  local target="$1"

  # Collect components that need creating
  local to_create=()
  local dir="$target"
  while [[ ! -d "$dir" ]]; do
    to_create=("$dir" "${to_create[@]}")
    dir="$(dirname "$dir")"
  done

  # Record the existing ancestor (unless it's one we already recorded)
  if ! _state_has_entry "DIR_CREATED" "$dir" && ! _state_has_entry "DIR_EXISTED" "$dir"; then
    state_record "DIR_EXISTED" "$dir"
  fi

  # Create and record each new directory
  for d in "${to_create[@]}"; do
    mkdir -p "$d"
    state_record "DIR_CREATED" "$d"
  done

  # If target already existed, ensure it's recorded
  if [[ ${#to_create[@]} -eq 0 ]]; then
    if ! _state_has_entry "DIR_CREATED" "$target" && ! _state_has_entry "DIR_EXISTED" "$target"; then
      state_record "DIR_EXISTED" "$target"
    fi
  fi
}

# Replace a non-directory entry with a real directory, retaining its baseline.
# Uninstall removes it only after managed children are undone and it is empty.
state_replace_with_directory() {
  local path="$1"
  _state_set_aside_changes "$path" || return 1
  _state_capture_original "$path" || return 1
  state_record MANAGED "$path" pending || return 1
  rm -f "$path" || return 1
  mkdir -p "$path" || return 1
  state_record MANAGED "$path" directory
}

# Create a symlink. Backs up any existing file/directory at the link path.
state_symlink() {
  local target="$1"
  local link_path="$2"

  # Existing managed links can be adopted without backing up our own content.
  if [[ -L "$link_path" ]] && [[ "$(readlink "$link_path")" == "$target" ]]; then
    _state_capture_original "$link_path" true || return 1
    state_record MANAGED "$link_path" "link:$target"
    return 0
  fi

  _state_set_aside_changes "$link_path" || return 1
  _state_capture_original "$link_path" || return 1
  state_record MANAGED "$link_path" pending || return 1
  rm -rf "$link_path" || return 1
  ln -s "$target" "$link_path" || return 1
  state_record MANAGED "$link_path" "link:$target"
}

# Record that we're about to write/overwrite a file.
# Call this BEFORE the actual write (cat >, echo >, etc.).
state_write_file() {
  local path="$1"

  _state_capture_original "$path" || return 1
  state_record MANAGED "$path" pending || return 1
  # Never let the caller's redirection write through an original symlink.
  if [[ -L "$path" ]]; then
    rm "$path" || return 1
  elif [[ -d "$path" ]]; then
    log_warning "Refusing to write a file over directory $path"
    return 1
  fi
}

# Call after a successful write to establish which content uninstall owns.
state_finish_file() {
  local path="$1" hash
  [[ -f "$path" && ! -L "$path" ]] || return 1
  hash="$(_state_file_hash "$path")" || return 1
  state_record MANAGED "$path" "file:$hash"
}

# Delete a file with backup. Replaces bare rm -f.
state_delete_file() {
  local path="$1"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    # Nothing to delete — may be an adopt run where it's already gone
    return 0
  fi

  _state_set_aside_changes "$path" || return 1
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    state_record MANAGED "$path" absent
    return 0
  fi
  _state_capture_original "$path" || return 1
  state_record MANAGED "$path" pending || return 1
  rm -f "$path" || return 1
  state_record MANAGED "$path" absent
}

# Copy a file to a destination, backing up the existing destination.
state_copy_file() {
  local src="$1"
  local dest="$2"

  state_write_file "$dest" || return 1
  cp "$src" "$dest" || return 1
  state_finish_file "$dest"
}
