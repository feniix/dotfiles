# Dotfiles

macOS development environment following the XDG Base Directory Specification. Apple Silicon only.

## Setup

```bash
git clone https://github.com/feniix/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script runs straight through: XDG dirs, symlinks, Homebrew packages, oh-my-zsh, neovim, macOS defaults, GitHub CLI, SSH permissions, and mise tools.

All changes are tracked in `~/.local/share/dotfiles-state/` with backups of any overwritten files.

## Uninstall

```bash
./uninstall.sh              # Remove symlinks, files, created directories
./uninstall.sh --software   # Also uninstall Homebrew packages, Oh-My-Zsh, mise
./uninstall.sh --defaults   # Also restore macOS defaults from backup
./uninstall.sh --everything # All of the above
./uninstall.sh --dry-run    # Preview what would be done
```

Uninstall reads the state manifest in reverse order, restores backed-up files, removes symlinks, and cleans up empty directories we created.

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
| mise | `~/.config/mise/config.toml` |

## Structure

```
~/dotfiles/
├── scripts/
│   ├── lib/             # state.sh (state tracking library)
│   ├── setup/           # Setup scripts (zsh, nvim, homebrew, mise, github, macos, xdg)
│   ├── macos/           # osx-defaults (system preferences)
│   ├── nvim/            # check_nvim.sh (structure + plugin check)
│   └── ssh/             # manage_ssh_keys.sh
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
./scripts/setup/setup_homebrew.sh   # Homebrew + Brewfile
./scripts/setup/setup_mise.sh       # mise tools from config.toml
./scripts/setup/setup_github.sh     # GitHub CLI + auth
./scripts/setup/setup_macos.sh      # macOS fonts, keys, iTerm2
./scripts/macos/osx-defaults        # macOS system defaults (--dry-run supported)
./scripts/nvim/check_nvim.sh        # Neovim structure + plugin check
./scripts/ssh/manage_ssh_keys.sh    # SSH key permissions, backup, passphrase
```
