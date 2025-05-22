# Neovim Configuration Documentation

This directory contains documentation for the Neovim configuration in this dotfiles repository.

## Guides

- [Colorscheme Guide](colorscheme_guide.md) - How to use, customize, and switch colorschemes

## Configuration Overview

The Neovim configuration in this repository is built around:

- **Plugin Management**: Using [Packer](https://github.com/wbthomason/packer.nvim) for managing plugins
- **Modern Features**: LSP, Treesitter, and modern completion with nvim-cmp
- **Colorscheme**: Default is [NeoSolarized](https://github.com/svrana/neosolarized.nvim), a modern Solarized implementation
- **Go Development**: Enhanced Go support with go.nvim and vim-go
- **Debugging**: Using nvim-dap for debugging support

## File Structure

- `init.lua` - Main configuration entry point
- `lua/user/` - Configuration modules
  - `plugins.lua` - Plugin definitions
  - `colorbuddy_setup.lua` - Colorscheme configuration
  - `options.lua` - Vim options
  - `keymaps.lua` - Key mappings
  - `lsp.lua` - Language Server Protocol setup
  - `go.lua` - Go-specific configuration
  - And others...

## Useful Commands

- `:PackerSync` - Install/update plugins
- `:ToggleTheme` - Switch between light and dark Solarized themes
- `:checkhealth user` - Run health checks for your configuration

## Scripts

There are several utility scripts in `scripts/nvim/` for checking your Neovim setup:

- `health_check.sh` - Comprehensive health check
- `check_plugins.sh` - List all installed plugins
- `test_colorbuddy.sh` - Test NeoSolarized setup

## Further Reading

For detailed information about specific parts of the configuration, see:

- [Colorscheme Guide](colorscheme_guide.md)
- [Health Check Documentation](../scripts/nvim/health_check.sh) 