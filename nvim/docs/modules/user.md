# User Override System Documentation

The user override system lets you customize the Neovim configuration without editing core files. Your settings live in `lua/user/config.lua`; `lua/user/init.lua` reads it and applies each part at the right point during startup.

## Files

```
user/
├── init.lua                    # Loader: reads user.config and applies it
├── config.lua                  # Your configuration (keys described below)
├── config.lua.example          # Fuller example of every key
├── health.lua                  # :checkhealth user
├── README.md                   # User documentation
├── overrides/                  # Code that applies each part of config.lua
│   ├── options.lua             # Applies config.options
│   ├── keymaps.lua             # Applies config.keymaps
│   ├── autocmds.lua            # Applies config.autocmds
│   └── plugins/                # One module per plugins.config entry
│       ├── platform.lua
│       └── telescope.lua
└── modules/                    # Your own modules, listed in config.modules
    └── my_custom_module.lua.example
```

You edit `config.lua`. The `overrides/` modules are the code that applies it; you only add to `overrides/plugins/` when you want a new `plugins.config` entry.

## Getting Started

```bash
cd ~/.config/nvim/lua/user
cp config.lua.example config.lua
```

Leave a key out to keep the defaults. An empty table still counts as set.

## Configuration Keys

`config.lua` returns a table. The loader reads exactly these keys:

| Key | Type | Applied by | When |
|-----|------|-----------|------|
| `options` | table | `overrides/options.lua` | after core setup |
| `keymaps` | table | `overrides/keymaps.lua` | after core setup |
| `autocmds` | list | `overrides/autocmds.lua` | after core setup |
| `plugins.specs` | table of lists | `plugins/init.lua` | added to lazy.nvim's specs |
| `plugins.config` | table | `overrides/plugins/<name>.lua` | shortly after lazy.nvim setup |
| `lazy_config` | table | `plugins/init.lua` | deep-merged into lazy.nvim's options |
| `modules` | list of names | `user.modules.<name>` | after plugin setup |
| `post_setup` | function | loader | after plugin setup |

### `options`

Each key is a Vim option set with `vim.opt`. Keys prefixed with `g:`, `b:` or `w:` set `vim.g`, `vim.b` or `vim.w` variables instead.

```lua
M.options = {
  tabstop = 4,
  shiftwidth = 4,
  colorcolumn = '100',
  ['g:python_format_on_save'] = true,
}
```

### `keymaps`

Two formats are accepted. A list of `{ mode, lhs, rhs, opts }` entries:

```lua
M.keymaps = {
  { 'n', '<leader>w', ':w<CR>', { desc = 'Save file' } },
}
```

or a table keyed by mode, where each value is an rhs string or a table with the rhs first plus keymap options:

```lua
M.keymaps = {
  n = {
    ['<leader>w'] = ':w<CR>',
    ['<leader>W'] = { ':wa<CR>', desc = 'Save all' },
  },
  i = { ['jk'] = '<Esc>' },
}
```

Both default to `silent = true, noremap = true`.

### `autocmds`

A list of tables with an `event` plus any `nvim_create_autocmd` options. They are created in the `UserOverrides` augroup, which is cleared each time the overrides are applied.

```lua
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
```

### `plugins.specs`

Extra lazy.nvim plugin specs, grouped under any category name. Every list is appended to the plugin specs; the category names are only for your own organization.

```lua
M.plugins = {
  specs = {
    editor = {
      { 'folke/zen-mode.nvim', cmd = 'ZenMode', opts = {} },
    },
  },
}
```

### `plugins.config`

Each entry `name = value` calls `require('user.overrides.plugins.<name>').setup(value)`. An entry is skipped when no such module exists, so adding one means also adding its module under `overrides/plugins/`. The shipped `telescope.lua` merges the table into the platform-aware Telescope defaults and calls `telescope.setup()`.

```lua
M.plugins = {
  config = {
    telescope = {
      defaults = { layout_strategy = 'vertical' },
    },
  },
}
```

### `lazy_config`

Deep-merged into the options passed to `require('lazy').setup()`.

```lua
M.lazy_config = {
  checker = { enabled = true, notify = true },
}
```

### `modules`

Names of modules under `lua/user/modules/`. Each one is required and its `setup()` called, if it has one.

```lua
M.modules = { 'my_custom_module' }  -- loads lua/user/modules/my_custom_module.lua
```

### `post_setup`

A function called once plugin setup has run.

```lua
function M.post_setup()
  vim.api.nvim_set_hl(0, 'CustomHighlight', { fg = '#ff0000', bold = true })
end
```

## Custom User Modules

Create a module in `user/modules/` and list its name in `modules`:

```lua
-- user/modules/my_custom_module.lua
local M = {}

function M.setup()
  vim.api.nvim_create_user_command('EditUserConfig', function()
    vim.cmd('edit ' .. vim.fn.stdpath('config') .. '/lua/user/config.lua')
  end, { desc = 'Edit user configuration file' })
end

return M
```

```lua
-- user/config.lua
M.modules = { 'my_custom_module' }
```

See `my_custom_module.lua.example` for a larger example.

## Loader Utilities

`require('user')` also exposes helpers for your own modules:

- `safe_override(original, override)`: deep-merges `override` into a copy of `original`.
- `safe_extend(original, extension)`: appends a list to a copy of `original`.
- `has_override(path)`: whether `user.overrides.<path>` can be required.
- `apply_override(path, default, config)`: calls that module's `override(default, config)` if it exists.

## Reloading

`:ReloadConfig` (or `<leader>pr`) clears and re-runs `core.options`, `core.keymaps` and the `user` modules, then applies `options`, `keymaps` and `autocmds` again. lazy.nvim cannot re-source the whole config, so changes to `plugins.*`, `lazy_config`, `modules` or `post_setup` need a restart.

## Health Checks

```vim
:checkhealth user
```

## Conditional Configuration

`config.lua` is plain Lua, so you can branch on the platform or environment:

```lua
local M = { options = {} }

if vim.fn.has('mac') == 1 then
  M.options.guifont = 'SF Mono:h14'
end

if os.getenv('WORK_ENV') then
  M.options.colorcolumn = '120'
end

return M
```

## Troubleshooting

```vim
" What the loader sees
:lua print(vim.inspect(require('user.config')))

" Whether a custom module loaded
:lua print(package.loaded['user.modules.my_custom_module'])
```

1. **Configuration not applied**: check `user/config.lua` for syntax errors, check the key names against the table above, and run `:checkhealth user`.
2. **Keymap conflicts**: use `:Telescope keymaps` or which-key to find the existing mapping.
3. **`plugins.config` entry ignored**: there must be a matching `user/overrides/plugins/<name>.lua` with a `setup()` function.

### Reset to Defaults

```bash
cd ~/.config/nvim/lua/user
mv config.lua config.lua.backup
# Restart Neovim to use the default configuration
```

## Related User Guides

- [Which-Key Guide](../guides/which-key.md) - Keymap customization examples
- [Health Checks Guide](../guides/health-checks.md) - System validation workflows
- [Cross-Platform Guide](../guides/cross-platform.md) - Platform-specific customizations
