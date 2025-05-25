# Neovim Health Check Guide

This guide explains how to use the comprehensive health check system to validate your Neovim configuration and troubleshoot common issues.

## Quick Start

There are multiple ways to run the health check:

### Option 1: Using `:checkhealth` command (recommended)

1. Open Neovim: `nvim`
2. Run the built-in health check command: `:checkhealth user`

### Option 2: Using the shortcut command

1. Open Neovim: `nvim`
2. Run the custom command: `:UserConfig`

### Option 3: Direct Lua call

If for some reason the other methods don't work:

1. Open Neovim: `nvim`
2. Run the Lua command: `:lua require("user.health").check()`

## What Gets Checked

The health check system validates several critical components:

### 🌍 Platform Detection
- Operating system detection (macOS, Linux)
- Terminal capabilities and integration
- Clipboard configuration and utilities
- Platform-specific keymaps

### 🐹 Go Development Environment
- Go installation and version
- vim-go plugin availability
- Essential Go tools:
  - `goimports` - Import management
  - `gofumpt` - Code formatting
  - `golangci-lint` - Linting
  - `gomodifytags` - Struct tag management
  - `gotests` - Test generation
  - `dlv` - Delve debugger
  - `impl` - Interface implementation
  - `gorename` - Refactoring

### 🐛 Debug Adapter Protocol (DAP)
- nvim-dap plugin installation
- nvim-dap-ui plugin installation
- nvim-nio dependency for DAP UI
- Go debugger (dlv) availability

### 🌳 TreeSitter Configuration
- nvim-treesitter plugin installation
- TreeSitter configuration module
- Language parser availability:
  - Lua, Vim, Go, JSON, Markdown

### 💬 Completion Engine
- nvim-cmp plugin installation
- Completion sources:
  - cmp-buffer (buffer completions)
  - cmp-path (file path completions)
  - cmp-cmdline (command line completions)

## Understanding the Results

The health check displays results using these indicators:

- ✓ **OK**: Everything is working correctly
- ⚠ **Warning**: Something needs attention but is not critical
- ✗ **Error**: Something is broken and needs to be fixed
- ℹ **Info**: Additional information that might be helpful

## Common Issues and Solutions

### Plugin Issues
1. **Missing plugins**: Run `:Lazy sync` to install missing plugins
2. **Plugin load errors**: Check for syntax errors in configuration files
3. **Outdated plugins**: Run `:Lazy update` to update all plugins

### Language Server Issues
2. **LSP servers not found**: Install language servers manually:
   ```bash
   # Go
   go install golang.org/x/tools/gopls@latest
   
   # Lua
   brew install lua-language-server  # macOS
   sudo apt install lua-language-server  # Ubuntu
   ```

### Go Development Issues
3. **Go tools missing**: Install Go tools manually:
   ```bash
   go install golang.org/x/tools/cmd/goimports@latest
   go install mvdan.cc/gofumpt@latest
   go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
   go install github.com/fatih/gomodifytags@latest
   go install github.com/cweill/gotests/gotests@latest
   go install github.com/go-delve/delve/cmd/dlv@latest
   ```

### Debug Adapter Issues
4. **DAP UI issues**: Ensure `nvim-nio` is installed for DAP UI:
   ```vim
   :Lazy sync
   ```

### Platform-Specific Issues

#### macOS
- **Clipboard not working**: Ensure `pbcopy`/`pbpaste` are available
- **Missing development tools**: Install Xcode command line tools:
  ```bash
  xcode-select --install
  ```

#### Linux
- **Clipboard not working**: Install clipboard utilities:
  ```bash
  # For X11
  sudo apt install xclip
  # For Wayland
  sudo apt install wl-clipboard
  ```

#### WSL
- **Clipboard integration**: Ensure `clip.exe` is in PATH
- **Performance issues**: Use WSL2 instead of WSL1

## Advanced Usage

### Adding Custom Health Checks

To add your own health checks:

1. Edit `nvim/lua/user/health.lua`
2. Add a new function similar to existing check functions:
   ```lua
   local function check_my_feature()
     start("My Custom Feature")
     
     if my_condition then
       ok("My feature is working")
     else
       error("My feature has issues")
     end
   end
   ```
3. Add the function call to the main `check()` function

### Automatic Health Check on Startup

To run health checks automatically when Neovim starts:

```lua
-- Add to your init.lua or user configuration
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      vim.cmd('checkhealth user')
    end, 1000)  -- Delay to let plugins load
  end,
  pattern = "*"
})
```

### Running Specific Health Checks

You can run health checks for specific components:

```vim
:checkhealth provider    " Check providers (clipboard, python, etc.)
:checkhealth treesitter  " Check TreeSitter installation
:checkhealth lsp         " Check LSP configuration
:checkhealth lazy        " Check plugin manager
```

## Troubleshooting Health Check Issues

### Health Check Won't Run
1. Ensure `user.health` module exists: `:lua print(require("user.health"))`
2. Check for syntax errors in health.lua
3. Verify the UserConfig command is created: `:command UserConfig`

### Incomplete Results
1. Some checks may fail silently - check `:messages` for errors
2. Plugin loading issues can affect health checks
3. Try running individual checks manually

### Performance Issues
1. Health checks with many external tool checks can be slow
2. Network-dependent checks may timeout
3. Consider running checks selectively during development

## Integration with Development Workflow

### Pre-commit Checks
Run health checks before committing configuration changes:
```bash
nvim --headless -c "checkhealth user" -c "qa"
```

### CI/CD Integration
Include health checks in your dotfiles CI pipeline to catch configuration issues early.

### Regular Maintenance
Run health checks periodically to ensure your development environment stays healthy:
- After system updates
- When adding new plugins
- When experiencing unexpected behavior

The health check system helps maintain a robust and reliable Neovim development environment! 🎉 