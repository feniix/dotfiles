-- Packer plugin management
local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path,
  })
  print('Installing packer. Close and reopen Neovim...')
  vim.cmd([[packadd packer.nvim]])
end

-- Use a protected call so we don't error out on first use
local packer_ok, packer = pcall(require, 'packer')
if not packer_ok then
  return
end

-- Have packer use a popup window
packer.init({
  display = {
    open_fn = function()
      return require('packer.util').float({ border = 'rounded' })
    end,
  },
  git = {
    clone_timeout = 300, -- Timeout in seconds
  },
})

return packer.startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- ---- Core ----
  use 'editorconfig/editorconfig-vim'       -- Support for .editorconfig

  -- ---- UI ----
  -- NeoSolarized theme
  use {
    'svrana/neosolarized.nvim',             -- Solarized theme using ColorBuddy
    requires = 'tjdevries/colorbuddy.nvim'  -- ColorBuddy framework
  }
  
  -- ---- Language Support ----
  -- Terraform
  use 'hashivim/vim-terraform'              -- Terraform syntax & formatting

  -- Puppet
  use 'rodjek/vim-puppet'                   -- Puppet

  -- Go
  use {
    'fatih/vim-go',
    run = ':GoUpdateBinaries',
    ft = 'go'
  }
  use 'AndrewRadev/splitjoin.vim'
  use {
    'ray-x/go.nvim',
    ft = 'go',
    requires = 'ray-x/guihua.lua'
  }
  use {
    'edolphin-ydf/goimpl.nvim',
    ft = 'go',
    requires = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim'
    }
  }

  -- ---- Neovim Specific ----
  -- LSP & Completion
  use 'neovim/nvim-lspconfig'             -- LSP configuration
  
  -- Mason for managing LSP servers, linters, and formatters
  use {
    'williamboman/mason.nvim',           -- Main package manager
    requires = {
      'williamboman/mason-lspconfig.nvim', -- Bridge between mason and lspconfig
      'WhoIsSethDaniel/mason-tool-installer.nvim', -- Auto-install tools
    }
  }
  
  -- Debugging
  use {
    'mfussenegger/nvim-dap',              -- Debug Adapter Protocol client
    requires = {
      'nvim-neotest/nvim-nio',            -- Required dependency for nvim-dap-ui
      'rcarriga/nvim-dap-ui',             -- UI for nvim-dap
      'theHamsta/nvim-dap-virtual-text',  -- Show variable values as virtual text
    }
  }

  -- TypeScript Tools - modern alternative to tsserver
  use {
    'pmizio/typescript-tools.nvim',      -- Enhanced TypeScript experience
    requires = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' }
  }

  -- Modern completion system
  use {
    'hrsh7th/nvim-cmp',                 -- Completion plugin
    requires = {
      'hrsh7th/cmp-nvim-lsp',           -- LSP source for nvim-cmp
      'hrsh7th/cmp-buffer',             -- Buffer source for nvim-cmp
      'hrsh7th/cmp-path',               -- Path source for nvim-cmp
      'hrsh7th/cmp-cmdline',            -- Cmdline source for nvim-cmp
    }
  }

  -- Snippets
  use {
    'L3MON4D3/LuaSnip',                 -- Snippet engine
    requires = {
      'saadparwaiz1/cmp_luasnip',       -- Luasnip source for nvim-cmp
      'rafamadriz/friendly-snippets',   -- Common snippets
    }
  }

  -- Treesitter for better syntax highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  
  -- Treesitter extensions
  use 'nvim-treesitter/nvim-treesitter-context'  -- Show code context at top of screen
  use 'nvim-treesitter/nvim-treesitter-textobjects' -- Enhanced textobjects
  use 'JoosepAlviste/nvim-ts-context-commentstring' -- Context-aware commenting
  use 'windwp/nvim-ts-autotag' -- Auto close/rename HTML/JSX tags

  -- Modern replacements
  use 'lewis6991/gitsigns.nvim'          -- Git integration (replaces vim-gitgutter)
  use 'RRethy/nvim-treesitter-endwise'   -- Auto-add end (replaces vim-endwise)
  use 'kylechui/nvim-surround'           -- Surround text objects (replaces vim-surround)
  use 'kaplanz/retrail.nvim'             -- Whitespace management (replaces vim-better-whitespace)
  use 'nvim-tree/nvim-web-devicons'      -- File icons (replaces vim-devicons)
  use 'nvim-lualine/lualine.nvim'        -- Status line (replaces vim-airline)
  use 'HiPhish/rainbow-delimiters.nvim'  -- Rainbow parentheses (replaces rainbow)

  -- JSON Support
  use 'b0o/SchemaStore.nvim'             -- JSON Schema store

  -- Extra niceties
  use {
    'folke/todo-comments.nvim',         -- TODO comments
    requires = 'nvim-lua/plenary.nvim'
  }
  use 'numToStr/Comment.nvim'            -- Commenting plugin
  use 'windwp/nvim-autopairs'            -- Auto pairs

  -- Automatically set up your configuration after cloning packer.nvim
  if PACKER_BOOTSTRAP then
    packer.sync()
  end
end) 