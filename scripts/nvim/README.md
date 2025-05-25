# Neovim Scripts

This directory contains scripts for setting up, managing, and troubleshooting Neovim with the dotfiles configuration.

## Available Scripts

### 🚀 Complete Setup
- **`setup_and_check.sh`** - Comprehensive setup and verification script
  - Sets up Neovim configuration
  - Installs plugins via lazy.nvim
  - Runs health checks
  - Tests colorscheme
  - Provides next steps

### 🏥 Health & Diagnostics
- **`health_check.sh`** - Quick health check and plugin status
- **`check_plugins.sh`** - Comprehensive plugin installation check
- **`plugin_status.sh`** - Detailed plugin status via lazy.nvim

### 📚 Documentation
- **`nvim_help.sh`** - Quick reference for all commands and scripts
- **`check_structure.sh`** - Check and fix structural issues (circular symlinks)

## Quick Start

```bash
# Complete setup from scratch
./scripts/nvim/setup_and_check.sh

# Quick health check
./scripts/nvim/health_check.sh

# Check plugin status
./scripts/nvim/check_plugins.sh

# Get help and command reference
./scripts/nvim/nvim_help.sh
```

## Script Details

### setup_and_check.sh
**Purpose**: One-stop script for complete Neovim setup and verification

**What it does**:
1. Checks if Neovim is installed
2. Runs setup script to link configuration
3. Installs plugins via lazy.nvim
4. Runs health checks
5. Tests colorscheme setup
6. Provides usage instructions

**Usage**: `./scripts/nvim/setup_and_check.sh`

### health_check.sh
**Purpose**: Quick health verification with plugin status

**What it does**:
- Shows lazy.nvim status
- Runs plugin status check
- Provides instructions for detailed health check

**Usage**: `./scripts/nvim/health_check.sh`

### check_plugins.sh
**Purpose**: Comprehensive plugin installation and migration check

**What it does**:
- Lists all installed plugins
- Checks for vim-plug/Packer remnants
- Verifies lazy.nvim migration
- Provides cleanup instructions

**Usage**: `./scripts/nvim/check_plugins.sh`

### plugin_status.sh
**Purpose**: Detailed plugin status via lua script

**What it does**:
- Runs lua script in Neovim to check plugins
- Shows installation status by manager
- Identifies missing plugins
- Color-coded output

**Usage**: `./scripts/nvim/plugin_status.sh`



### nvim_help.sh
**Purpose**: Quick reference and help

**What it does**:
- Lists all available scripts
- Shows common Neovim commands
- Displays configuration file locations
- Provides troubleshooting tips

**Usage**: `./scripts/nvim/nvim_help.sh`

### check_structure.sh
**Purpose**: Check and fix structural issues

**What it does**:
- Detects circular symlinks (like nvim/nvim → nvim)
- Validates main configuration symlink
- Checks for essential configuration files
- Fixes common structural problems

**Usage**: `./scripts/nvim/check_structure.sh`

## Common Workflows

### First-time Setup
```bash
# Complete setup
./scripts/nvim/setup_and_check.sh
```

### Troubleshooting
```bash
# Check what's wrong
./scripts/nvim/health_check.sh

# Detailed plugin check
./scripts/nvim/check_plugins.sh

# Get help
./scripts/nvim/nvim_help.sh
```

### Plugin Management
```bash
# Check plugin status
./scripts/nvim/plugin_status.sh

# In Neovim: install/update plugins
:Lazy sync
```

### Theme Issues
```bash
# Test colorscheme in Neovim
nvim -c ':ToggleTheme'

# In Neovim: toggle theme
:ToggleTheme
```

## Integration with Main Setup

These scripts integrate with the main setup process:

- `../setup/setup_nvim.sh` - Main setup script (called by setup_and_check.sh)
- Main health checks available in Neovim via `:checkhealth user`
- Configuration located at `~/.config/nvim/` (symlinked to `~/dotfiles/nvim/`)

## File Locations

- **Scripts**: `~/dotfiles/scripts/nvim/`
- **Configuration**: `~/.config/nvim/` → `~/dotfiles/nvim/`
- **Plugins**: `~/.local/share/nvim/lazy/`
- **Cache**: `~/.cache/nvim/`

## Environment Variables

The scripts respect XDG Base Directory Specification:

- `XDG_CONFIG_HOME` (default: `~/.config`)
- `XDG_DATA_HOME` (default: `~/.local/share`)
- `XDG_CACHE_HOME` (default: `~/.cache`)

## Requirements

- **Neovim** v0.9.0+ (for lazy.nvim support)
- **Git** (for plugin installation)
- **Internet connection** (for initial plugin download)

## Troubleshooting

Common issues and solutions:

1. **Scripts not executable**: `chmod +x scripts/nvim/*.sh`
2. **Neovim not found**: Install with `brew install neovim` (macOS)
3. **Plugins not installing**: Run `:Lazy sync` in Neovim
4. **Health check fails**: Check `:checkhealth user` for details
5. **Config not loading**: Verify `~/.config/nvim` symlink
6. **Circular symlinks**: Run `./scripts/nvim/check_structure.sh` to detect and fix

### Common Structural Issues

**Circular Symlink Problem**: If you see nested `nvim/nvim/nvim/...` directories, this indicates a circular symlink where `nvim/nvim` points back to the nvim directory itself.

**Solution**: Run the structure check script:
```bash
./scripts/nvim/check_structure.sh
```

This will automatically detect and remove circular symlinks while preserving the correct configuration structure.

For more detailed troubleshooting, see `nvim/lua/user/README.md`. 