# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for a macOS development environment following the XDG Base Directory Specification. It provides modular setup scripts and configuration files for a complete development environment.

## Key Commands

### Setup and Installation
- `./setup.sh` - Main installation script with interactive menu for partial installations
- `./validate_dotfiles.sh` - Validation script to test core functionality and consistency

### Individual Setup Scripts
- `./scripts/setup/setup_xdg.sh` - XDG directory structure setup
- `./scripts/setup/setup_zsh.sh` - Zsh and Oh-My-Zsh configuration
- `./scripts/setup/setup_nvim.sh` - Neovim configuration
- `./scripts/setup/setup_homebrew.sh` - Homebrew package management
- `./scripts/setup/setup_fonts.sh` - Nerd Font installation
- `./scripts/setup/setup_github.sh` - GitHub integration
- `./scripts/setup/setup_macos.sh` - macOS-specific setup
- `./scripts/setup/setup_linux.sh` - Linux-specific setup

### Package Management
- `brew bundle --file=Brewfile` - Install packages from Brewfile
- `brew bundle dump --file=Brewfile --force` - Update Brewfile with current packages

## Architecture

### XDG Compliance Structure
The dotfiles follow XDG Base Directory Specification:
- Configuration files → `~/.config/`
- Data files → `~/.local/share/`
- Cache files → `~/.cache/`
- State files → `~/.local/state/`

### Key Components
- **Symlink Approach**: Configuration files remain in the dotfiles repository and are symlinked to XDG locations
- **Modular Setup**: Each component has its own setup script for easier maintenance
- **Safety Features**: Automatic backups, rollback capability, and dependency checking
- **Cross-Platform**: macOS (full support) and Linux (basic support)

### Directory Structure
```
~/dotfiles/
├── scripts/
│   ├── setup/          # Main setup scripts
│   ├── nvim/           # Neovim-related utilities
│   ├── ssh/            # SSH key management
│   └── utils/          # General utilities
├── nvim/               # Neovim configuration (Lua-based)
├── zsh_custom/         # Custom ZSH themes and plugins
├── fonts/              # Font configuration and management
├── Brewfile            # Homebrew packages list
├── zshrc               # Main Zsh configuration
├── zshenv              # Zsh environment variables (XDG setup)
└── setup.sh            # Main installation script
```

### Environment Variables
- `DOTFILES_DIR` - Path to dotfiles repository (defaults to script location)
- `XDG_CONFIG_HOME` - Config directory (`~/.config`)
- `XDG_DATA_HOME` - Data directory (`~/.local/share`)
- `XDG_CACHE_HOME` - Cache directory (`~/.cache`)
- `XDG_STATE_HOME` - State directory (`~/.local/state`)

### Backup System
- Backups stored in `~/.local/share/dotfiles_backup/TIMESTAMP/`
- Automatic rollback on installation errors
- Preserves existing configurations before modification

## Development Notes

- Scripts use color-coded logging with helper functions (`log_info`, `log_success`, `log_warning`, `log_error`)
- All scripts include dependency checking and error handling with `set -e`
- Platform detection is automated for macOS/Linux compatibility
- Neovim configuration is Lua-based with plugin management via lazy.nvim
- ZSH configuration includes custom themes and plugin management
- Utility scripts are linked to `~/bin` for PATH compatibility