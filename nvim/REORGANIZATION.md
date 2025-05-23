# Neovim Configuration Reorganization

## Overview

This document outlines the reorganization of the Neovim configuration with better separation of concerns, improved modularity, and cleaner architecture.

## New Directory Structure

```
nvim/
├── init.lua                 # Original configuration (preserved)
├── init-new.lua            # New reorganized configuration entry point
├── lua/
│   ├── core/               # Core Neovim configuration
│   │   ├── init.lua        # Core module loader
│   │   ├── utils.lua       # Utility functions and platform detection
│   │   ├── options.lua     # Vim options and settings
│   │   ├── keymaps.lua     # Global keymaps and shortcuts
│   │   └── autocmds.lua    # Autocommands and file type settings
│   ├── plugins/            # Plugin management
│   │   ├── init.lua        # Plugin loader (lazy.nvim setup)
│   │   ├── specs/          # Plugin specifications (what to install)
│   │   │   ├── ui.lua      # UI-related plugins
│   │   │   ├── editor.lua  # Editor enhancement plugins
│   │   │   ├── lsp.lua     # LSP and completion plugins
│   │   │   ├── lang/       # Language-specific plugins
│   │   │   │   ├── go.lua
│   │   │   │   ├── terraform.lua
│   │   │   │   └── puppet.lua
│   │   │   └── tools.lua   # Development tools
│   │   └── config/         # Plugin configurations (how to configure)
│   │       ├── colorscheme.lua
│   │       ├── telescope.lua
│   │       ├── treesitter.lua
│   │       ├── cmp.lua
│   │       ├── lualine.lua
│   │       ├── gitsigns.lua
│   │       ├── lang/
│   │       │   ├── go.lua
│   │       │   └── terraform.lua
│   │       └── ...
│   └── user/               # User-specific overrides (preserved)
│       └── ...
```

## Key Principles

### 1. Separation of Concerns
- **Plugin Declarations** (`plugins/specs/`): What plugins to install, dependencies, lazy loading
- **Plugin Configurations** (`plugins/config/`): How plugins should be configured
- **Core Settings** (`core/`): Essential Neovim functionality
- **User Overrides** (`user/`): Personal customizations

### 2. Modular Architecture
- Each module has a single responsibility
- Clear interfaces between modules
- Easy to enable/disable features
- Minimal interdependencies

### 3. Lazy Loading Strategy
- Plugins load only when needed
- Event-based loading for better performance
- Command and filetype-based loading
- Optimized startup time

## Migration Status

### ✅ Completed
- [x] Core module structure (`core/`)
- [x] Plugin management structure (`plugins/`)
- [x] Basic plugin specifications
- [x] Essential plugin configurations
- [x] New entry point (`init-new.lua`)
- [x] Backward compatibility with existing setup
- [x] Health check compatibility (fixed platform module API)
- [x] Platform detection and utilities migration

### 🚧 In Progress
- [ ] Complete plugin configuration migration
- [ ] Advanced plugin configurations (DAP, Diffview, etc.)
- [ ] Language-specific configurations
- [ ] User override system

### 📋 TODO
- [ ] Performance optimization
- [ ] Documentation for each module
- [ ] Health checks for new structure
- [ ] Migration scripts

## How to Test the New Configuration

### Option 1: Side-by-side testing
The new configuration is available as `init-new.lua`. You can test it without affecting your current setup:

```bash
# Test the new configuration
nvim -u init-new.lua

# Or create a symlink for testing
ln -sf init-new.lua init-test.lua
nvim -u init-test.lua
```

### Option 2: Gradual migration
1. Keep using `init.lua` for daily work
2. Test specific modules from the new structure
3. Gradually migrate configurations
4. Switch when confident

## Benefits of the New Structure

### 1. **Clear Organization**
- Plugin specs separate from configurations
- Language-specific plugins grouped together
- Core functionality isolated from extensions

### 2. **Better Maintainability**
- Easy to find and modify specific configurations
- Reduced coupling between components
- Clear dependency relationships

### 3. **Improved Performance**
- Better lazy loading strategy
- Optimized plugin loading order
- Reduced startup time

### 4. **Enhanced Modularity**
- Easy to disable/enable features
- Simple to add new plugins
- Clean separation of concerns

### 5. **Scalability**
- Easy to add new languages
- Simple plugin management
- Clear extension points

## Configuration Examples

### Adding a New Plugin

1. **Add specification** in appropriate `plugins/specs/*.lua`:
```lua
-- In plugins/specs/editor.lua
{
  "new/plugin.nvim",
  event = "BufReadPost",
  config = function()
    require("plugins.config.new-plugin").setup()
  end,
}
```

2. **Create configuration** in `plugins/config/new-plugin.lua`:
```lua
local M = {}

function M.setup()
  local plugin = require('new-plugin')
  plugin.setup({
    -- configuration here
  })
end

return M
```

### Adding Language Support

1. **Create spec** in `plugins/specs/lang/newlang.lua`
2. **Create config** in `plugins/config/lang/newlang.lua`
3. **Add to plugin loader** in `plugins/init.lua`

## Migration Commands

### Switch to New Configuration
```bash
# Backup current configuration
cp init.lua init-backup.lua

# Switch to new configuration
cp init-new.lua init.lua

# Restart Neovim
```

### Revert if Needed
```bash
# Restore backup
cp init-backup.lua init.lua
```

## Troubleshooting

### Common Issues

1. **Plugin not loading**: Check if spec is included in `plugins/init.lua`
2. **Configuration error**: Verify config file exists and has `setup()` function
3. **Missing dependencies**: Check plugin specifications for required dependencies
4. **Health check errors**: The new configuration maintains backward compatibility with the existing health check system

### Resolved Issues

- **Health check platform API error**: Fixed by adding backward compatibility methods to the platform module in `core/utils.lua`
  - Added `get_os()`, `get_terminal()`, `get_language_tools()`, etc.
  - Maintains compatibility with existing `user/health.lua` checks

### Debug Commands
```vim
:Lazy                 " Check plugin status
:checkhealth          " Run health checks
:messages             " View error messages
```

## Next Steps

1. **Test the new configuration** with your daily workflow
2. **Report any issues** or missing functionality
3. **Gradually migrate** remaining configurations
4. **Customize** the new structure to your needs

## Feedback

Please test the new configuration and provide feedback on:
- Missing functionality
- Performance improvements
- Ease of use
- Any issues encountered

The goal is to maintain all existing functionality while providing a cleaner, more maintainable structure. 