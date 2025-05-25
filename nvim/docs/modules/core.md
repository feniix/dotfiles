# Core Modules Documentation

The core modules provide essential Neovim functionality and settings. They form the foundation of the configuration and are loaded first during startup.

## Module Overview

| Module | Purpose | Dependencies |
|--------|---------|--------------|
| `core/init.lua` | Core module loader | None |
| `core/utils.lua` | Utilities and platform detection | None |
| `core/options.lua` | Vim options and settings | `core/utils` |
| `core/keymaps.lua` | Global keymaps | `core/utils` |
| `core/autocmds.lua` | Autocommands and file types | `core/utils` |

## Loading Order

The core modules are loaded in a specific order to ensure dependencies are resolved:

1. **utils.lua** - Platform detection and utility functions
2. **options.lua** - Vim options and global settings
3. **keymaps.lua** - Global keymaps and shortcuts
4. **autocmds.lua** - Autocommands and file type settings
5. **User overrides** - Applied after core modules

## Module Details

### core/init.lua - Core Module Loader

**Purpose**: Orchestrates the loading of all core modules in the correct order.

**API**:
```lua
local core = require('core')
core.setup() -- Load all core modules
```

**Key Features**:
- Loads modules in dependency order
- Handles user override integration
- Error handling for missing modules

### core/utils.lua - Utilities and Platform Detection

**Purpose**: Provides utility functions and platform-specific configurations.

**Key Functions**:

#### Platform Detection
```lua
local utils = require('core.utils')

-- Platform detection
utils.platform.is_mac()     -- Returns true on macOS
utils.platform.is_linux()   -- Returns true on Linux
utils.platform.get_os()     -- Returns 'macos', 'linux', or 'unknown'

-- Global functions (backward compatibility)
is_mac()     -- Returns true on macOS
is_linux()   -- Returns true on Linux
```

#### File System Utilities
```lua
-- File/directory operations
utils.file_exists(path)         -- Check if file exists
utils.dir_exists(path)          -- Check if directory exists
utils.create_dir(path)          -- Create directory if it doesn't exist
utils.get_config_dir()          -- Get Neovim config directory
utils.get_data_dir()            -- Get Neovim data directory
```

#### Configuration Utilities
```lua
-- Configuration helpers
utils.safe_require(module)      -- Safely require module with error handling
utils.merge_config(default, user) -- Merge user config with defaults
utils.reload_config()           -- Reload configuration
```

#### Keymap Utilities
```lua
-- Keymap helpers
utils.map(mode, key, cmd, opts) -- Create keymap with options
utils.nmap(key, cmd, opts)      -- Normal mode keymap
utils.vmap(key, cmd, opts)      -- Visual mode keymap
utils.imap(key, cmd, opts)      -- Insert mode keymap
```

### core/options.lua - Vim Options and Settings

**Purpose**: Configures all Vim options and global settings.

**Categories**:

#### Editor Behavior
- Line numbers and relative numbers
- Indentation (spaces, tabs, width)
- Search behavior (ignorecase, smartcase)
- Scrolling and cursor behavior

#### UI Settings
- Color support and themes
- Status line and command line
- Window splitting behavior
- Mouse support

#### File Handling
- Encoding (UTF-8)
- File formats and line endings
- Backup and swap file settings
- Undo persistence

#### Performance
- Update time and timeout settings
- Completion menu behavior
- Syntax highlighting limits

**Key Options Set**:
```lua
-- Example of key options (see full file for complete list)
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.shiftwidth = 2          -- Indent size
vim.opt.tabstop = 2             -- Tab size
vim.opt.ignorecase = true       -- Ignore case in search
vim.opt.smartcase = true        -- Smart case matching
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
```

### core/keymaps.lua - Global Keymaps

**Purpose**: Defines global keymaps and shortcuts that work across all file types.

**Keymap Categories**:

#### Leader Key Configuration
```lua
vim.g.mapleader = " "      -- Space as leader key
vim.g.maplocalleader = "," -- Comma as local leader
```

#### Window Management
- Window navigation (`<C-h/j/k/l>`)
- Window resizing (`<C-Up/Down/Left/Right>`)
- Window splitting

#### Buffer Management
- Buffer navigation
- Buffer operations (close, next, previous)

#### Text Editing
- Line movement (`Alt+j/k`)
- Indentation shortcuts
- Quick save and quit

#### Search and Replace
- Clear search highlighting
- Quick search and replace

#### Terminal Integration
- Terminal mode navigation
- Quick terminal access

**Example Keymaps**:
```lua
-- Window navigation
map('n', '<C-h>', '<C-w>h', 'Go to left window')
map('n', '<C-j>', '<C-w>j', 'Go to bottom window')
map('n', '<C-k>', '<C-w>k', 'Go to top window')
map('n', '<C-l>', '<C-w>l', 'Go to right window')

-- Buffer management
map('n', '<leader>bd', ':bdelete<CR>', 'Delete buffer')
map('n', '<leader>bn', ':bnext<CR>', 'Next buffer')
map('n', '<leader>bp', ':bprevious<CR>', 'Previous buffer')
```

### core/autocmds.lua - Autocommands and File Types

**Purpose**: Defines autocommands for file type handling, events, and automatic behaviors.

**Autocommand Categories**:

#### File Type Detection
- Custom file type associations
- Syntax highlighting setup
- File-specific settings

#### Editor Behavior
- Automatic formatting on save
- Cursor position restoration
- Highlight yanked text

#### Window Management
- Automatic window resizing
- Focus event handling

#### Terminal Integration
- Terminal mode settings
- Shell integration

**Key Autocommands**:

#### Highlight on Yank
```lua
-- Briefly highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({ higroup = 'Visual', timeout = 200 })
  end,
})
```

#### File Type Settings
```lua
-- Python-specific settings
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})
```

#### Auto-resize Windows
```lua
-- Automatically resize windows when Vim is resized
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    vim.cmd('wincmd =')
  end,
})
```

## User Override Integration

All core modules support user overrides through the user system:

### Options Override
Users can override any option by creating `user/overrides/options.lua`:
```lua
return {
  -- Override any vim option
  number = false,        -- Disable line numbers
  shiftwidth = 4,        -- Use 4-space indentation
  -- Add custom options
  custom_option = true,
}
```

### Keymaps Override
Users can override or add keymaps via `user/overrides/keymaps.lua`:
```lua
return {
  -- Override existing keymaps
  ['<leader>bd'] = { ':Bdelete<CR>', 'Delete buffer (using plugin)' },
  -- Add new keymaps
  ['<leader>xx'] = { ':CustomCommand<CR>', 'Custom command' },
}
```

### Autocmds Override
Users can add custom autocommands via `user/overrides/autocmds.lua`:
```lua
return {
  {
    event = 'BufWritePre',
    pattern = '*.lua',
    callback = function()
      -- Custom formatting for Lua files
    end,
  },
}
```

## Platform-Specific Behavior

The core modules automatically adapt to different platforms:

### macOS
- Uses system clipboard integration
- Command key mappings where appropriate
- macOS-specific terminal settings

### Linux
- X11 clipboard integration
- Linux-specific file paths
- Distribution-specific optimizations

### WSL Support
- WSL clipboard integration via clip.exe
- Unix path handling in WSL environment
- Cross-platform compatibility

## Performance Considerations

- **Lazy Loading**: Core modules are loaded only once during startup
- **Conditional Loading**: Platform-specific code only loads when needed
- **Efficient Options**: Options are set in batches to minimize overhead
- **Event Handling**: Autocommands use efficient event filtering

## Troubleshooting

### Common Issues

1. **Keymap Conflicts**: Check for conflicting keymaps in user overrides
2. **Option Not Working**: Verify option name and value in `user/overrides/options.lua`
3. **Platform Issues**: Check platform detection with `:lua print(require('core.utils').platform.get_os())`

### Debugging

```lua
-- Debug core module loading
:lua print(vim.inspect(require('core.utils')))

-- Check if core modules are loaded
:lua print(package.loaded['core.utils'])

-- Verify options are set
:lua print(vim.opt.number:get())
```

## Best Practices

1. **Don't Modify Core Files**: Use the user override system instead
2. **Platform Awareness**: Use utility functions for cross-platform compatibility
3. **Performance**: Prefer autocommands over manual checks for file events
4. **Consistency**: Follow the established patterns for keymaps and options 