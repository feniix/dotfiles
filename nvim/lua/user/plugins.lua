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
  
  -- Indent guides
  use {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    config = function()
      if safe_require('user.indent-blankline') then
        require('user.indent-blankline').setup()
      end
    end
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

  -- ---- Neovim Specific ----
  -- Debugging (lazy loaded)
  use {
    'mfussenegger/nvim-dap',
    cmd = { 'DapContinue', 'DapToggleBreakpoint' },
    keys = { '<F5>', '<leader>db' },
    requires = {
      'nvim-neotest/nvim-nio',
      {
        'rcarriga/nvim-dap-ui',
        config = function()
          -- DAP UI setup moved to after/ plugin
        end
      },
      'theHamsta/nvim-dap-virtual-text',
    },
    config = function()
      if safe_require('user.dap') then
        require('user.dap').setup()
      end
    end
  }

  -- Treesitter (core only for now - extensions to be added after base is working)
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      'nvim-treesitter/nvim-treesitter-textobjects', -- Smart text objects
    },
    config = function()
      if safe_require('user.treesitter') then
        require('user.treesitter').setup()
      end
    end
  }

  -- TreeSitter context-aware commenting
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  -- Modern completion system (adding back sources now that core is stable)
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-buffer'    -- Complete from current file
  use 'hrsh7th/cmp-path'      -- Complete file paths  
  use 'hrsh7th/cmp-cmdline'   -- Complete Vim commands

  -- Telescope - Fuzzy finder over lists
  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- Icons (already included above)
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end
      }
    },
    config = function()
      if safe_require('user.telescope') then
        require('user.telescope').setup()
      end
    end
  }

  -- Modern replacements
  use 'lewis6991/gitsigns.nvim'          -- Git integration (replaces vim-gitgutter)
  use 'kylechui/nvim-surround'           -- Surround text objects (replaces vim-surround)
  use 'kaplanz/retrail.nvim'             -- Whitespace management (replaces vim-better-whitespace)
  use 'nvim-tree/nvim-web-devicons'      -- File icons (replaces vim-devicons)
  use 'nvim-lualine/lualine.nvim'        -- Status line (replaces vim-airline)
  use 'HiPhish/rainbow-delimiters.nvim'  -- Rainbow parentheses (replaces rainbow)

  -- Extra niceties
  use {
    'folke/todo-comments.nvim',         -- TODO comments
    requires = 'nvim-lua/plenary.nvim'
  }
  use 'numToStr/Comment.nvim'            -- Commenting plugin
  use 'windwp/nvim-autopairs'            -- Auto pairs

  -- Which Key - Keymap discovery and organization
  use {
    'folke/which-key.nvim',
    config = function()
      if safe_require('user.which-key') then
        require('user.which-key').setup()
      end
    end
  }

  -- Git diff viewer
  use {
    'sindrets/diffview.nvim',
    requires = 'nvim-lua/plenary.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    config = function()
      if safe_require('user.diffview') then
        require('user.diffview').setup()
      end
    end
  }

  -- Automatically set up your configuration after cloning packer.nvim
  if PACKER_BOOTSTRAP then
    packer.sync()
  end
end) 