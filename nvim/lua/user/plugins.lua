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

  -- Modern completion system (event-based loading)
  use {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    requires = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      -- CMP setup moved to avoid startup delay
      vim.defer_fn(function()
        if safe_require('cmp') then
          local cmp = require('cmp')
          cmp.setup({
            snippet = {
              expand = function(args)
                -- No snippet engine
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
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  fallback()
                end
              end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
              { name = 'buffer' },
              { name = 'path' },
            })
          })

          -- Cmdline completion
          cmp.setup.cmdline('/', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = { { name = 'buffer' } }
          })

          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'path' }
            }, {
              { name = 'cmdline' }
            })
          })
        end
      end, 100)
    end
  }

  -- Treesitter (optimized loading)
  use {
    'nvim-treesitter/nvim-treesitter',
    event = 'BufRead',
    run = ':TSUpdate',
    config = function()
      if safe_require('user.treesitter') then
        require('user.treesitter').setup()
      end
    end
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