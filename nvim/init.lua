-- Neovim Configuration with Packer
-- This is the entry point for all Neovim configuration

-- Load the core init file that defines basic utilities
require('init')

-- Load core functionality
require('user.options').setup()
require('user.keymaps').setup()
require('user.autocmds').setup()

-- Filetype and syntax
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

-- Configure Terraform
vim.g.terraform_align = 0
vim.g.terraform_fmt_on_save = 0

-- Configure Go settings
vim.g.go_fmt_command = 'goimports'
vim.g.go_list_type = 'quickfix'
vim.g.go_test_timeout = '10s'
vim.g.go_highlight_types = 0  -- Let tree-sitter handle highlighting
vim.g.go_highlight_fields = 0
vim.g.go_highlight_functions = 0
vim.g.go_highlight_methods = 0
vim.g.go_highlight_operators = 0
vim.g.go_highlight_build_constraints = 0
vim.g.go_highlight_function_calls = 0
vim.g.go_highlight_extra_types = 0
vim.g.go_highlight_generate_tags = 0
vim.g.go_def_mode = 'gopls'
vim.g.go_info_mode = 'gopls'
vim.g.go_gopls_enabled = 0  -- Disable gopls in vim-go as we use LSP
vim.g.go_code_completion_enabled = 0  -- Disable vim-go completion as we use LSP
vim.g.go_doc_keywordprg_enabled = 0   -- Disable K mapping as we use LSP
vim.g.go_mod_fmt_autosave = 0         -- LSP handles formatting
vim.g.go_fmt_autosave = 0             -- LSP handles formatting
vim.g.go_imports_autosave = 0         -- LSP handles formatting
vim.g.go_diagnostics_enabled = 0      -- LSP handles diagnostics
vim.g.go_metalinter_enabled = 0       -- LSP handles linting

-- Load plugins via Packer
require('user.plugins')

-- Set colorscheme using NeoSolarized
vim.cmd('set background=dark')
-- Setup NeoSolarized through our colorbuddy setup
local colorbuddy_ok, colorbuddy_setup = pcall(require, 'user.colorbuddy_setup')
if colorbuddy_ok then
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

-- Setup nvim-cmp
if safe_require('cmp') and safe_require('luasnip') then
  local cmp = require('cmp')
  local luasnip = require('luasnip')
  
  -- Load friendly-snippets if available
  pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
      { name = 'path' },
    })
  })

  -- Use buffer source for `/` search
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':'
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
end

-- Setup Mason (do this before LSP)
if safe_require('user.mason') then
  require('user.mason').setup()
end

-- Setup LSP if available
safe_require('user.lsp').setup()

-- Setup Treesitter if available
if safe_require('user.treesitter') then
  require('user.treesitter').setup()
end

-- Setup TypeScript if available
if not vim.g.skip_ts_tools and safe_require('user.typescript') then
  require('user.typescript').setup()
end

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

-- Setup Go development
if safe_require('user.go') then
  require('user.go').setup({
    auto_install_tools = true, -- Set to false to disable automatic installation
    suppress_mason_notifications = true -- Suppress repetitive notifications about Mason tools
  })
end

-- Setup DAP (Debugging)
if safe_require('user.dap') then
  require('user.dap').setup()
end

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
  require('Comment').setup({
    -- Add ts-context-commentstring integration
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  })
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
      lualine_b = {'branch', 'diff', 'diagnostics'},
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

-- Setup custom popup menu for mouse right-click (VSCode-style)
vim.cmd([[
  " Clear existing PopUp menu
  aunmenu PopUp
  
  " Define VSCode-like popup menu items
  menu PopUp.Cut                      "+d
  menu PopUp.Copy                     "+y
  menu PopUp.Paste                    "+p
  menu PopUp.-sep1-                   :
  menu PopUp.Go\ To\ Definition       :lua vim.lsp.buf.definition()<CR>
  menu PopUp.Peek\ Definition         :lua require('telescope.builtin').lsp_definitions()<CR>
  menu PopUp.Go\ To\ References       :lua vim.lsp.buf.references()<CR>
  menu PopUp.Go\ To\ Implementations  :lua vim.lsp.buf.implementation()<CR>
  menu PopUp.Find\ Symbol             :lua require('telescope.builtin').lsp_document_symbols()<CR>
  menu PopUp.-sep2-                   :
  menu PopUp.Rename\ Symbol           :lua vim.lsp.buf.rename()<CR>
  menu PopUp.Format\ Document         :lua vim.lsp.buf.format({ async = true })<CR>
  menu PopUp.Code\ Actions            :lua vim.lsp.buf.code_action()<CR>
  menu PopUp.-sep3-                   :
  menu PopUp.Toggle\ Breakpoint       :lua require('dap').toggle_breakpoint()<CR>
  menu PopUp.-sep4-                   :
  menu PopUp.Select\ All              ggVG
  
  " Include editor context menus
  menu PopUp.Command\ Palette         :Telescope commands<CR>
]])

-- Set up auto-hover documentation (VSCode-like)
vim.cmd([[
  " Show documentation on hover (K) automatically
  autocmd CursorHold * lua vim.lsp.buf.hover()
  
  " Set updatetime for CursorHold
  " 300ms of no cursor movement to trigger CursorHold
  set updatetime=300
]])

-- Setup ts_context_commentstring
if safe_require('ts_context_commentstring') then
  -- Skip the deprecated module to speed up loading
  vim.g.skip_ts_context_commentstring_module = true
  
  require('ts_context_commentstring').setup({
    enable_autocmd = false, -- Let Comment.nvim handle this
  })
end

-- iTerm2 specific integrations
vim.cmd([[
  " Check if we're in iTerm2
  if $TERM_PROGRAM ==# "iTerm.app" || $TERM =~# "^iterm" || $LC_TERMINAL ==# "iTerm2"
    " Enable true color support
    set termguicolors
  endif
]])

-- Create Packer commands
vim.api.nvim_create_user_command('PackerInstall', function()
  vim.cmd('PackerInstall')
end, { desc = 'Install missing plugins' })

vim.api.nvim_create_user_command('PackerUpdate', function()
  -- Reload the plugins module first
  package.loaded['user.plugins'] = nil
  require('user.plugins')
  -- Then run PackerSync
  vim.cmd('PackerSync')
end, { desc = 'Reload plugins configuration and run PackerSync' })

vim.api.nvim_create_user_command('PackerClean', function()
  vim.cmd('PackerClean')
end, { desc = 'Remove unused plugins' })

-- Helper function for Go files - must be defined at global scope
function _G.build_go_files()
  local file = vim.fn.expand('%')
  if file:match('_test%.go$') then
    vim.cmd('GoTest')
  elseif file:match('%.go$') then
    vim.cmd('GoBuild')
  end
end 