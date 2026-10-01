#!/bin/bash
# Inventory software at CLI boundaries; partial installs are owned too.

software_record_additions() {
  local type="$1" before="$2" after="$3" added="$3.added" item
  LC_ALL=C comm -13 "$before" "$after" > "$added" || return 1
  while IFS= read -r item; do
    [[ -z "$item" ]] || state_record "$type" "$item" || return 1
  done < "$added"
}

software_brew_inventory() {
  local kind="$1" output="$2"
  brew list "--$kind" > "$output.raw" || return 1
  LC_ALL=C sort -u "$output.raw" > "$output"
}

# A run killed mid-install (Ctrl-C during brew bundle) leaves its before-
# snapshot behind. Diff it against today's inventory first, or the additions
# land in the next run's before-snapshot and are never recorded as ours.
software_recover_interrupted() {
  local kind="$1" snapshot
  [[ -f "$STATE_MANIFEST" ]] || return 0
  while IFS= read -r snapshot; do
    [[ -n "$snapshot" ]] || continue
    if [[ "$kind" == brew && -f "$snapshot/formula.before" && -f "$snapshot/cask.before" ]]; then
      software_brew_inventory formula "$snapshot/formula.after" || return 1
      software_brew_inventory cask "$snapshot/cask.after" || return 1
      software_record_additions BREW_FORMULA "$snapshot/formula.before" "$snapshot/formula.after" || return 1
      software_record_additions BREW_CASK "$snapshot/cask.before" "$snapshot/cask.after" || return 1
    elif [[ "$kind" == mise && -f "$snapshot/before" ]]; then
      software_mise_inventory "$snapshot/after" || return 1
      software_record_additions MISE_VERSION "$snapshot/before" "$snapshot/after" || return 1
    fi
    # Without a complete before-snapshot nothing was installed yet.
    _state_remove_entry SOFTWARE_INVENTORY "$snapshot" || return 1
    rm -rf "$snapshot"
  done < <(awk -F '|' -v kind="$kind" \
    '$1 == "SOFTWARE_INVENTORY" && $4 == kind {print $3}' "$STATE_MANIFEST")
}

software_track_brew_install() {
  local snapshot status=0
  software_recover_interrupted brew || return 1
  snapshot="$(mktemp -d "$STATE_DIR/software-brew.XXXXXX")" || return 1
  software_brew_inventory formula "$snapshot/formula.before" || return 1
  software_brew_inventory cask "$snapshot/cask.before" || return 1
  state_record SOFTWARE_INVENTORY "$snapshot" brew || return 1
  "$@" || status=$?
  software_brew_inventory formula "$snapshot/formula.after" || return 1
  software_brew_inventory cask "$snapshot/cask.after" || return 1
  software_record_additions BREW_FORMULA "$snapshot/formula.before" "$snapshot/formula.after" || return 1
  software_record_additions BREW_CASK "$snapshot/cask.before" "$snapshot/cask.after" || return 1
  _state_remove_entry SOFTWARE_INVENTORY "$snapshot" || return 1
  rm -rf "$snapshot"
  return "$status"
}

software_mise_inventory() {
  local output="$1"
  mise ls --installed --json > "$output.json" || return 1
  jq -r 'to_entries[] | .key as $tool | .value[] | "\($tool)@\(.version)"' \
    "$output.json" > "$output.raw" || return 1
  LC_ALL=C sort -u "$output.raw" > "$output"
}

software_install_mise() {
  local snapshot status=0
  software_recover_interrupted mise || return 1
  snapshot="$(mktemp -d "$STATE_DIR/software-mise.XXXXXX")" || return 1
  software_mise_inventory "$snapshot/before" || return 1
  state_record SOFTWARE_INVENTORY "$snapshot" mise || return 1
  # Do not install tools from the checkout's/project's local mise config.
  mise install --cd "$HOME" --yes || status=$?
  software_mise_inventory "$snapshot/after" || return 1
  software_record_additions MISE_VERSION "$snapshot/before" "$snapshot/after" || return 1
  _state_remove_entry SOFTWARE_INVENTORY "$snapshot" || return 1
  rm -rf "$snapshot"
  return "$status"
}
