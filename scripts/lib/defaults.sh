#!/bin/bash
# Immutable per-domain snapshots, including the current-host preference scope.

defaults_backup_domain() {
  local domain="$1" scope="${2:-user}" key backup tmp
  local flags=()
  key="$scope:$domain"
  _state_has_entry DEFAULTS_DOMAIN "$key" && return 0
  [[ "$scope" != host ]] || flags=(-currentHost)
  backup="defaults/$(_state_backup_name "$key").plist"
  mkdir -p "$STATE_BACKUPS/defaults" || return 1
  tmp="$STATE_BACKUPS/$backup.tmp"
  # '-' requests XML on stdout, rather than a binary/file-name-dependent export.
  if ! defaults "${flags[@]}" export "$domain" - > "$tmp"; then
    rm -f "$tmp"
    log_warning "Cannot back up $key; refusing to modify it."
    return 1
  fi
  mv "$tmp" "$STATE_BACKUPS/$backup" || return 1
  state_record DEFAULTS_DOMAIN "$key" "$backup"
}

defaults_restore_domain() {
  local key="$1" backup="$2" scope domain
  local flags=()
  scope="${key%%:*}"
  domain="${key#*:}"
  case "$scope" in user) ;; host) flags=(-currentHost) ;; *) return 1 ;; esac
  [[ -f "$STATE_BACKUPS/$backup" ]] || return 1
  run defaults "${flags[@]}" import "$domain" "$STATE_BACKUPS/$backup" || return 1
  log_success "Restored defaults: $key (restart may be needed)"
}
