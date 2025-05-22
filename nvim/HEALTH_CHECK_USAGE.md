# Neovim Health Check Usage

This document explains how to use the health check module in your Neovim configuration.

## Quick Start

There are multiple ways to run the health check:

### Option 1: Using `:checkhealth` command (recommended)

1. Open Neovim: `nvim`
2. Run the built-in health check command: `:checkhealth user`

This will show the status of your configuration including:
- LSP Configuration
- Debugging Configuration (DAP)
- Go Development Environment
- Treesitter Configuration
- Completion Configuration

### Option 2: Using the shortcut command

The health module installs a convenient user command:

1. Open Neovim: `nvim`
2. Run the custom command: `:UserConfig`

### Option 3: Direct Lua call

If for some reason the other methods don't work:

1. Open Neovim: `nvim`
2. Run the Lua command: `:lua require("user.health").check()`

## Understanding the Results

The health check will display results in the following format:

- ✓ OK: Everything is working correctly
- ⚠ Warning: Something needs attention but is not critical
- ✗ Error: Something is broken and needs to be fixed
- ℹ Info: Additional information that might be helpful

## Common Issues and Solutions

If you encounter problems with the health check:

1. **Missing plugins**: Run `:PlugInstall` to install missing plugins
2. **LSP servers not found**: Install the language servers (`gopls`, etc.)
3. **Go tools missing**: Run `:GoInstallBinaries` to install Go tools
4. **DAP UI issues**: Ensure `nvim-nio` is installed for DAP UI

## Adding Custom Health Checks

If you want to add your own health checks:

1. Edit `nvim/lua/user/health.lua`
2. Add a new function similar to the existing check functions
3. Call this function from the `check()` function

## Automatic Health Check

To run the health check automatically when Neovim starts, add this to your `init.vim`:

```vim
autocmd VimEnter * lua vim.cmd('checkhealth user')
```

Or in your `init.lua`:

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('checkhealth user')
  end,
  pattern = "*"
})
``` 