# Neovim Colorscheme Guide

This guide explains how to use and customize the NeoSolarized colorscheme in your Neovim setup, as well as how to switch to other colorschemes if desired.

## Table of Contents

1. [Using NeoSolarized](#using-neosolarized)
2. [Toggling Light and Dark Modes](#toggling-light-and-dark-modes)
3. [Customizing NeoSolarized](#customizing-neosolarized)
4. [Switching to Other Colorschemes](#switching-to-other-colorschemes)
5. [Adding New Colorschemes](#adding-new-colorschemes)
6. [Troubleshooting](#troubleshooting)

## Using NeoSolarized

Your Neovim configuration is set up to use NeoSolarized, a modern implementation of the classic Solarized colorscheme using the ColorBuddy framework.

### Default Setup

NeoSolarized is configured to start in dark mode by default. The colorscheme is loaded automatically when you start Neovim.

### Key Features

- Based on the classic Solarized color palette
- Enhanced for modern Neovim features (Treesitter, LSP)
- Supports both light and dark variants
- Built with ColorBuddy for easier customization

## Toggling Light and Dark Modes

You can easily switch between light and dark variants of the Solarized theme:

1. Inside Neovim, run the command:
   ```
   :ToggleTheme
   ```

2. This will switch from dark to light mode or vice versa.

3. You can also manually set a specific mode:
   - For dark mode: `:set background=dark`
   - For light mode: `:set background=light`

## Customizing NeoSolarized

The NeoSolarized theme can be customized to your preferences.

### Basic Customization

Edit the configuration file at:
```
~/dotfiles/nvim/lua/user/colorbuddy_setup.lua
```

Inside this file, you can modify the NeoSolarized setup options:

```lua
neosolarized.setup({
  comment_italics = true,     -- Enable/disable italics for comments
  background_set = false,     -- Let Neovim control the background
  transparent = false,        -- Set to true for transparent background
})
```

### Advanced Customization

For more advanced customization, you can use ColorBuddy to define or override specific highlight groups after the theme is loaded. Add your customizations to the setup function in `colorbuddy_setup.lua`:

```lua
-- After neosolarized.setup() call:
local Color = require('colorbuddy').Color
local Group = require('colorbuddy').Group
local colors = require('colorbuddy').colors
local styles = require('colorbuddy').styles

-- Modify existing colors
colors.red = colors.red:light()

-- Override specific highlight groups
Group.new('Comment', colors.base01, nil, styles.italic)
Group.new('Function', colors.blue, nil, styles.bold)
```

## Switching to Other Colorschemes

While NeoSolarized is the default theme, you can temporarily switch to any other installed colorscheme.

### Temporary Switch

To temporarily switch colorschemes in your current session:

```
:colorscheme [name]
```

For example:
- `:colorscheme tokyonight`
- `:colorscheme gruvbox`
- `:colorscheme nord`

### Permanent Switch

To permanently switch to another colorscheme:

1. Edit your Neovim config file:
   ```
   nvim ~/dotfiles/nvim/init.lua
   ```

2. Find the colorscheme section and modify it to use your preferred theme.

## Adding New Colorschemes

To add a new colorscheme to your Neovim setup:

1. Edit the plugins file:
   ```
   nvim ~/dotfiles/nvim/lua/user/plugins.lua
   ```

2. Add your desired colorscheme within the Packer setup function:
   ```lua
   -- Example: Add the TokyoNight colorscheme
   use 'folke/tokyonight.nvim'
   
   -- Example: Add the Gruvbox colorscheme
   use 'sainnhe/gruvbox-material'
   ```

3. Save the file and run:
   ```
   :PackerSync
   ```

4. To test the new colorscheme:
   ```
   :colorscheme [new-theme-name]
   ```

5. To make it the default, update the setup in `~/dotfiles/nvim/init.lua`

### Example: Adding Tokyo Night

```lua
-- In plugins.lua
use 'folke/tokyonight.nvim'

-- Then in init.lua (after installing), replace or modify the colorscheme section:
-- vim.cmd('colorscheme tokyonight')
```

## Troubleshooting

### Common Issues

1. **Colorscheme not found**
   - Run `:PackerSync` to ensure all plugins are installed
   - Check if the theme is correctly specified in your plugins file
   - Verify the correct theme name with `:colorscheme` + TAB

2. **Colors don't look right**
   - Ensure your terminal supports true colors: `export TERM=xterm-256color`
   - Add to your init.lua: `vim.opt.termguicolors = true`
   - Check terminal color palette settings

3. **Theme not applying on startup**
   - Check init.lua for errors in the colorscheme section
   - Ensure the colorscheme name is spelled correctly
   - Verify the plugin is installed via `:PackerStatus`

### Getting Help

If you encounter issues with your colorscheme:

1. Check the documentation for the specific theme
2. Try the theme's GitHub issues page
3. For ColorBuddy-specific issues, see the ColorBuddy documentation

## Resources

- [NeoSolarized GitHub](https://github.com/svrana/neosolarized.nvim)
- [ColorBuddy GitHub](https://github.com/tjdevries/colorbuddy.nvim)
- [Neovim Highlight Groups](https://neovim.io/doc/user/syntax.html#highlight-groups)
- [Original Solarized](https://ethanschoonover.com/solarized/) 