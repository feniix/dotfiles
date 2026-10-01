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

# Per-key baselines let uninstall undo only the keys osx-defaults wrote,
# leaving later changes to the same domain alone:
#   DEFAULTS_KEY|ts|scope:domain:key|<type>:<base64 value>   (scalar original)
#   DEFAULTS_KEY|ts|scope:domain:key|ABSENT                  (key did not exist)
#   DEFAULTS_KEY|ts|scope:domain:key|SNAPSHOT                (import whole domain)
# SNAPSHOT covers values `defaults write` cannot recreate from text (arrays,
# dicts, data, dates) and domains whose snapshot predates per-key tracking.

defaults_domain_has_keys() {
  local prefix="$1:$2:"
  [[ -f "$STATE_MANIFEST" ]] &&
    awk -F '|' -v prefix="$prefix" \
      '$1 == "DEFAULTS_KEY" && index($3, prefix) == 1 {found=1} END {exit !found}' \
      "$STATE_MANIFEST"
}

# Call before defaults_backup_domain: a snapshot without key records was taken
# by an older install, after which the current values are already ours. Once a
# domain restores via its snapshot, later keys say so too rather than record
# baselines the import would overwrite anyway.
defaults_domain_is_legacy() {
  _state_has_entry DEFAULTS_DOMAIN "$1:$2" || return 1
  ! defaults_domain_has_keys "$1" "$2" ||
    awk -F '|' -v prefix="$1:$2:" \
      '$1 == "DEFAULTS_KEY" && index($3, prefix) == 1 && $4 == "SNAPSHOT" {found=1}
       END {exit !found}' "$STATE_MANIFEST"
}

defaults_record_key() {
  local domain="$1" scope="$2" key="$3" legacy="${4:-false}" path out type extra
  local flags=()
  path="$scope:$domain:$key"
  if [[ "$domain" == *[:\|]* || "$key" == *\|* || "$domain$key" == *$'\n'* ]]; then
    log_warning "Cannot track $path in the manifest; refusing to modify it."
    return 1
  fi
  _state_has_entry DEFAULTS_KEY "$path" && return 0
  case "$scope" in user) ;; host) flags=(-currentHost) ;; *) return 1 ;; esac
  if [[ "$legacy" == true ]]; then
    extra=SNAPSHOT
  elif ! out="$(defaults "${flags[@]}" read-type "$domain" "$key" 2>/dev/null)"; then
    extra=ABSENT
  else
    type="${out#Type is }"
    case "$type" in
      boolean|integer|float|string)
        # Keep a string's own trailing newlines; `defaults read` adds one.
        out="$(defaults "${flags[@]}" read "$domain" "$key" && printf x)" || out=""
        if [[ "$out" == *x ]]; then
          out="${out%x}"
          out="${out%$'\n'}"
          extra="$type:$(printf '%s' "$out" | base64 | tr -d '\n')"
        else
          extra=SNAPSHOT
        fi
        ;;
      *) extra=SNAPSHOT ;;
    esac
  fi
  state_record DEFAULTS_KEY "$path" "$extra"
}

# Returns 2 for SNAPSHOT entries, which only a domain import can restore.
defaults_restore_key() {
  local path="$1" extra="$2" scope rest domain key type value
  local flags=()
  scope="${path%%:*}"
  rest="${path#*:}"
  domain="${rest%%:*}"
  key="${rest#*:}"
  case "$scope" in user) ;; host) flags=(-currentHost) ;; *) return 1 ;; esac
  case "$extra" in
    SNAPSHOT) return 2 ;;
    ABSENT)
      defaults "${flags[@]}" read-type "$domain" "$key" >/dev/null 2>&1 || return 0
      run defaults "${flags[@]}" delete "$domain" "$key" || return 1
      ;;
    *:*)
      type="${extra%%:*}"
      value="$(printf '%s' "${extra#*:}" | base64 --decode && printf x)" || return 1
      value="${value%x}"
      case "$type" in
        boolean) if [[ "$value" == 1 ]]; then value=true; else value=false; fi; type=bool ;;
        integer) type=int ;;
        float|string) ;;
        *) return 1 ;;
      esac
      run defaults "${flags[@]}" write "$domain" "$key" "-$type" "$value" || return 1
      ;;
    *) return 1 ;;
  esac
  log_success "Restored default: $path"
}
