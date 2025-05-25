# Health Check System

The reorganized Neovim configuration includes a comprehensive health check system that validates the integrity, performance, and functionality of all configuration components.

## Overview

The health check system provides multiple levels of validation:

- **Structure & Architecture**: Validates the overall organization and module structure
- **Core Modules**: Tests platform detection, options, keymaps, and autocommands
- **Plugin System**: Validates plugin manager, specifications, and configurations
- **User Override System**: Tests user customizations and integration
- **Performance Monitoring**: Tracks startup time and resource usage

## Quick Start

### Basic Usage

```vim
" Run comprehensive health check
:checkhealth

" Run quick essential checks only
:HealthQuick

" Run specific health check categories
:checkhealth structure
:checkhealth core
:checkhealth plugins
:checkhealth user_system
```

### User Commands

The health system provides several convenient commands:

```vim
:HealthCheck          " Comprehensive health check
:HealthQuick          " Quick essential systems check
:HealthStructure      " Check configuration structure
:HealthCore           " Check core modules
:HealthPlugins        " Check plugin system
:HealthUser           " Check user override system
```

## Health Check Modules

### 1. Structure Health (`health/structure.lua`)

Validates the overall reorganization and architectural integrity.

**What it checks:**
- Directory structure completeness
- Core module availability and loading
- Plugin system architecture (specs vs configs separation)
- Lazy loading strategy effectiveness
- Backward compatibility with old structure
- Configuration consistency and conflict detection
- Overall health scoring with recommendations

**Key validations:**
```lua
-- Directory structure
lua/core/           -- Core modules
lua/plugins/        -- Plugin management
lua/plugins/specs/  -- Plugin specifications
lua/plugins/config/ -- Plugin configurations
lua/user/           -- User customizations
lua/health/         -- Health check modules

-- Module completeness
core.init, core.utils, core.options, core.keymaps, core.autocmds

-- Plugin categories
plugins.specs.ui, plugins.specs.editor, plugins.specs.lsp, plugins.specs.tools
```

### 2. Core Module Health (`health/core.lua`)

Validates the foundation of the configuration system.

**What it checks:**
- **Platform Detection**: OS detection, terminal detection, clipboard configuration
- **Utility Functions**: map(), create_augroup(), merge_tables(), safe_require()
- **Vim Options**: Critical settings (numbers, indentation, colors, etc.)
- **Global Keymaps**: Leader keys and navigation keymaps
- **Autocommands**: Autogroup configuration and autocmd setup

**Example validation:**
```lua
-- Platform detection test
local os_name = utils.platform.get_os()  -- Should return: macos, linux, etc.
local terminal = utils.platform.get_terminal()  -- Should detect terminal type
local clipboard = utils.platform.get_clipboard_config()  -- Should configure clipboard

-- Options validation
vim.opt.number         -- Should be true
vim.opt.relativenumber -- Should be true  
vim.opt.termguicolors  -- Should be true
```

### 3. Plugin System Health (`health/plugins.lua`)

Validates the plugin management and configuration system.

**What it checks:**
- **Plugin Manager**: lazy.nvim installation and configuration
- **Plugin Specifications**: All spec categories (ui, editor, lsp, tools, lang/*)
- **Essential Configurations**: telescope, treesitter, cmp, colorscheme
- **Advanced Configurations**: dap, diffview, indent-blankline
- **Language Configurations**: Go, Terraform, Puppet language support
- **Individual Plugin Health**: Loading status and functionality
- **Performance Metrics**: Startup time, lazy loading effectiveness

**Plugin categories validated:**
```lua
-- Essential plugins
telescope     -- File finder and fuzzy search
treesitter    -- Syntax highlighting and parsing
cmp           -- Auto-completion engine
colorscheme   -- Theme management

-- Advanced plugins  
dap           -- Debug Adapter Protocol
diffview      -- Git diff visualization
which-key     -- Keymap help system

-- Language-specific
go            -- Go development tools
terraform     -- Infrastructure as Code
puppet        -- Configuration management
```

### 4. User Override System Health (`health/user_system.lua`)

Validates user customizations and the override system.

**What it checks:**
- **User Module Initialization**: Loading and integration with core
- **Configuration Files**: `user/config.lua` structure and validity
- **Override System**: Options, keymaps, autocmds, and plugin overrides
- **Custom Modules**: User-defined modules in `user/modules/`
- **Integration Testing**: User overrides properly merge with core/plugins
- **Documentation**: User documentation and help system availability

**User system structure:**
```lua
user/
├── init.lua              -- Main user module
├── config.lua            -- User configuration (optional)
├── config.lua.example    -- Configuration template
├── overrides/
│   ├── options.lua       -- Vim options overrides
│   ├── keymaps.lua       -- Keymap overrides
│   ├── autocmds.lua      -- Autocommand overrides
│   └── plugins/          -- Plugin-specific overrides
└── modules/              -- Custom user modules
```

### 5. Health Check Orchestration (`health/init.lua`)

Coordinates all health check modules and provides unified access.

**Features:**
- **Comprehensive Coordination**: Runs all health checks in priority order
- **Quick Health Check**: Fast validation of essential systems only
- **Targeted Commands**: User commands for specific health check areas
- **Automation**: Automatic health checks after configuration reload
- **Performance Overview**: Startup statistics and optimization suggestions

## Health Check Results

### Status Indicators

Health checks use standard Neovim health check indicators:

- ✅ **OK**: Component is working correctly
- ⚠️ **WARN**: Component has issues but is functional
- ❌ **ERROR**: Component has critical issues
- ℹ️ **INFO**: Additional information or optional component

### Performance Metrics

The health system tracks and reports:

```vim
" Startup performance
Startup time: 45.32ms       -- Total configuration load time
Total plugins: 42           -- Number of installed plugins
Loaded plugins: 8           -- Plugins loaded at startup
Lazy-loaded: 34            -- Plugins deferred for performance

" Memory usage
Memory usage: 28.5MB        -- Current Lua memory usage

" Health score
Overall health: 95%         -- Comprehensive health percentage
```

### Improvement Recommendations

Based on health check results, the system provides targeted recommendations:

```vim
" Performance optimization
- Review failed module loading
- Check plugin configurations
- Optimize startup time
- Resolve configuration conflicts

" Structure improvements  
- Consider structure reorganization
- Review backward compatibility issues
- Update deprecated configurations
```

## Customizing Health Checks

### Adding Custom Health Checks

Create a new health check module:

```lua
-- lua/health/my_custom.lua
local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start("My Custom Checks")
  
  -- Your custom validation logic
  local custom_config = safe_require("my_custom_module")
  if custom_config then
    ok("Custom module is loaded")
  else
    error("Custom module failed to load")
  end
end

return M
```

Register with the main health system:

```lua
-- In your user configuration
local health_init = require("health")
if health_init and health_init.setup then
  health_init.setup()
end
```

### Extending Existing Health Checks

Override health check modules in your user configuration:

```lua
-- user/overrides/plugins/health.lua
local M = {}

function M.override(original_module)
  -- Extend the original health check
  local original_check = original_module.check
  
  original_module.check = function()
    -- Run original checks
    original_check()
    
    -- Add your custom checks
    local health = vim.health or require("health")
    health.start("Custom Extensions")
    health.ok("Custom validation passed")
  end
  
  return original_module
end

return M
```

## Troubleshooting

### Common Issues

**Health check module not found:**
```vim
:checkhealth my_module
" Error: Health check module 'my_module' is not available

" Solution: Ensure the module exists at lua/health/my_module.lua
```

**Module loading failures:**
```vim
" Check if module can be required manually
:lua print(vim.inspect(require("problematic_module")))

" Check for syntax errors
:lua require("problematic_module")
```

**Performance issues:**
```vim
" Check startup time
:HealthQuick

" Detailed plugin analysis
:checkhealth plugins

" Profile startup
:Lazy profile
```

### Debug Mode

Enable verbose health checking:

```lua
-- In your user configuration
vim.g.health_verbose = true
vim.g.health_debug = true
```

### Health Check Automation

Set up automatic health checks:

```lua
-- Run health check after plugin updates
vim.api.nvim_create_autocmd("User", {
  pattern = "LazySync",
  callback = function()
    vim.defer_fn(function()
      require("health").quick_check()
    end, 2000)
  end,
})

-- Weekly comprehensive health check reminder
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local last_check = vim.fn.getftime(vim.fn.stdpath("cache") .. "/last_health_check")
    local week_seconds = 7 * 24 * 60 * 60
    
    if os.time() - last_check > week_seconds then
      vim.notify("Consider running :HealthCheck for configuration validation", vim.log.levels.INFO)
      vim.fn.writefile({}, vim.fn.stdpath("cache") .. "/last_health_check")
    end
  end,
})
```

## Integration with CI/CD

### Automated Testing

Use health checks in automated testing:

```bash
#!/bin/bash
# test-config.sh

# Start Neovim in headless mode and run health checks
nvim --headless --noplugin -u init.lua -c "lua require('health').check()" -c "qall" 2>&1 | \
  grep -E "(ERROR|✗)" && exit 1 || exit 0
```

### GitHub Actions

```yaml
# .github/workflows/nvim-health.yml
name: Neovim Configuration Health Check

on: [push, pull_request]

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Neovim
        run: |
          wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
          tar xzf nvim-linux64.tar.gz
          echo "$PWD/nvim-linux64/bin" >> $GITHUB_PATH
      
      - name: Run Health Checks
        run: |
          cd nvim
          nvim --headless -c "lua require('health').check()" -c "qall"
```

## Best Practices

### Regular Health Monitoring

1. **Weekly Comprehensive Checks**: Run `:HealthCheck` weekly
2. **After Updates**: Run `:HealthQuick` after plugin updates
3. **Before Important Work**: Validate system before critical projects
4. **Performance Monitoring**: Track startup time trends

### Health-Driven Development

1. **Write Health Checks First**: Create health checks when adding new features
2. **Test Edge Cases**: Validate error conditions and edge cases
3. **Document Expectations**: Clear documentation of what should pass/fail
4. **Automate Validation**: Integrate health checks into development workflow

### Maintenance Workflow

```vim
" Monthly maintenance routine
:HealthCheck                 " Comprehensive validation
:Lazy sync                   " Update plugins
:HealthPlugins              " Validate plugin health
:Mason update               " Update LSP servers
:checkhealth mason          " Validate LSP health
```

The health check system provides comprehensive validation and monitoring for your Neovim configuration, ensuring reliability, performance, and maintainability as your setup evolves. 