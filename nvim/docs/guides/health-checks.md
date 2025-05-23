# Neovim Health Check

## Quick Start

There are multiple ways to run the health check:

### Option 1: Using `:checkhealth` command (recommended)

1. Open Neovim: `nvim`
2. Run the built-in health check command: `:checkhealth user`

### Option 2: Using the shortcut command

1. Open Neovim: `nvim`
2. Run the custom command: `:UserConfig`

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

## Advanced Usage

### Option 3: Direct Lua call

If for some reason the other methods don't work:

1. Open Neovim: `nvim`
2. Run the Lua command: `:lua require("user.health").check()`

### Adding Custom Health Checks

If you want to add your own health checks:

1. Edit `nvim/lua/user/health.lua`
2. Add a new function similar to the existing check functions
3. Call this function from the `check()` function

### Automatic Health Check

To run the health check automatically when Neovim starts, add this to your `init.lua`:

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd('checkhealth user')
  end,
  pattern = "*"
})
``` 