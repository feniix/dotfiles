{ lib, dotfilesDir, ... }:

{
  # Ensure SSH ControlMaster socket directory exists before any ssh call.
  home.activation.createSshControlMasters =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.ssh/controlmasters"
      run chmod 700 "$HOME/.ssh/controlmasters"
    '';

  # Run BEFORE HM's checkLinkTargets safety pass. For each path we manage as a
  # live symlink into ~/dotfiles, if anything else (real file, real dir, stale
  # symlink) is sitting there, blow it away so HM can write our symlink without
  # erroring out. No-op if the symlink is already correct.
  #
  # WARNING: this DELETES whatever is at these paths. If you want a backup-first
  # approach instead, drop this block and run `home-manager switch -b backup`.
  #
  # Keep this list in sync with modules/files.nix.
  home.activation.cleanStaleTargets =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      _clean() {
        local path="$1" want="$2"
        if [[ -L "$path" ]]; then
          if [[ "$(readlink "$path")" == "$want" ]]; then
            return 0
          fi
          verboseEcho "Removing stale symlink: $path -> $(readlink "$path")"
          run rm "$path"
        elif [[ -e "$path" ]]; then
          verboseEcho "Removing conflicting file/dir at $path (HM wants a symlink)"
          run rm -rf "$path"
        fi
      }

      _clean "$HOME/.config/nvim"                "${dotfilesDir}/nvim"
      _clean "$HOME/.config/zsh/.p10k.zsh"       "${dotfilesDir}/p10k.zsh"
      _clean "$HOME/.config/git/ignore"          "${dotfilesDir}/gitignore_global"
      _clean "$HOME/.config/git/allowed_signers" "${dotfilesDir}/git_allowed_signers"
      _clean "$HOME/.config/tmux/tmux.conf"      "${dotfilesDir}/tmux.conf"
      _clean "$HOME/.vimrc"                      "${dotfilesDir}/.vimrc"
      _clean "$HOME/.pylintrc"                   "${dotfilesDir}/pylintrc"
      _clean "$HOME/.luacheckrc"                 "${dotfilesDir}/.luacheckrc"
    '';

  # Point iTerm2 at the prefs plist inside the dotfiles repo. Idempotent.
  # Equivalent to scripts/setup/setup_macos.sh's `defaults write` calls.
  home.activation.iterm2PrefsFolder =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write com.googlecode.iterm2 \
        PrefsCustomFolder -string "${dotfilesDir}/iterm2"
      run /usr/bin/defaults write com.googlecode.iterm2 \
        LoadPrefsFromCustomFolder -bool true
    '';
}
