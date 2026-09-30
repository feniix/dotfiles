# Dotfiles

macOS development environment following the XDG Base Directory Specification. Apple Silicon only.

## Setup

```bash
git clone https://github.com/feniix/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script runs straight through: XDG dirs, symlinks, Homebrew packages, oh-my-zsh, neovim, macOS defaults, GitHub CLI, SSH permissions, and mise tools.

Managed filesystem changes are tracked in `~/.local/share/dotfiles-state/`.
The first original state of each path is preserved across reruns. Writes detach
existing symlinks before replacing content, and completed file writes are
fingerprinted so uninstall can recognize later user changes.

## Uninstall

```bash
./uninstall.sh              # Remove symlinks, files, created directories
./uninstall.sh --software   # Also remove software additions owned by setup
./uninstall.sh --defaults   # Also restore snapshotted defaults domains
./uninstall.sh --everything # All of the above
./uninstall.sh --dry-run    # Preview what would be done
```

Uninstall reads the state manifest in reverse order, restores backed-up files,
removes owned symlinks/files, and cleans up empty directories we created.
Changed user files, unresolved entries, and unselected optional operations retain
their records and backups for a later retry. Ambiguous legacy manifests are never
silently migrated or discarded.

`--software` removes only newly installed Homebrew formulae/casks, mise tool
versions, and an Oh-My-Zsh directory installed by setup. Pre-existing software is
left alone. Legacy Brewfile-wide/mise-wide records lack ownership information
and require manual cleanup. App Store apps and VS Code extensions are not removed.

`--defaults` imports each domain into its original user/current-host scope.
The first snapshot is kept across setup reruns; failed imports remain retryable.
Legacy all-domain dumps are preserved for manual recovery, not imported into
`NSGlobalDomain`. Power settings (`pmset`), firmware settings (`nvram`), and file
visibility flags are not automatically restored.

Agent skill conflicts are retained separately under
`~/.local/share/dotfiles-conflicts/`, outside disposable uninstall state.

## What's Included

- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k (via Homebrew)
- **Editor**: Neovim (Lua config, lazy.nvim plugins)
- **Terminal**: iTerm2 with MesloLGS Nerd Font
- **Git**: Custom aliases, diff-so-fancy, SSH signing
- **Packages**: Homebrew (Brewfile), mise (config.toml) for dev tools
- **macOS**: System defaults via `scripts/macos/osx-defaults`

## File Locations

| Config | Location |
|--------|----------|
| Zsh | `~/.config/zsh/.zshrc` -> `~/dotfiles/zshrc` |
| Zsh env | `~/.zshenv` -> `~/dotfiles/zshenv` |
| Powerlevel10k | `~/.p10k.zsh` -> `~/dotfiles/p10k.zsh` |
| Git | `~/.config/git/config` -> `~/dotfiles/gitconfig` |
| SSH | `~/.ssh/config` includes `~/.config/ssh/config` -> `~/dotfiles/ssh_config` |
| Neovim | `~/.config/nvim` -> `~/dotfiles/nvim` |
| mise | `~/.config/mise/config.toml` -> `~/dotfiles/mise/config.toml` |

The shell setup and Home Manager read the same `mise/config.toml` tool declarations.
Web-identity AWS authentication must be configured in its project/profile, not
globally.

## Regression tests

Requires Python 3, Neovim, jq, and macOS's Bash/Zsh. The AWS credential-selection
test additionally runs when the AWS CLI is available.

```bash
python3 -m unittest discover -s tests -v
shellcheck -S warning setup.sh uninstall.sh scripts/lib/*.sh scripts/setup/*.sh scripts/macos/osx-defaults
```

Tests use temporary homes and mocked package managers/defaults/formatters.
They do not install or remove real software, alter macOS preferences, or load
your Neovim plugins.

## Structure

```
~/dotfiles/
├── scripts/
│   ├── lib/             # state.sh (state tracking library)
│   ├── setup/           # Setup scripts (zsh, nvim, homebrew, mise, github, macos, xdg)
│   ├── macos/           # osx-defaults (system preferences)
│   ├── nvim/            # check_nvim.sh (structure + plugin check)
│   └── ssh/             # manage_ssh_keys.sh
├── agents/              # Shared agent skills + prompts (pi, Codex, Claude Code)
├── nvim/                # Neovim config (Lua, lazy.nvim)
├── iterm2/              # iTerm2 preferences
├── Brewfile             # Homebrew packages
├── zshrc                # Zsh configuration
├── zshenv               # XDG env vars, ZDOTDIR
├── p10k.zsh             # Powerlevel10k prompt config
├── gitconfig            # Git configuration
├── gitignore_global     # Global gitignore
├── ssh_config           # SSH configuration
├── setup.sh             # Main setup script
└── uninstall.sh         # Reverse setup (state-tracked)
```

## Individual Scripts

```bash
./scripts/setup/setup_zsh.sh        # Oh-My-Zsh + verify p10k/zsh-completions
./scripts/setup/setup_nvim.sh       # Neovim symlink + plugin install
./scripts/setup/setup_pi.sh         # pi user config symlinks (settings, models, agents)
./scripts/setup/setup_agent_skills.sh  # agents/skills + agents/prompts linked per item into pi, Codex, Claude Code (--dry-run)
./scripts/agents/vendor_skills.sh     # pull third-party skill bundles (agents/skills.vendor) into agents/skills; --dry-run, --frozen
./scripts/setup/setup_homebrew.sh   # Homebrew + Brewfile
./scripts/setup/setup_mise.sh       # mise tools from config.toml
./scripts/setup/setup_github.sh     # GitHub CLI + auth
./scripts/setup/setup_macos.sh      # macOS fonts, keys, iTerm2
./scripts/macos/osx-defaults        # macOS system defaults (--dry-run supported)
./scripts/nvim/check_nvim.sh        # Neovim structure + plugin check
./scripts/ssh/manage_ssh_keys.sh    # SSH key permissions, backup, passphrase
```

## License

Code authored for this repository is available under the
[MIT License](LICENSE). Vendored third-party material keeps its original
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
