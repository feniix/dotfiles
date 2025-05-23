# Health Check System Documentation

The health check system provides comprehensive diagnostic and validation capabilities for the Neovim configuration. It ensures that all components are properly configured and functioning correctly.

## Overview

The health check system is built on Neovim's native `:checkhealth` command and provides detailed diagnostics for:

- Core module functionality
- Plugin installation and configuration
- User override system integrity
- Language-specific tool availability
- Performance metrics
- Platform-specific configurations

## Available Health Checks

### Core Health Checks

#### `:checkhealth user`
Comprehensive health check for the user override system:

**Categories Checked**:
- User configuration file validation
- Module loading status
- Override system functionality
- Custom module health
- Configuration syntax validation
- Performance impact assessment

**Example Output**:
```
health: user
  - OK Core modules loaded successfully
  - OK User configuration found and valid
  - OK Override system functioning
  - WARNING Custom module 'my_module' not found
  - OK Platform detection working (Darwin)
  - OK Performance within acceptable limits (startup: 45ms)
```

#### `:checkhealth core`
Validates core module functionality:

**Categories Checked**:
- Platform detection accuracy
- Utility function availability
- Options application
- Keymap registration
- Autocommand setup

### Plugin Health Checks

#### `:checkhealth lazy`
Validates lazy.nvim plugin manager:

**Categories Checked**:
- Plugin installation status
- Loading condition validation
- Dependency resolution
- Configuration integrity
- Performance metrics

#### `:checkhealth telescope`
Validates Telescope fuzzy finder:

**Categories Checked**:
- External dependency availability (fd, rg, fzf)
- Extension loading
- Configuration validity
- Performance optimization

#### `:checkhealth treesitter`
Validates TreeSitter syntax highlighting:

**Categories Checked**:
- Parser installation status
- Language support availability
- Text object configuration
- Highlighting functionality

#### `:checkhealth lsp`
Validates Language Server Protocol setup:

**Categories Checked**:
- LSP server availability
- Client configuration
- Capability negotiation
- Error handling

### Language-Specific Health Checks

#### `:checkhealth go`
Go development environment validation:

**Categories Checked**:
- Go installation and version
- gopls LSP server availability
- Delve debugger installation
- vim-go plugin configuration
- GOPATH/GOMODULE setup

#### `:checkhealth python`
Python development environment validation:

**Categories Checked**:
- Python interpreter availability
- Virtual environment detection
- LSP server installation (pylsp/pyright)
- Formatter availability (black, autopep8, yapf)
- Linter availability (flake8, pylint, mypy)
- Testing framework detection

#### `:checkhealth rust`
Rust development environment validation:

**Categories Checked**:
- Rust toolchain installation
- rust-analyzer availability
- Cargo functionality
- Clippy linter installation
- rustfmt formatter availability

#### `:checkhealth terraform`
Terraform environment validation:

**Categories Checked**:
- Terraform binary availability
- terraform-ls LSP server
- Plugin configuration
- Workspace detection

#### `:checkhealth puppet`
Puppet environment validation:

**Categories Checked**:
- Puppet installation
- puppet-lint availability
- Syntax validation tools
- Editor services

## Health Check Implementation

### Core Health Check Structure

```lua
-- health/user.lua
local M = {}

M.check = function()
  vim.health.start("User Configuration System")
  
  -- Check user configuration file
  local config_file = vim.fn.stdpath("config") .. "/lua/user/config.lua"
  if vim.fn.filereadable(config_file) == 1 then
    vim.health.ok("User configuration file found")
    
    -- Validate syntax
    local ok, config = pcall(dofile, config_file)
    if ok then
      vim.health.ok("User configuration syntax valid")
    else
      vim.health.error("User configuration syntax error: " .. config)
    end
  else
    vim.health.warn("User configuration file not found (using defaults)")
  end
  
  -- Check module loading
  local user_module = package.loaded['user']
  if user_module then
    vim.health.ok("User module loaded successfully")
  else
    vim.health.error("User module failed to load")
  end
  
  -- Check override system
  M.check_override_system()
  
  -- Check custom modules
  M.check_custom_modules()
  
  -- Performance metrics
  M.check_performance()
end

return M
```

### Plugin Health Check Pattern

```lua
-- health/telescope.lua
local M = {}

M.check = function()
  vim.health.start("Telescope Configuration")
  
  -- Check plugin installation
  local ok, telescope = pcall(require, "telescope")
  if ok then
    vim.health.ok("Telescope plugin loaded")
  else
    vim.health.error("Telescope plugin not found or failed to load")
    return
  end
  
  -- Check external dependencies
  M.check_external_tools()
  
  -- Check configuration
  M.check_configuration()
  
  -- Check extensions
  M.check_extensions()
end

M.check_external_tools = function()
  local tools = {
    { cmd = "fd", desc = "Fast file finder" },
    { cmd = "rg", desc = "Ripgrep for live grep" },
    { cmd = "fzf", desc = "Fuzzy finder" },
  }
  
  for _, tool in ipairs(tools) do
    if vim.fn.executable(tool.cmd) == 1 then
      vim.health.ok(tool.desc .. " (" .. tool.cmd .. ") available")
    else
      vim.health.warn(tool.desc .. " (" .. tool.cmd .. ") not found - some features may be limited")
    end
  end
end

return M
```

### Language Health Check Template

```lua
-- health/go.lua
local M = {}

M.check = function()
  vim.health.start("Go Development Environment")
  
  -- Check Go installation
  if vim.fn.executable("go") == 1 then
    local version = vim.fn.system("go version"):gsub("\n", "")
    vim.health.ok("Go installed: " .. version)
  else
    vim.health.error("Go not found in PATH")
    return
  end
  
  -- Check GOPATH/GOROOT
  M.check_go_environment()
  
  -- Check LSP server
  M.check_gopls()
  
  -- Check debugger
  M.check_delve()
  
  -- Check vim-go plugin
  M.check_vim_go()
end

M.check_gopls = function()
  if vim.fn.executable("gopls") == 1 then
    local version = vim.fn.system("gopls version"):gsub("\n", "")
    vim.health.ok("gopls LSP server available: " .. version)
  else
    vim.health.error("gopls not found - install with: go install golang.org/x/tools/gopls@latest")
  end
end

return M
```

## Health Check Categories

### Configuration Validation

**File Syntax Checks**:
- Lua syntax validation for configuration files
- JSON validation for plugin specifications
- Schema validation for user overrides

**Dependency Validation**:
- Module dependency resolution
- Plugin dependency checking
- LSP server availability

### Performance Monitoring

**Startup Time Analysis**:
```lua
-- Measure startup time impact
local function check_startup_performance()
  local start_time = vim.fn.reltime()
  -- Simulate startup sequence
  require('core').setup()
  require('plugins').setup()
  local load_time = vim.fn.reltimestr(vim.fn.reltime(start_time))
  
  local time_ms = tonumber(load_time) * 1000
  if time_ms < 100 then
    vim.health.ok(string.format("Startup time: %.1fms (excellent)", time_ms))
  elseif time_ms < 250 then
    vim.health.ok(string.format("Startup time: %.1fms (good)", time_ms))
  elseif time_ms < 500 then
    vim.health.warn(string.format("Startup time: %.1fms (acceptable)", time_ms))
  else
    vim.health.error(string.format("Startup time: %.1fms (slow)", time_ms))
  end
end
```

**Memory Usage Monitoring**:
```lua
-- Check memory consumption
local function check_memory_usage()
  local memory_kb = vim.fn.system("ps -o rss= -p " .. vim.fn.getpid()):gsub("%s+", "")
  local memory_mb = tonumber(memory_kb) / 1024
  
  if memory_mb < 50 then
    vim.health.ok(string.format("Memory usage: %.1f MB (excellent)", memory_mb))
  elseif memory_mb < 100 then
    vim.health.ok(string.format("Memory usage: %.1f MB (good)", memory_mb))
  elseif memory_mb < 200 then
    vim.health.warn(string.format("Memory usage: %.1f MB (high)", memory_mb))
  else
    vim.health.error(string.format("Memory usage: %.1f MB (excessive)", memory_mb))
  end
end
```

### Platform Compatibility

**Operating System Detection**:
```lua
-- Validate platform-specific features
local function check_platform_features()
  local os_name = require('core.utils').get_os()
  vim.health.ok("Platform detected: " .. os_name)
  
  -- Platform-specific checks
  if os_name == "Darwin" then
    -- macOS specific checks
    if vim.fn.executable("pbcopy") == 1 then
      vim.health.ok("System clipboard integration available")
    else
      vim.health.warn("System clipboard tools not found")
    end
  elseif os_name == "Linux" then
    -- Linux specific checks
    if vim.fn.executable("xclip") == 1 or vim.fn.executable("wl-clipboard") == 1 then
      vim.health.ok("System clipboard integration available")
    else
      vim.health.warn("Install xclip or wl-clipboard for system clipboard support")
    end
  end
end
```

### Tool Availability

**Development Tools**:
```lua
-- Check external tool availability
local function check_development_tools()
  local tools = {
    -- Version control
    { cmd = "git", desc = "Git version control", required = true },
    
    -- Search tools
    { cmd = "fd", desc = "Fast file finder", required = false },
    { cmd = "rg", desc = "Ripgrep search", required = false },
    
    -- Language tools
    { cmd = "node", desc = "Node.js runtime", required = false },
    { cmd = "python3", desc = "Python 3 interpreter", required = false },
    
    -- Formatters
    { cmd = "prettier", desc = "Code formatter", required = false },
    { cmd = "black", desc = "Python formatter", required = false },
  }
  
  for _, tool in ipairs(tools) do
    if vim.fn.executable(tool.cmd) == 1 then
      vim.health.ok(tool.desc .. " available")
    else
      if tool.required then
        vim.health.error(tool.desc .. " required but not found")
      else
        vim.health.warn(tool.desc .. " not found (optional)")
      end
    end
  end
end
```

## User Health Check Integration

### Custom Health Checks

Users can add custom health checks:

```lua
-- user/health.lua
local M = {}

M.check_custom = function()
  vim.health.start("Custom User Configuration")
  
  -- Check custom tools
  if vim.fn.executable("my-custom-tool") == 1 then
    vim.health.ok("Custom tool available")
  else
    vim.health.warn("Custom tool not found")
  end
  
  -- Check custom configuration
  local custom_config = vim.g.my_custom_setting
  if custom_config then
    vim.health.ok("Custom setting configured: " .. custom_config)
  else
    vim.health.warn("Custom setting not configured")
  end
end

-- Register custom health check
vim.api.nvim_create_user_command("CheckUserHealth", function()
  M.check_custom()
end, {})

return M
```

### Health Check Automation

```lua
-- Automatic health check on startup (optional)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Run health checks on startup if configured
    if vim.g.auto_health_check then
      vim.cmd("checkhealth user")
    end
  end,
})

-- Scheduled health check reminders
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local last_check = vim.fn.getftime(vim.fn.stdpath("data") .. "/last_health_check")
    local current_time = vim.fn.localtime()
    local week_in_seconds = 7 * 24 * 60 * 60
    
    if current_time - last_check > week_in_seconds then
      vim.notify("Consider running :checkhealth to validate your configuration", vim.log.levels.INFO)
      vim.fn.writefile({tostring(current_time)}, vim.fn.stdpath("data") .. "/last_health_check")
    end
  end,
})
```

## Health Check Commands

### Available Commands

```vim
" Core health checks
:checkhealth user          " User override system
:checkhealth core          " Core modules

" Plugin health checks
:checkhealth lazy          " Plugin manager
:checkhealth telescope     " File finder
:checkhealth treesitter    " Syntax highlighting
:checkhealth lsp           " Language servers
:checkhealth dap           " Debug adapters

" Language-specific health checks
:checkhealth go            " Go development
:checkhealth python        " Python development
:checkhealth rust          " Rust development
:checkhealth terraform     " Infrastructure as Code
:checkhealth puppet        " Configuration management

" Comprehensive health check
:checkhealth               " All available checks
```

### Custom Health Check Commands

```lua
-- Create custom health check commands
vim.api.nvim_create_user_command("HealthSummary", function()
  -- Run abbreviated health checks
  vim.cmd("checkhealth user")
  vim.cmd("checkhealth lazy")
  vim.cmd("checkhealth lsp")
end, { desc = "Run essential health checks" })

vim.api.nvim_create_user_command("HealthFull", function()
  -- Run comprehensive health checks
  vim.cmd("checkhealth")
end, { desc = "Run all available health checks" })

vim.api.nvim_create_user_command("HealthLang", function(opts)
  -- Run language-specific health check
  local lang = opts.args
  if lang ~= "" then
    vim.cmd("checkhealth " .. lang)
  else
    print("Available languages: go, python, rust, terraform, puppet")
  end
end, { 
  desc = "Run language-specific health check",
  nargs = 1,
  complete = function()
    return { "go", "python", "rust", "terraform", "puppet" }
  end
})
```

## Troubleshooting with Health Checks

### Common Issues and Solutions

#### Plugin Loading Issues
```lua
-- Health check reveals plugin not loading
-- Solution: Check plugin specification and dependencies
:checkhealth lazy
-- Look for missing dependencies or configuration errors
```

#### LSP Server Issues
```lua
-- Health check shows LSP server problems
:checkhealth lsp
-- Install missing LSP servers:
-- :Mason to open LSP installer
-- Or manually install: npm install -g typescript-language-server
```

#### Performance Issues
```lua
-- Health check shows slow startup
:checkhealth user
-- Identify slow-loading plugins or configurations
-- Use :Lazy profile to analyze startup time
```

#### Platform-Specific Issues
```lua
-- Health check reveals platform problems
:checkhealth core
-- Install platform-specific tools
-- Update platform detection logic if needed
```

### Health Check Automation Scripts

```bash
#!/bin/bash
# health-check.sh - Automated health check script

nvim --headless -c "checkhealth user" -c "q" 2>&1 | tee health-report.txt

# Parse results
if grep -q "ERROR" health-report.txt; then
  echo "❌ Health check failed - see health-report.txt"
  exit 1
else
  echo "✅ Health check passed"
  exit 0
fi
```

## Best Practices

### Regular Health Monitoring

1. **Weekly Health Checks**: Run `:checkhealth` weekly to catch issues early
2. **Post-Update Validation**: Always run health checks after updating plugins
3. **Environment Changes**: Check health when changing development environments
4. **Performance Monitoring**: Monitor startup time and memory usage regularly

### Health Check Development

1. **Comprehensive Coverage**: Include all critical components in health checks
2. **Clear Messages**: Provide actionable error messages and solutions
3. **Performance Impact**: Keep health checks lightweight and fast
4. **User Feedback**: Include user-specific configurations in health validation

### Integration with CI/CD

```yaml
# .github/workflows/neovim-health.yml
name: Neovim Configuration Health Check

on: [push, pull_request]

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Neovim
        run: |
          sudo apt-get update
          sudo apt-get install -y neovim
      - name: Run Health Checks
        run: |
          nvim --headless -c "checkhealth user" -c "q"
```

The health check system ensures that your Neovim configuration remains reliable, performant, and properly configured across different environments and use cases. 