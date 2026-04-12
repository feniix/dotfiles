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
_STATE_ADOPTING=false

# --- Internal helpers ---

_state_timestamp() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

_state_backup_name() {
  local path="$1"
  echo "${path//\//__}.orig"
}

_state_backup_exists() {
  local path="$1"
  local backup_name
  backup_name="$(_state_backup_name "$path")"
  [[ -f "$STATE_BACKUPS/$backup_name" ]]
}

_state_backup_file() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 1
  fi
  if _state_backup_exists "$path"; then
    # Already have a backup from a previous run — don't overwrite with our own content
    return 0
  fi
  local backup_name
  backup_name="$(_state_backup_name "$path")"
  if [[ -d "$path" ]] && [[ ! -L "$path" ]]; then
    cp -a "$path" "$STATE_BACKUPS/$backup_name"
  else
    cp -a "$path" "$STATE_BACKUPS/$backup_name"
  fi
}

# Check if a manifest entry already exists for a given type+path
_state_has_entry() {
  local type="$1"
  local path="$2"
  [[ -f "$STATE_MANIFEST" ]] && grep -q "^${type}|[^|]*|${path}|" "$STATE_MANIFEST" 2>/dev/null
}

# Remove an existing entry for type+path (for updates on re-run)
_state_remove_entry() {
  local type="$1"
  local path="$2"
  if [[ -f "$STATE_MANIFEST" ]]; then
    local tmp="$STATE_MANIFEST.tmp"
    grep -v "^${type}|[^|]*|${path}|" "$STATE_MANIFEST" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$STATE_MANIFEST"
  fi
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
    _STATE_ADOPTING=true
    touch "$STATE_MANIFEST"
    echo "# Dotfiles state manifest — do not edit manually" > "$STATE_MANIFEST"
    echo "# Format: TYPE|TIMESTAMP|PATH|EXTRA" >> "$STATE_MANIFEST"
    log_warning "No previous state found — adopting existing dotfiles install."
    log_warning "Original pre-dotfiles files cannot be restored."
  fi

  _STATE_INITIALIZED=true
}

# Low-level: append a record to the manifest
state_record() {
  local type="$1"
  local path="$2"
  local extra="${3:-}"

  # Deduplicate: update existing entry rather than appending
  _state_remove_entry "$type" "$path"

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

# Create a symlink. Backs up any existing file/directory at the link path.
state_symlink() {
  local target="$1"
  local link_path="$2"

  # Already a symlink pointing to our target — idempotent, just ensure recorded
  if [[ -L "$link_path" ]] && [[ "$(readlink "$link_path")" == "$target" ]]; then
    if ! _state_has_entry "SYMLINK" "$link_path" && ! _state_has_entry "SYMLINK_OVER_FILE" "$link_path"; then
      state_record "SYMLINK" "$link_path" "$target"
    fi
    return 0
  fi

  # Something exists at link_path — back it up
  if [[ -e "$link_path" ]] || [[ -L "$link_path" ]]; then
    local backup_name
    backup_name="$(_state_backup_name "$link_path")"
    _state_backup_file "$link_path"
    rm -rf "$link_path"
    ln -s "$target" "$link_path"
    state_record "SYMLINK_OVER_FILE" "$link_path" "$backup_name"
    return 0
  fi

  # Nothing exists — fresh symlink
  ln -s "$target" "$link_path"
  state_record "SYMLINK" "$link_path" "$target"
}

# Record that we're about to write/overwrite a file.
# Call this BEFORE the actual write (cat >, echo >, etc.).
state_write_file() {
  local path="$1"

  if [[ -e "$path" ]]; then
    local backup_name
    backup_name="$(_state_backup_name "$path")"
    _state_backup_file "$path"
    state_record "FILE_WRITTEN" "$path" "$backup_name"
  else
    state_record "FILE_CREATED" "$path"
  fi
}

# Delete a file with backup. Replaces bare rm -f.
state_delete_file() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    # Nothing to delete — may be an adopt run where it's already gone
    return 0
  fi

  local backup_name
  backup_name="$(_state_backup_name "$path")"
  _state_backup_file "$path"
  rm -f "$path"
  state_record "FILE_DELETED" "$path" "$backup_name"
}

# Copy a file to a destination, backing up the existing destination.
state_copy_file() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" ]]; then
    local backup_name
    backup_name="$(_state_backup_name "$dest")"
    _state_backup_file "$dest"
    cp "$src" "$dest"
    state_record "FILE_COPIED" "$dest" "$backup_name"
  else
    cp "$src" "$dest"
    state_record "FILE_CREATED" "$dest"
  fi
}
