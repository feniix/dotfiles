# CLAUDE.md

Personal dotfiles for macOS (Apple Silicon). Not designed to be generalizable.

## Setup

- `./setup.sh` — straight-line install: XDG dirs, symlinks, Homebrew, oh-my-zsh, nvim, macOS, GitHub, SSH, mise
- `./uninstall.sh` — reverse setup using state manifest (supports `--software`, `--defaults`, `--dry-run`)
- All side effects tracked in `~/.local/share/dotfiles-state/` with file backups
- Safe to re-run: idempotent install, first run on existing install does an "adopt"

## Key Files

- `zshrc` — main shell config (oh-my-zsh, p10k via Homebrew, mise, direnv, keybindings)
- `zshenv` — XDG env vars, sets `ZDOTDIR=~/.config/zsh`
- `gitconfig` — aliases, diff-so-fancy, SSH signing, URL rewrites
- `ssh_config` — multiplexing, GitHub multi-key setup, LAN/Tailscale hosts
- `Brewfile` — Homebrew packages (source of truth for system tools)
- `claude.source` — Claude Code wrapper functions for alternative providers
- `pi/` — pi user config (settings.json, models.json, AGENTS.md, agents/, skills/, compound-engineering manifest). Symlinked into `~/.pi/agent/`. See `pi/README.md`.

## Architecture

- Symlinks from XDG locations to `~/dotfiles/`
- Git reads `~/.config/git/config` natively (no `~/.gitconfig`)
- SSH uses `Include ~/.config/ssh/config` (SSH doesn't support XDG)
- Powerlevel10k and zsh-completions installed via Homebrew, not git clones
- mise manages dev tools via `~/.config/mise/config.toml`
- `scripts/lib/state.sh` — shared state tracking library (sourced by all setup scripts)

## Scripts

```
scripts/
├── lib/
│   └── state.sh             # State tracking library (manifest + backups)
├── setup/
│   ├── setup_xdg.sh        # XDG directory structure
│   ├── setup_zsh.sh         # Oh-My-Zsh + verify Homebrew packages
│   ├── setup_nvim.sh        # Neovim symlink + optional plugin install
│   ├── setup_homebrew.sh    # Homebrew + Brewfile
│   ├── setup_mise.sh        # mise tools from config.toml
│   ├── setup_github.sh      # GitHub CLI install + auth
│   ├── setup_pi.sh          # pi user config symlinks (settings, models, agents, skills)
│   └── setup_macos.sh       # macOS fonts, iTerm2, key bindings
├── macos/
│   └── osx-defaults         # macOS system defaults (supports --dry-run, --only, --backup)
├── nvim/
│   └── check_nvim.sh        # Structure, plugins, and legacy cleanup check
└── ssh/
    └── manage_ssh_keys.sh   # Key permissions, backup, passphrase management
```

## Package Management

- `brew bundle --file=Brewfile` — install/update Homebrew packages
- `brew bundle dump --file=Brewfile --force` — update Brewfile from current state
- `mise install` — install all tools from `~/.config/mise/config.toml`
