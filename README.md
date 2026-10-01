# Dotfiles

macOS development environment following the XDG Base Directory Specification. Apple Silicon only.

## Setup

```bash
git clone https://github.com/feniix/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

Setup links the configs, then runs each step on its own: Homebrew packages,
oh-my-zsh, Neovim, macOS defaults, GitHub CLI, SSH permissions and the git
signing key, mise tools, pi config and agent skills. A failed step doesn't stop
the others; setup lists the failures at the end and exits 1, and a rerun picks up
where it left off. It asks before installing packages, applying macOS defaults or
generating an SSH key.

Once `gitconfig` is linked, GitHub URLs are rewritten to SSH, so register your SSH
key (`gh ssh-key add ~/.ssh/id_ed25519.pub`, plus `--type signing` for commit
signing) before the next `git pull`. Commits are signed with `~/.ssh/id_ed25519`;
restore it from a backup (`scripts/ssh/manage_ssh_keys.sh restore <dir>`) or let
setup generate one.

Not installed by setup: the Claude Code CLI (`curl -fsSL https://claude.ai/install.sh | bash`),
pi (`npm install -g @earendil-works/pi-coding-agent`), and the language tools the
Neovim formatters call when present (black, isort, flake8, mypy, gopls,
puppet-lint, luacheck).

Managed filesystem changes are tracked in `~/.local/share/dotfiles-state/`.
The first original state of each path is preserved across reruns. Writes detach
existing symlinks before replacing content, and completed file writes are
fingerprinted so uninstall can recognize later user changes.

## Uninstall

```bash
./uninstall.sh              # Remove symlinks, files, created directories
./uninstall.sh --software   # Also remove software additions owned by setup
./uninstall.sh --defaults   # Also restore the defaults keys osx-defaults wrote
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

`--defaults` restores only the keys `osx-defaults` wrote, each to its recorded
type and value (or deletes it if it was absent), in its original user or
current-host scope. Other changes to those domains are kept. Domain snapshots are
still taken before any write and are imported whole only for values a key record
cannot hold (arrays, dicts, data, dates) and for domains recorded by older
installs. The first baseline is kept across setup reruns; failed restores remain
retryable. Legacy all-domain dumps are preserved for manual recovery, not
imported. Power settings (`pmset`), firmware settings (`nvram`) and file flags
(`chflags`) are listed at the end as not undone automatically.

On a rerun, anything at a managed path that you changed by hand is moved to
`~/.local/share/dotfiles-conflicts/setup/<run>/` before setup relinks it.

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
| Powerlevel10k | `~/.config/zsh/.p10k.zsh` -> `~/dotfiles/p10k.zsh` |
| Git | `~/.config/git/config` -> `~/dotfiles/gitconfig` |
| SSH | `~/.ssh/config` includes `~/.config/ssh/config` -> `~/dotfiles/ssh_config` |
| Neovim | `~/.config/nvim` -> `~/dotfiles/nvim` |
| mise | `~/.config/mise/config.toml` -> `~/dotfiles/mise/config.toml` |
| tmux | `~/.config/tmux/tmux.conf` -> `~/dotfiles/tmux.conf` |
| Utilities | `~/.local/bin/{flushdns,view-secrets}` -> `~/dotfiles/scripts/utils/` |

The `sopsdiffer` git diff driver decrypts only in repos that opt in with
`git config sops.diff true`; elsewhere it shows the ciphertext, so a cloned repo
can't make `git diff` contact a KMS or Vault with your credentials.
The `kimi`/`zai`/`dseek`/`ccc`/`ccmm` wrappers in `claude.source` pass only their
own key and unset every other `*_API_KEY`/`*_ADMIN_KEY` in that session.

The shell setup and Home Manager read the same `mise/config.toml` tool declarations.
Web-identity AWS authentication must be configured in its project/profile, not
globally.
Explicit AWS config/credentials paths are preserved. Until an XDG replacement
exists, existing `~/.aws/config` and `~/.aws/credentials` remain in use.

Skill reconciliation preserves original tool-side entries for uninstall;
conflicting copies also remain available in the conflicts directory.
Skill setup's `--dry-run` does not create installation state.
Vendoring fails without replacing the lock when configured globs match no
skills. To intentionally remove all of a source's skills, remove its `skill`
directives or explicitly skip every match.

Neovim formatters consume unsaved buffer content and separate diagnostics from
formatted output. Rust formatting resolves package editions (including workspace
inheritance) through offline Cargo metadata; standalone files use edition 2021.

## Regression tests

Requires Python 3, Neovim 0.12+, jq, and macOS's Bash/Zsh. Vendoring tests
additionally require Bash 4+ (Homebrew). The AWS credential-selection
test additionally runs when the AWS CLI is available.

```bash
uvx pytest -q tests
git ls-files setup.sh uninstall.sh 'scripts/**' | xargs shellcheck -S warning
```

Tests use temporary homes and mocked package managers/defaults/formatters.
They do not install or remove real software, alter macOS preferences, or load
your Neovim plugins.

## Structure

```
~/dotfiles/
├── scripts/
│   ├── lib/             # state.sh (state tracking), software.sh, defaults.sh
│   ├── setup/           # Setup scripts (zsh, nvim, homebrew, mise, github, macos, xdg, pi, agent skills)
│   ├── agents/          # vendor_skills.sh (third-party skill bundles)
│   ├── git/             # sops-textconv (opt-in sops diff driver)
│   ├── macos/           # osx-defaults (system preferences)
│   ├── nvim/            # check_nvim.sh (structure + plugin check)
│   ├── ssh/             # manage_ssh_keys.sh
│   └── utils/           # flushdns, view-secrets (linked into ~/.local/bin)
├── tests/               # Regression tests (temporary homes, mocked CLIs)
├── agents/              # Shared agent skills + prompts (pi, Codex, Claude Code)
├── nvim/                # Neovim config (Lua, lazy.nvim)
├── iterm2/              # iTerm2 preferences
├── pi/                  # pi user config
├── mise/                # mise tool versions
├── home-manager/        # Home Manager flake (not used by setup.sh)
├── Brewfile             # Homebrew packages
├── zshrc                # Zsh configuration
├── zshenv               # XDG env vars, ZDOTDIR
├── p10k.zsh             # Powerlevel10k prompt config
├── gitconfig            # Git configuration
├── gitignore_global     # Global gitignore
├── ssh_config           # SSH configuration
├── tmux.conf            # tmux configuration
├── setup.sh             # Main setup script
└── uninstall.sh         # Reverse setup (state-tracked)
```

## Individual Scripts

```bash
./scripts/setup/setup_zsh.sh        # Oh-My-Zsh + verify p10k/zsh-completions
./scripts/setup/setup_nvim.sh       # Neovim symlink + plugin install
./scripts/setup/setup_pi.sh         # pi user config symlinks (settings, models, agents)
./scripts/setup/setup_agent_skills.sh  # agents/skills + agents/prompts linked per item into pi, Codex, Claude Code (--dry-run; --absorb to move tool-installed items into the repo)
./scripts/agents/vendor_skills.sh     # third-party skill bundles (agents/skills.vendor) into agents/skills; pinned to skills.lock, --update [<id>] to move pins; --dry-run, --frozen
./scripts/setup/setup_homebrew.sh   # Homebrew + Brewfile
./scripts/setup/setup_mise.sh       # mise tools from config.toml
./scripts/setup/setup_github.sh     # GitHub CLI + auth
./scripts/setup/setup_macos.sh      # macOS key bindings, iTerm2, optional defaults
./scripts/macos/osx-defaults        # macOS system defaults (--dry-run supported)
./scripts/nvim/check_nvim.sh        # Neovim structure + plugin check
./scripts/ssh/manage_ssh_keys.sh    # SSH key permissions, backup, passphrase, signing-key check
```

## License

Code authored for this repository is available under the
[MIT License](LICENSE). Vendored third-party material keeps its original
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

> **Note:** `agents/skills/{docx,pdf,pptx,xlsx}` are proprietary Anthropic
> skills (all rights reserved). They are not covered by the MIT license, and
> this repository grants no rights to them. See their `LICENSE.txt` files.
