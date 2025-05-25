# Neovim Integration with Setup System

This document explains how Neovim setup integrates with the main dotfiles setup system.

## Overview

The Neovim configuration has **dual integration**:
1. **Basic Setup**: Integrated into the main setup system (`setup.sh`)
2. **Advanced Management**: Standalone scripts for detailed management

## Integration Architecture

```
setup.sh (Main Setup)
├── setup_nvim() → scripts/setup/setup_nvim.sh (Basic Setup)
└── Option 5 → scripts/setup/setup_nvim_complete.sh (Complete Setup)
                 ├── calls setup_nvim.sh (basic)
                 └── calls scripts/nvim/setup_and_check.sh (advanced)
```

## Setup Options Available

### From Main Setup (`./setup.sh`)

When you run `./setup.sh` and the dotfiles directory already exists, you get these options:

1. **Update existing dotfiles to XDG format** - Full system setup
2. **Run XDG setup only** - Directory structure only
3. **Run platform-specific setup only** - macOS/Linux specific
4. **Run Neovim setup only** - Basic nvim setup with optional plugin installation
5. **Run comprehensive Neovim setup & health check** - **⭐ Complete nvim setup**
6. **Run Homebrew setup only** - Package management
7. **Set up fonts** - Font installation
8. **Set up GitHub integration** - GitHub tools
9. **Clean up legacy files** - Cleanup old configs
10. **Set up SSH keys** - SSH management
11. **Set up asdf version manager** - Version management
12. **Exit** - Quit without changes

### Direct Nvim Scripts

From `scripts/nvim/`:

- **`setup_and_check.sh`** - Complete nvim setup and verification
- **`health_check.sh`** - Quick health check
- **`check_plugins.sh`** - Comprehensive plugin check
- **`plugin_status.sh`** - Plugin status via lazy.nvim
- **`nvim_help.sh`** - Quick reference and help

## Setup Flow Details

### Basic Nvim Setup (Option 4)
```bash
setup_nvim() function in setup.sh
├── Prompts for plugin installation
├── Calls scripts/setup/setup_nvim.sh
├── Optional health check
└── Shows available management scripts
```

**What it does**:
- Links nvim configuration to XDG locations
- Optionally installs plugins via lazy.nvim
- Creates necessary directories
- Links .vimrc for vim compatibility
- Shows management script locations

### Complete Nvim Setup (Option 5)
```bash
scripts/setup/setup_nvim_complete.sh
├── Step 1: Basic setup (setup_nvim.sh --install-plugins)
├── Step 2: Comprehensive check (setup_and_check.sh)
└── Step 3: Show management options
```

**What it does**:
- Everything from basic setup
- Runs comprehensive health checks
- Tests plugin installations
- Verifies colorscheme setup
- Provides complete reference

## Integration Points

### Main Setup Integration

The main `setup.sh` script integrates nvim through:

1. **setup_nvim() function** - Core integration point
2. **Menu option 4** - Basic nvim setup
3. **Menu option 5** - Complete nvim setup  
4. **Validation** - Checks for script existence
5. **Fallbacks** - Provides alternatives if scripts missing

### Enhanced Features

The integration provides:

- **Interactive prompts** for plugin installation
- **Automatic health checks** post-setup
- **Script availability display** 
- **Fallback handling** for missing components
- **Progress reporting** with colored output

## File Relationships

### Core Setup Files
- `setup.sh` - Main orchestrator
- `scripts/setup/setup_nvim.sh` - Basic nvim setup
- `scripts/setup/setup_nvim_complete.sh` - Complete nvim setup

### Nvim Management Files
- `scripts/nvim/setup_and_check.sh` - Comprehensive setup
- `scripts/nvim/health_check.sh` - Health checking
- `scripts/nvim/check_plugins.sh` - Plugin verification
- `scripts/nvim/plugin_status.sh` - Plugin status
- `scripts/nvim/nvim_help.sh` - Help and reference

### Configuration Files
- `nvim/` - Main configuration directory
- `nvim/init.lua` - Entry point
- `nvim/lua/` - Lua modules
- `.vimrc` - Vim compatibility

## Usage Examples

### Quick Setup from Main Script
```bash
./setup.sh
# Choose option 5 for complete nvim setup
```

### Direct Nvim Management
```bash
# Complete setup and check
./scripts/nvim/setup_and_check.sh

# Quick health check
./scripts/nvim/health_check.sh

# Get help
./scripts/nvim/nvim_help.sh
```

### Basic Setup Only
```bash
./scripts/setup/setup_nvim.sh --install-plugins
```

## Error Handling

The integration includes comprehensive error handling:

1. **Missing Scripts** - Fallback to basic functionality
2. **Missing Neovim** - Clear installation instructions
3. **Plugin Issues** - Health check guidance
4. **Configuration Problems** - Troubleshooting tips

## Benefits of Integration

1. **Unified Experience** - Single entry point via setup.sh
2. **Progressive Enhancement** - Basic → Advanced setup options
3. **Standalone Capability** - Scripts work independently
4. **Comprehensive Checking** - Health and status verification
5. **User Guidance** - Clear next steps and references

## Maintenance

To maintain this integration:

1. **Keep scripts synchronized** - Ensure all scripts reference correct paths
2. **Update documentation** - Keep README files current
3. **Test integration points** - Verify main setup → nvim scripts work
4. **Handle new features** - Add new nvim scripts to integration
5. **Version compatibility** - Ensure scripts work with nvim updates

This integration provides both novice-friendly setup through the main script and power-user capabilities through dedicated nvim management scripts. 