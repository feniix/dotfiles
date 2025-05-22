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

-- Load plugins
safe_require('user.plugins')

-- Set colorscheme (fallback to default if not available)
vim.cmd('set background=dark')
pcall(function() vim.cmd('colorscheme solarized') end)

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
    auto_install_tools = true -- Set to false to disable automatic installation
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
  require('Comment').setup()
end

-- Setup lualine (replacement for vim-airline)
if safe_require('lualine') then
  require('lualine').setup({
    options = {
      theme = 'solarized_dark',
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
  vim.g.rainbow_delimiters = {
    strategy = {
      [''] = require('rainbow-delimiters').strategy['global'],
    },
    query = {
      [''] = 'rainbow-delimiters',
    },
  }
end

-- Setup solarized colorscheme
if safe_require('solarized') then
  require('solarized').setup({
    theme = 'neo', -- or 'default'
    transparent = false,
    colors = {},  -- Override specific color values
    highlights = {}, -- Override specific highlight groups
    enable_italics = true,
  })
end

-- Create a command to compile and sync Packer
vim.api.nvim_create_user_command('PackerUpdate', function()
  -- Reload the plugins module first
  package.loaded['user.plugins'] = nil
  require('user.plugins')
  -- Then run PackerSync
  vim.cmd('PackerSync')
end, { desc = 'Reload plugins configuration and run PackerSync' })

-- Helper function for Go files - must be defined at global scope
function _G.build_go_files()
  local file = vim.fn.expand('%')
  if file:match('_test%.go$') then
    vim.cmd('GoTest')
  elseif file:match('%.go$') then
    vim.cmd('GoBuild')
  end
end 