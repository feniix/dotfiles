# User Override System

The user override system provides a comprehensive way to customize every aspect of your Neovim configuration without modifying the core files. This allows you to maintain your personal customizations while keeping the base configuration clean and updateable.

## 📁 Directory Structure

```
user/
├── init.lua                          # Main user override system
├── config.lua                        # Your personal configuration (create from config.lua.example)
├── config.lua.example                # Example configuration file
├── overrides/                        # Override modules for core functionality
│   ├── options.lua                   # Override vim options
│   ├── keymaps.lua                   # Override keymaps
│   ├── autocmds.lua                  # Override autocommands
│   └── plugins/                      # Plugin-specific overrides
│       └── telescope.lua             # Example telescope override
├── modules/                          # Custom user modules
│   └── my_custom_module.lua.example  # Example custom module
└── README.md                         # This documentation
```

## 🚀 Quick Start

### 1. Create Your Configuration

```bash
# Copy the example configuration
cp ~/.config/nvim/lua/user/config.lua.example ~/.config/nvim/lua/user/config.lua
```

### 2. Edit Your Configuration

```lua
-- In ~/.config/nvim/lua/user/config.lua
local M = {}

-- Override vim options
M.options = {
  tabstop = 2,
  shiftwidth = 2,
  relativenumber = false,
}

-- Add custom keymaps
M.keymaps = {
  normal = {
    ['<leader>w'] = ':w<CR>',
    ['<leader>q'] = ':q<CR>',
  },
}

return M
```

### 3. Restart Neovim

Your customizations will be automatically applied!

## 📋 Configuration Options

### Core Customizations

#### Override Vim Options

```lua
M.options = {
  -- Tab settings
  tabstop = 4,
  shiftwidth = 4,
  expandtab = true,
  
  -- Visual settings
  colorcolumn = '100',
  relativenumber = false,
  cursorline = true,
  
  -- Behavior settings
  ignorecase = true,
  smartcase = true,
  wrap = false,
}
```

#### Override Keymaps

```lua
M.keymaps = {
  -- Normal mode mappings
  normal = {
    ['<leader>w'] = ':w<CR>',
    ['<leader>q'] = ':q<CR>',
    ['<C-h>'] = '<C-w>h',
    ['<C-j>'] = '<C-w>j',
    ['<C-k>'] = '<C-w>k',
    ['<C-l>'] = '<C-w>l',
  },
  
  -- Insert mode mappings
  insert = {
    ['jk'] = '<Esc>',
    ['<C-a>'] = '<Home>',
    ['<C-e>'] = '<End>',
  },
  
  -- Visual mode mappings
  visual = {
    ['<leader>y'] = '"+y',
    ['<leader>p'] = '"+p',
  },
  
  -- Advanced mapping with options
  normal = {
    ['<leader>ff'] = {
      '<cmd>Telescope find_files<CR>',
      desc = 'Find files',
      silent = true,
      noremap = true,
    },
  },
}
```

#### Override Autocommands

```lua
M.autocmds = {
  -- File type specific settings
  {
    event = 'FileType',
    pattern = 'markdown',
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  },
  
  -- Auto-save functionality
  {
    event = 'FocusLost',
    pattern = '*',
    command = 'silent! wa',
  },
  
  -- Highlight yanked text
  {
    event = 'TextYankPost',
    pattern = '*',
    callback = function()
      vim.highlight.on_yank({ timeout = 300 })
    end,
  },
}
```

### Plugin Customizations

#### Add Custom Plugins

```lua
M.plugins = {
  specs = {
    -- Add UI plugins
    ui = {
      {
        'folke/zen-mode.nvim',
        cmd = 'ZenMode',
        config = function()
          require('zen-mode').setup({
            window = { width = 120 }
          })
        end,
      },
    },
    
    -- Add editor plugins
    editor = {
      {
        'tpope/vim-surround',
        event = 'VeryLazy',
      },
    },
    
    -- Add language-specific plugins
    lang = {
      {
        'iamcco/markdown-preview.nvim',
        ft = 'markdown',
        build = function()
          vim.fn['mkdp#util#install']()
        end,
      },
    },
  },
}
```

#### Override Plugin Configurations

```lua
M.plugins = {
  config = {
    -- Override telescope settings
    telescope = {
      defaults = {
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = {
            width = 0.9,
            height = 0.8,
          },
        },
      },
    },
    
    -- Override treesitter settings
    treesitter = {
      ensure_installed = { 'lua', 'vim', 'markdown' },
      highlight = {
        additional_vim_regex_highlighting = true,
      },
    },
  },
}
```

#### Override Lazy.nvim Configuration

```lua
M.lazy_config = {
  checker = {
    enabled = true,
    notify = true,
    frequency = 3600,
  },
  
  ui = {
    border = 'rounded',
    size = {
      width = 0.8,
      height = 0.8,
    },
  },
}
```

### Custom Modules

Create custom modules for complex functionality:

```lua
-- In user/modules/my_workflow.lua
local M = {}

function M.setup()
  -- Create custom commands
  vim.api.nvim_create_user_command('ProjectSetup', function()
    -- Your project setup logic
  end, {})
  
  -- Set up custom keymaps
  vim.keymap.set('n', '<leader>ps', '<cmd>ProjectSetup<CR>', {
    desc = 'Setup project'
  })
end

return M
```

Then load it in your config:

```lua
M.modules = {
  'my_workflow',
  'git_helpers',
  'project_management',
}
```

### Post-Setup Hook

Execute custom logic after all setup is complete:

```lua
function M.post_setup()
  -- Set up custom commands
  vim.api.nvim_create_user_command('ReloadConfig', function()
    vim.cmd('source ~/.config/nvim/init.lua')
    print('Configuration reloaded!')
  end, {})
  
  -- Set up custom highlights
  vim.api.nvim_set_hl(0, 'CustomHighlight', {
    fg = '#ff0000',
    bold = true,
  })
  
  -- Project-specific settings
  local project_nvimrc = vim.fn.getcwd() .. '/.nvimrc.lua'
  if vim.fn.filereadable(project_nvimrc) == 1 then
    dofile(project_nvimrc)
  end
end
```

## 🔧 Advanced Customization

### Creating Override Modules

For complex customizations, create override modules:

```lua
-- In user/overrides/plugins/my_plugin.lua
local M = {}

function M.setup(user_config)
  -- Custom setup logic for the plugin
  local ok, plugin = pcall(require, 'my_plugin')
  if ok then
    plugin.setup(user_config)
  end
end

function M.override(default_config, user_config)
  return vim.tbl_deep_extend('force', default_config, user_config)
end

return M
```

### Conditional Customizations

```lua
-- Platform-specific settings
if vim.fn.has('mac') == 1 then
  M.options.guifont = 'SF Mono:h14'
elseif vim.fn.has('unix') == 1 then
  M.options.guifont = 'Ubuntu Mono 14'
end

-- Environment-specific settings
local hostname = vim.fn.hostname()
if string.match(hostname, 'work') then
  -- Work-specific plugins
  M.plugins.specs.tools = {
    {
      'zbirenbaum/copilot.lua',
      event = 'InsertEnter',
      config = function()
        require('copilot').setup()
      end,
    },
  }
end
```

## 📚 Examples

### Complete Configuration Example

```lua
-- ~/.config/nvim/lua/user/config.lua
local M = {}

-- Core settings
M.options = {
  tabstop = 2,
  shiftwidth = 2,
  expandtab = true,
  relativenumber = false,
  colorcolumn = '100',
}

M.keymaps = {
  normal = {
    ['<leader>w'] = ':w<CR>',
    ['<leader>q'] = ':q<CR>',
    ['<leader>ff'] = '<cmd>Telescope find_files<CR>',
    ['<leader>fg'] = '<cmd>Telescope live_grep<CR>',
  },
  insert = {
    ['jk'] = '<Esc>',
  },
}

M.autocmds = {
  {
    event = 'FileType',
    pattern = 'markdown',
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  },
}

-- Plugin customizations
M.plugins = {
  specs = {
    ui = {
      {
        'folke/zen-mode.nvim',
        cmd = 'ZenMode',
        config = function()
          require('zen-mode').setup({
            window = { width = 120 }
          })
        end,
      },
    },
  },
  
  config = {
    telescope = {
      defaults = {
        layout_strategy = 'horizontal',
      },
    },
  },
}

-- Custom modules
M.modules = {
  'my_custom_module',
}

-- Post-setup hook
function M.post_setup()
  vim.api.nvim_create_user_command('EditUserConfig', function()
    vim.cmd('edit ~/.config/nvim/lua/user/config.lua')
  end, {})
  
  vim.keymap.set('n', '<leader>ce', '<cmd>EditUserConfig<CR>', {
    desc = 'Edit user config'
  })
end

return M
```

## 🛠️ Utilities

The user override system provides several utility functions:

```lua
local user = require('user')

-- Check if an override exists
if user.has_override('plugins.telescope') then
  -- Apply custom telescope setup
end

-- Apply override with fallback
local config = user.apply_override('options', default_options, user_options)

-- Safely merge tables
local merged = user.safe_override(original_table, override_table)

-- Safely extend lists
local extended = user.safe_extend(original_list, extension_list)
```

## 🔄 Reloading Configuration

The user override system supports hot-reloading:

```lua
-- Create a reload command (in your config or module)
vim.api.nvim_create_user_command('ReloadUserConfig', function()
  package.loaded['user.config'] = nil
  package.loaded['user.init'] = nil
  
  local user = require('user')
  user.setup_core_overrides()
  user.setup_plugin_overrides()
  user.run_post_setup_hooks()
  
  vim.notify('User configuration reloaded!', vim.log.levels.INFO)
end, {})
```

## 🐛 Troubleshooting

### Common Issues

1. **Configuration not loading**: Check that your `config.lua` file is in the correct location and has valid Lua syntax.

2. **Plugin overrides not working**: Ensure the plugin override module exists and has the correct `setup()` function.

3. **Keymaps not working**: Check for conflicts with existing keymaps and ensure the mapping format is correct.

### Debug Commands

```vim
:lua print(vim.inspect(require('user.config')))  " View your configuration
:messages                                         " View error messages
:checkhealth                                      " Check system health
```

## 📖 Best Practices

1. **Start Small**: Begin with simple overrides and gradually add complexity.

2. **Use Comments**: Document your customizations for future reference.

3. **Test Changes**: Test overrides in a separate Neovim instance before applying permanently.

4. **Backup Configuration**: Keep a backup of your working configuration.

5. **Modular Design**: Use custom modules for complex functionality.

6. **Conditional Logic**: Use platform and environment detection for flexible configurations.

## 🤝 Contributing

If you create useful override modules or configurations, consider sharing them with the community by creating examples or documentation.

---

The user override system makes it easy to customize every aspect of your Neovim configuration while maintaining a clean, updateable base setup. Start with simple overrides and gradually build up your perfect development environment! 🚀 