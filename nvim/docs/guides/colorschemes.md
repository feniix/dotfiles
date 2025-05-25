# Neovim Colorscheme Guide

This guide explains how to use and customize the Catppuccin colorscheme in your Neovim setup, as well as how to switch to other colorschemes if desired.

## Table of Contents

1. [Using Catppuccin](#using-catppuccin)
2. [Switching Flavours](#switching-flavours)
3. [Customizing Catppuccin](#customizing-catppuccin)
4. [Switching to Other Colorschemes](#switching-to-other-colorschemes)
5. [Adding New Colorschemes](#adding-new-colorschemes)
6. [Troubleshooting](#troubleshooting)

## Using Catppuccin

Your Neovim configuration is set up to use Catppuccin, a modern colorscheme with multiple flavours and excellent plugin integration.

### Default Setup

Catppuccin is configured to use the "mocha" flavour (dark theme) by default. The colorscheme is loaded automatically when you start Neovim.

### Key Features

- Four beautiful flavours: Latte (light), Frappé, Macchiato, and Mocha (dark)
- Excellent integration with modern Neovim plugins
- Consistent color palette across all flavours
- Highly customizable with extensive configuration options

## Switching Flavours

You can switch between Catppuccin's four flavours:

### Available Flavours
- **Latte** - Light theme with warm tones
- **Frappé** - Dark theme with muted colors
- **Macchiato** - Dark theme with vibrant colors  
- **Mocha** - Dark theme with rich, deep colors (default)

### Temporary Switch
To temporarily switch flavours in your current session:

```
:Catppuccin latte
:Catppuccin frappe
:Catppuccin macchiato
:Catppuccin mocha
```

### Using Telescope
You can also browse and switch colorschemes using Telescope:
- Press `<leader>fc` to open colorscheme picker
- Navigate and preview different themes

## Customizing Catppuccin

The Catppuccin theme can be extensively customized to your preferences.

### Basic Customization

Edit the configuration file at:
```
~/dotfiles/nvim/lua/plugins/specs/ui.lua
```

Inside the Catppuccin setup function, you can modify these options:

```lua
require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false, -- Set to true for transparent background
  show_end_of_buffer = false,
  term_colors = false,
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  no_italic = false,    -- Disable italics
  no_bold = false,      -- Disable bold
  no_underline = false, -- Disable underlines
})
```

### Style Customization

You can customize specific syntax highlighting styles:

```lua
styles = {
  comments = { "italic" },
  conditionals = { "italic" },
  loops = {},
  functions = { "bold" },
  keywords = { "italic" },
  strings = {},
  variables = {},
  numbers = {},
  booleans = {},
  properties = {},
  types = { "bold" },
  operators = {},
},
```

### Plugin Integration

Catppuccin includes built-in integration for many plugins:

```lua
integrations = {
  cmp = true,
  gitsigns = true,
  nvimtree = true,
  treesitter = true,
  notify = true,
  diffview = true,
  telescope = true,
  which_key = true,
  indent_blankline = {
    enabled = true,
    colored_indent_levels = false,
  },
  mini = {
    enabled = true,
    indentscope_color = "",
  },
},
```

## Switching to Other Colorschemes

While Catppuccin is the default theme, you can temporarily switch to any other installed colorscheme.

### Temporary Switch

To temporarily switch colorschemes in your current session:

```
:colorscheme [name]
```

For example:
- `:colorscheme tokyonight`
- `:colorscheme gruvbox`
- `:colorscheme nord`

### Using Telescope

Press `<leader>fc` to open the colorscheme picker and preview themes interactively.

### Permanent Switch

To permanently switch to another colorscheme:

1. Edit the UI plugins file:
   ```
   nvim ~/dotfiles/nvim/lua/plugins/specs/ui.lua
   ```

2. Modify the Catppuccin configuration or replace it with your preferred theme.

## Adding New Colorschemes

To add a new colorscheme to your Neovim setup:

1. Edit the UI plugins file:
   ```
   nvim ~/dotfiles/nvim/lua/plugins/specs/ui.lua
   ```

2. Add your desired colorscheme to the return table:

```lua
{
  "your-colorscheme/plugin",
  lazy = false,
  priority = 1000,
  config = function()
    -- Optional: configure the colorscheme
    vim.cmd("colorscheme your-theme")
  end,
},
```

3. Run `:Lazy sync` to install

4. To test the new colorscheme:
   ```
   :colorscheme [new-theme-name]
   ```

### Example: Adding Tokyo Night

```lua
-- In lua/plugins/specs/ui.lua, add to the return table:
{
  'folke/tokyonight.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "night", -- storm, moon, night, day
    })
    -- Uncomment to make it default:
    -- vim.cmd("colorscheme tokyonight")
  end,
},
```

## Advanced Customization

### Custom Highlight Groups

You can override specific highlight groups after Catppuccin loads:

```lua
-- In the Catppuccin config function:
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*",
  callback = function()
    local colors = require("catppuccin.palettes").get_palette()
    vim.api.nvim_set_hl(0, "Comment", { fg = colors.overlay1, italic = true })
    vim.api.nvim_set_hl(0, "Function", { fg = colors.blue, bold = true })
  end,
})
```

### Transparent Background

To enable transparent background:

```lua
require("catppuccin").setup({
  transparent_background = true,
})
```

## Troubleshooting

### Common Issues

1. **Colorscheme not found**
   - Run `:Lazy sync` to ensure all plugins are installed
   - Check if the theme is correctly specified in your plugins file
   - Verify the correct theme name with `:colorscheme` + TAB

2. **Colors don't look right**
   - Ensure your terminal supports true colors: `export TERM=xterm-256color`
   - Verify `vim.opt.termguicolors = true` is set in your config
   - Check terminal color palette settings

3. **Theme not applying on startup**
   - Check ui.lua for errors in the colorscheme section
   - Ensure the colorscheme name is spelled correctly
   - Verify the plugin is installed via `:Lazy`

4. **Plugin integrations not working**
   - Ensure the integration is enabled in the Catppuccin setup
   - Check that the plugin is loaded after Catppuccin
   - Restart Neovim after configuration changes

### Getting Help

If you encounter issues with your colorscheme:

1. Check the [Catppuccin documentation](https://github.com/catppuccin/nvim)
2. Try the theme's GitHub issues page
3. Use `:checkhealth` to verify plugin status

## Resources

- [Catppuccin for Neovim](https://github.com/catppuccin/nvim)
- [Catppuccin Website](https://catppuccin.com/)
- [Neovim Highlight Groups](https://neovim.io/doc/user/syntax.html#highlight-groups)
- [Catppuccin Palette](https://github.com/catppuccin/catppuccin#-palette) 