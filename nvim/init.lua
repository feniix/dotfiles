-- Neovim Configuration with Packer
-- This is the entry point for all Neovim configuration

-- Load the core init file that defines basic utilities
require('init')

-- Load core functionality
require('user.options').setup()
require('user.keymaps').setup()
require('user.autocmds').setup()

-- Note: filetype and syntax are enabled by default in Neovim

-- Configure Terraform
vim.g.terraform_align = 0
vim.g.terraform_fmt_on_save = 0

-- Configure Go settings
vim.g.go_fmt_command = 'goimports'
vim.g.go_list_type = 'quickfix'
vim.g.go_test_timeout = '10s'
vim.g.go_highlight_types = 1
vim.g.go_highlight_fields = 1
vim.g.go_highlight_functions = 1
vim.g.go_highlight_methods = 1
vim.g.go_highlight_operators = 1
vim.g.go_highlight_build_constraints = 1
vim.g.go_highlight_function_calls = 1
vim.g.go_highlight_extra_types = 1
vim.g.go_highlight_generate_tags = 1
-- Re-enable vim-go features (using gopls for basic completion, but not full LSP setup)
vim.g.go_gopls_enabled = 1
vim.g.go_code_completion_enabled = 1
vim.g.go_doc_keywordprg_enabled = 1
vim.g.go_mod_fmt_autosave = 1
vim.g.go_fmt_autosave = 1
vim.g.go_imports_autosave = 1
vim.g.go_diagnostics_enabled = 1
vim.g.go_metalinter_enabled = 1

-- Load plugins via Packer
require('user.plugins')

-- Setup NeoSolarized through our colorbuddy setup
local colorbuddy_setup = safe_require('user.colorbuddy_setup')
if colorbuddy_setup then
  -- Initialize NeoSolarized theme
  colorbuddy_setup.setup()
  
  -- Create a command to toggle between light and dark modes
  vim.api.nvim_create_user_command('ToggleTheme', function()
    colorbuddy_setup.toggle_theme()
  end, { desc = 'Toggle between light and dark Solarized themes' })
else
  vim.notify("NeoSolarized setup failed. Run :PackerSync to install required plugins.", vim.log.levels.WARN)
end

-- Initialize plugins

-- Setup todo-comments
if safe_require('todo-comments') then
  require('todo-comments').setup({
    signs = true,
    keywords = {
      FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      NOTE = { icon = " ", color = "hint", alt = { "INFO" } }
    }
  })
end

-- Note: nvim-cmp is now lazy-loaded in plugins.lua

-- Note: Treesitter is now lazy-loaded in plugins.lua

-- Setup TreeSitter troubleshooting helpers
if not vim.g.skip_treesitter_setup and safe_require('user.setup_treesitter') then
  local ts_setup = require('user.setup_treesitter')
  
  -- Create command to manually install parsers
  vim.api.nvim_create_user_command('InstallTSParsers', function()
    ts_setup.install_parsers()
  end, { desc = 'Install TreeSitter parsers that might fail with the standard process' })

  -- Create command to specifically fix the vim parser
  vim.api.nvim_create_user_command('FixVimParser', function()
    ts_setup.install_vim_parser()
  end, { desc = 'Manually install the Vim TreeSitter parser' })
end

-- Setup plugin installer
if not vim.g.skip_plugin_installer and safe_require('user.plugin_installer') then
  require('user.plugin_installer').create_commands()
end

-- Setup configuration tester
if safe_require('user.config_test') then
  require('user.config_test').create_commands()
end

-- Note: DAP is now lazy-loaded in plugins.lua

-- Setup additional modules
if safe_require('nvim-autopairs') then
  require('nvim-autopairs').setup{}
end

-- Setup gitsigns (replacement for vim-gitgutter)
if safe_require('gitsigns') then
  require('gitsigns').setup({
    signs = {
      add          = { text = '┃' },
      change       = { text = '┃' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol',
      delay = 1000,
    },
  })
end

-- Setup nvim-surround (replacement for vim-surround)
if safe_require('nvim-surround') then
  require('nvim-surround').setup{}
end

-- Setup retrail (replacement for vim-better-whitespace)
if safe_require('retrail') then
  require('retrail').setup({
    trim = {
      auto = true,
      whitespace = true,
      blanklines = false,
    }
  })
end

-- Setup Comment.nvim
if safe_require('Comment') then
  local comment_config = {
    -- Basic Comment.nvim setup
  }
  
  -- Add ts-context-commentstring integration if available
  local ts_context_ok, ts_context = pcall(require, 'ts_context_commentstring.integrations.comment_nvim')
  if ts_context_ok then
    comment_config.pre_hook = ts_context.create_pre_hook()
  end
  
  require('Comment').setup(comment_config)
end

-- Setup lualine (replacement for vim-airline)
if safe_require('lualine') then
  require('lualine').setup({
    options = {
      theme = 'auto', -- Set to 'auto' to match current colorscheme
      icons_enabled = true,
      component_separators = { left = '', right = ''},
      section_separators = { left = '', right = ''},
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff'},
      lualine_c = {'filename'},
      lualine_x = {'encoding', 'fileformat', 'filetype'},
      lualine_y = {'progress'},
      lualine_z = {'location'}
    },
    tabline = {
      lualine_a = {'buffers'},
      lualine_z = {'tabs'}
    },
    extensions = {'fugitive'}
  })
end

-- Setup rainbow-delimiters (replacement for rainbow)
if safe_require('rainbow-delimiters') then
  local rainbow_delimiters = require('rainbow-delimiters')
  if rainbow_delimiters and rainbow_delimiters.strategy then
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = rainbow_delimiters.strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
      },
    }
  end
end

-- Setup nvim-web-devicons
if safe_require('nvim-web-devicons') then
  require('nvim-web-devicons').setup({
    -- Enable folder icons
    override_folder_icon = true,
    -- Enable default icons
    default = true,
    -- Enable strict mode (only use specified icon patterns)
    strict = true,
    -- Override specific file icons
    override = {
      -- Custom file icon overrides can be added here if needed
    },
    -- Same color for all identical icons
    color_icons = true,
  })
end

-- Setup mouse right-click menu for terminal Neovim
if vim.fn.has('nvim') == 1 then
  vim.cmd([[
    aunmenu PopUp
    menu PopUp.Copy                      "+y
    menu PopUp.Paste                     "+gP
    menu PopUp.Select\ All               ggVG
  ]])
end

-- Setup ts_context_commentstring
if safe_require('ts_context_commentstring') then
  -- Skip the deprecated module to speed up loading
  vim.g.skip_ts_context_commentstring_module = true
  
  require('ts_context_commentstring').setup({
    enable_autocmd = false, -- Let Comment.nvim handle this
  })
end

-- iTerm2 specific integrations
if is_iterm2() then
  vim.cmd('set termguicolors')
end

-- Standard K keymap behavior (no LSP)
vim.api.nvim_set_keymap('n', 'K', 'K', { noremap = true, silent = true })

-- Helper function for Go files - must be defined at global scope
function _G.build_go_files()
  require('user.go').build_go_files()
end 