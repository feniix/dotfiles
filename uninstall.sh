#!/bin/bash
#
# Dotfiles Uninstall Script
# Reverses everything setup.sh did, using the state manifest
#
# Usage:
#   ./uninstall.sh              # Remove symlinks, files, directories
#   ./uninstall.sh --software   # Also uninstall Homebrew packages, OMZ, mise
#   ./uninstall.sh --defaults   # Also restore macOS defaults from backup
#   ./uninstall.sh --everything # All of the above
#   ./uninstall.sh --dry-run    # Show what would be done (combinable with above)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-state"
STATE_MANIFEST="$STATE_DIR/manifest"
STATE_BACKUPS="$STATE_DIR/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse flags
DRY_RUN=false
REMOVE_SOFTWARE=false
RESTORE_DEFAULTS=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)     DRY_RUN=true ;;
    --software)    REMOVE_SOFTWARE=true ;;
    --defaults)    RESTORE_DEFAULTS=true ;;
    --everything)  REMOVE_SOFTWARE=true; RESTORE_DEFAULTS=true ;;
    *)             log_error "Unknown flag: $arg"; exit 1 ;;
  esac
done

# Verify manifest exists
if [[ ! -f "$STATE_MANIFEST" ]]; then
  log_error "No state manifest found at $STATE_MANIFEST"
  log_error "Nothing to uninstall — setup.sh was either never run or used an older version without state tracking."
  exit 1
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# Confirmation
if [[ "$DRY_RUN" == false ]]; then
  echo ""
  echo "This will remove all dotfiles symlinks, restore backed-up files,"
  echo "and clean up directories created by setup.sh."
  if [[ "$REMOVE_SOFTWARE" == true ]]; then
    echo ""
    echo "  --software: Will also uninstall Homebrew packages, Oh-My-Zsh, and mise tools."
  fi
  if [[ "$RESTORE_DEFAULTS" == true ]]; then
    echo ""
    echo "  --defaults: Will also attempt to restore macOS defaults from backup."
  fi
  echo ""
  read -p "Continue? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted."
    exit 0
  fi
fi

echo ""

# Read manifest in reverse order (LIFO — undo in reverse)
# Skip comment lines
entries=()
while IFS= read -r line; do
  [[ "$line" =~ ^#.* ]] && continue
  [[ -z "$line" ]] && continue
  entries+=("$line")
done < "$STATE_MANIFEST"

# Process in reverse
for (( i=${#entries[@]}-1; i>=0; i-- )); do
  line="${entries[$i]}"
  IFS='|' read -r type ts path extra <<< "$line"

  case "$type" in

    SYMLINK)
      if [[ -L "$path" ]]; then
        local_target="$(readlink "$path")"
        # Only remove if it still points into our dotfiles
        if [[ "$local_target" == "$DOTFILES_DIR"* ]] || [[ "$local_target" == "$extra" ]]; then
          log_info "Removing symlink: $path"
          run rm "$path"
        else
          log_warning "Symlink $path now points to $local_target (not ours) — skipping"
        fi
      elif [[ -e "$path" ]]; then
        log_warning "$path exists but is not a symlink — skipping"
      fi
      ;;

    SYMLINK_OVER_FILE)
      if [[ -L "$path" ]]; then
        log_info "Removing symlink: $path"
        run rm "$path"
        if [[ -n "$extra" ]] && [[ -e "$STATE_BACKUPS/$extra" ]]; then
          log_info "Restoring backup: $path"
          run cp -a "$STATE_BACKUPS/$extra" "$path"
        else
          log_warning "No backup available for $path"
        fi
      elif [[ -e "$path" ]]; then
        log_warning "$path exists but is not a symlink — skipping"
      fi
      ;;

    FILE_WRITTEN)
      if [[ -e "$path" ]]; then
        if [[ -n "$extra" ]] && [[ -e "$STATE_BACKUPS/$extra" ]]; then
          log_info "Restoring original: $path"
          run cp -a "$STATE_BACKUPS/$extra" "$path"
        else
          log_warning "No backup for $path — removing"
          run rm -f "$path"
        fi
      fi
      ;;

    FILE_CREATED)
      if [[ -e "$path" ]]; then
        log_info "Removing created file: $path"
        run rm -f "$path"
      fi
      ;;

    FILE_DELETED)
      if [[ -n "$extra" ]] && [[ -e "$STATE_BACKUPS/$extra" ]]; then
        log_info "Restoring deleted file: $path"
        run cp -a "$STATE_BACKUPS/$extra" "$path"
      else
        log_warning "Cannot restore $path — no backup available"
      fi
      ;;

    FILE_COPIED)
      if [[ -e "$path" ]]; then
        if [[ -n "$extra" ]] && [[ -e "$STATE_BACKUPS/$extra" ]]; then
          log_info "Restoring original: $path"
          run cp -a "$STATE_BACKUPS/$extra" "$path"
        else
          log_warning "No backup for $path — removing"
          run rm -f "$path"
        fi
      fi
      ;;

    DIR_CREATED)
      if [[ -d "$path" ]]; then
        if run rmdir "$path" 2>/dev/null; then
          log_info "Removed empty directory: $path"
        else
          if [[ "$DRY_RUN" == true ]]; then
            echo "  [dry-run] rmdir $path (if empty)"
          else
            log_warning "Directory not empty, keeping: $path"
          fi
        fi
      fi
      ;;

    ITERM2_PREFS)
      log_info "Removing iTerm2 custom preferences folder setting..."
      run defaults delete com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || true
      run defaults delete com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || true
      ;;

    DIR_EXISTED)
      # We didn't create it — leave it alone
      ;;

    GH_CONFIG)
      # path=key, extra=value
      if command -v gh &>/dev/null; then
        log_info "Clearing gh config: $path"
        run gh config set "$path" ""
      fi
      ;;

    SOFTWARE)
      # path=type (brew/omz/mise), extra=details
      if [[ "$REMOVE_SOFTWARE" != true ]]; then
        continue
      fi

      case "$path" in
        brew)
          if command -v brew &>/dev/null && [[ -n "$extra" ]] && [[ -f "$extra" ]]; then
            log_info "Removing Homebrew packages from Brewfile..."
            # Only remove packages that are leaves (nothing depends on them)
            local leaves
            if [[ "$DRY_RUN" == false ]]; then
              leaves="$(brew leaves 2>/dev/null || true)"
              while IFS= read -r formula; do
                [[ -z "$formula" ]] && continue
                [[ "$formula" =~ ^#.* ]] && continue
                # Extract formula name from Brewfile lines like: brew "name"
                if [[ "$formula" =~ ^brew\ \"([^\"]+)\" ]]; then
                  local pkg="${BASH_REMATCH[1]}"
                  if echo "$leaves" | grep -q "^${pkg}$"; then
                    log_info "Uninstalling: $pkg"
                    brew uninstall "$pkg" 2>/dev/null || true
                  else
                    log_warning "Skipping $pkg (other packages depend on it)"
                  fi
                fi
              done < "$extra"
            else
              echo "  [dry-run] Uninstall leaf Homebrew packages from $extra"
            fi
          fi
          ;;
        omz)
          if [[ -d "$extra" ]]; then
            if [[ -f "$extra/tools/uninstall.sh" ]]; then
              log_info "Uninstalling Oh-My-Zsh using its own uninstaller..."
              run bash "$extra/tools/uninstall.sh" --unattended
            else
              log_info "Removing Oh-My-Zsh directory: $extra"
              run rm -rf "$extra"
            fi
          fi
          ;;
        mise)
          if command -v mise &>/dev/null; then
            log_info "Removing mise tools and data..."
            if [[ "$DRY_RUN" == false ]]; then
              mise implode --yes 2>/dev/null || rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/mise"
            else
              echo "  [dry-run] mise implode --yes"
            fi
          fi
          ;;
      esac
      ;;

    DEFAULTS_BACKUP)
      if [[ "$RESTORE_DEFAULTS" != true ]]; then
        continue
      fi
      if [[ -f "$path" ]]; then
        log_info "macOS defaults backup found at: $path"
        log_warning "Automatic restore of macOS defaults is partial and may require a restart."
        if [[ "$DRY_RUN" == false ]]; then
          read -p "Attempt to import defaults from backup? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            defaults import NSGlobalDomain "$path" 2>/dev/null || true
            log_success "Imported defaults from backup (restart may be needed)"
          fi
        else
          echo "  [dry-run] defaults import NSGlobalDomain $path"
        fi
      else
        log_warning "Defaults backup not found at: $path"
      fi
      ;;

  esac
done

# Clean up state directory
if [[ "$DRY_RUN" == false ]]; then
  echo ""
  log_info "Cleaning up state directory..."
  rm -rf "$STATE_DIR"
  log_success "State directory removed."
fi

echo ""
log_success "Dotfiles uninstall complete!"
if [[ "$DRY_RUN" == true ]]; then
  log_info "(dry-run mode — no changes were made)"
fi
