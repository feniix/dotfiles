"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if &compatible
  set nocompatible               " Be iMproved
endif

" Python provider settings - use XDG paths
let g:python3_host_prog = '/opt/homebrew/opt/python@3.10/bin/python3.10'
let g:loaded_python_provider = 0  " Disable Python 2

" Leader key
let mapleader = ','

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" XDG Directories Setup
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set XDG Base Directory paths
if empty($XDG_CONFIG_HOME)
  let $XDG_CONFIG_HOME = $HOME . '/.config'
endif
if empty($XDG_DATA_HOME)
  let $XDG_DATA_HOME = $HOME . '/.local/share'
endif
if empty($XDG_CACHE_HOME)
  let $XDG_CACHE_HOME = $HOME . '/.cache'
endif
if empty($XDG_STATE_HOME)
  let $XDG_STATE_HOME = $HOME . '/.local/state'
endif

" Create directories if they don't exist
if !isdirectory($XDG_DATA_HOME . '/nvim')
  call mkdir($XDG_DATA_HOME . '/nvim', 'p', 0700)
endif
if !isdirectory($XDG_CACHE_HOME . '/nvim')
  call mkdir($XDG_CACHE_HOME . '/nvim', 'p', 0700)
endif
if !isdirectory($XDG_STATE_HOME . '/nvim')
  call mkdir($XDG_STATE_HOME . '/nvim', 'p', 0700)
endif

" Set up undo directory
let &undodir = $XDG_STATE_HOME . '/nvim/undo'
if !isdirectory(&undodir)
  call mkdir(&undodir, 'p', 0700)
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins (vim-plug)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Auto-install vim-plug if not found
let data_dir = $XDG_DATA_HOME . '/nvim'
let plug_file = data_dir . '/site/autoload/plug.vim'

if empty(glob(plug_file))
  silent execute '!curl -fLo ' . plug_file . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(data_dir . '/plugged')

" ---- Core ----
" Removed vim-sensible (redundant with Neovim defaults)
Plug 'editorconfig/editorconfig-vim'       " Support for .editorconfig

" ---- UI ----
Plug 'shaunsingh/solarized.nvim'          " Modern Solarized colorscheme in Lua

" ---- Navigation ----
" Removed tagbar and ctrlp (outdated)

" ---- Language Support ----
" Syntax and linting
" Removed vim-json (replaced by Tree-sitter + LSP)
" Removed vim-toml (replaced by Tree-sitter)
" Removed Dockerfile.vim (replaced by Tree-sitter + LSP)
Plug 'hashivim/vim-terraform'              " Terraform syntax & formatting

" Languages
Plug 'rodjek/vim-puppet'                   " Puppet
" Removed vim-gradle (replaced by LSP)

" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries', 'for': 'go' }
Plug 'AndrewRadev/splitjoin.vim'
" Go enhanced plugins
Plug 'ray-x/go.nvim', { 'for': 'go' }
Plug 'ray-x/guihua.lua'  " Required by go.nvim for floating windows
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.4' }  " Modern fuzzy finder
Plug 'edolphin-ydf/goimpl.nvim', { 'for': 'go' }  " Generate interface implementations

" ---- Neovim Specific ----
if has('nvim')
  Plug 'nvim-lua/plenary.nvim'             " Lua functions
  Plug 'neovim/nvim-lspconfig'             " LSP configuration
  
  " TypeScript Tools - modern alternative to tsserver
  Plug 'pmizio/typescript-tools.nvim'      " Enhanced TypeScript experience
  
  " Modern completion system
  Plug 'hrsh7th/nvim-cmp'                 " Completion plugin
  Plug 'hrsh7th/cmp-nvim-lsp'             " LSP source for nvim-cmp
  Plug 'hrsh7th/cmp-buffer'               " Buffer source for nvim-cmp
  Plug 'hrsh7th/cmp-path'                 " Path source for nvim-cmp
  Plug 'hrsh7th/cmp-cmdline'              " Cmdline source for nvim-cmp
  
  " Snippets
  Plug 'L3MON4D3/LuaSnip'                 " Snippet engine
  Plug 'saadparwaiz1/cmp_luasnip'         " Luasnip source for nvim-cmp
  Plug 'rafamadriz/friendly-snippets'     " Common snippets
  
  " Treesitter for better syntax highlighting
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  
  " Modern replacements
  Plug 'lewis6991/gitsigns.nvim'          " Git integration (replaces vim-gitgutter)
  Plug 'RRethy/nvim-treesitter-endwise'   " Auto-add end (replaces vim-endwise)
  Plug 'kylechui/nvim-surround'           " Surround text objects (replaces vim-surround)
  Plug 'kaplanz/retrail.nvim'             " Whitespace management (replaces vim-better-whitespace)
  Plug 'nvim-tree/nvim-web-devicons'      " File icons (replaces vim-devicons)
  Plug 'nvim-lualine/lualine.nvim'        " Status line (replaces vim-airline)
  Plug 'HiPhish/rainbow-delimiters.nvim'  " Rainbow parentheses (replaces rainbow)
  
  " JSON Support
  Plug 'b0o/SchemaStore.nvim'             " JSON Schema store
  
  " Extra niceties
  Plug 'folke/todo-comments.nvim'         " TODO comments
  Plug 'numToStr/Comment.nvim'            " Commenting plugin
  Plug 'windwp/nvim-autopairs'            " Auto pairs
endif

call plug#end()

" Required:
filetype plugin indent on
syntax on

" Plugin configuration is now in lua/user/plugins.lua
" Editor options are now in lua/user/options.lua

if has('nvim')
  " Load init.lua which contains utility functions
  lua require('init')
  
  " Set up global_safe_require function
  lua << EOF
  -- Make safe_require globally available
  _G.safe_require = safe_require
EOF

  " Setup Lua modules - these are loaded automatically from init.lua, but can be manually loaded if needed
  " lua _G.setup_options()    -- Editor options
  " lua _G.setup_plugins()    -- Plugin configuration  
  " lua _G.setup_ui()         -- UI configuration
  " lua _G.setup_keymaps()    -- Key mappings
  " lua _G.setup_completion() -- Completion system

  " Load LSP modules safely
  lua << EOF
  -- Setup LSP if available
  safe_require('user.lsp').setup()
  
  -- Load common LSP functions
  local lsp_common = safe_require('user.lsp_common')
  if not lsp_common then
    vim.notify("Could not load LSP common module. Check your configuration.", vim.log.levels.ERROR)
  end
  
  -- Setup Treesitter if available
  local treesitter = safe_require('user.treesitter')
  if treesitter then treesitter.setup() end
  
  -- Setup TypeScript if available
  if not vim.g.skip_ts_tools then
    local typescript = safe_require('user.language-support.typescript')
    if typescript then typescript.setup() end
  end
  
  -- Setup TreeSitter troubleshooting helpers
  if not vim.g.skip_treesitter_setup then
    local ts_setup = safe_require('user.setup_treesitter')
    if ts_setup then
      -- Create command to manually install parsers
      vim.api.nvim_create_user_command('InstallTSParsers', function()
        ts_setup.install_parsers()
      end, { desc = 'Install TreeSitter parsers that might fail with the standard process' })
      
      -- Create command to specifically fix the vim parser
      vim.api.nvim_create_user_command('FixVimParser', function()
        ts_setup.install_vim_parser()
      end, { desc = 'Manually install the Vim TreeSitter parser' })
    end
  end
  
  -- Setup plugin installer
  if not vim.g.skip_plugin_installer then
    local plugin_installer = safe_require('user.plugin_installer')
    if plugin_installer then
      plugin_installer.create_commands()
    end
  end
  
  -- Setup configuration tester
  local config_test = safe_require('user.config_test')
  if config_test then
    config_test.create_commands()
  end
  
  -- Setup Go development
  local ok, go_module = pcall(require, 'user.language-support.go')
  if ok then
    go_module.setup({
      auto_install_tools = true -- Set to false to disable automatic installation
    })
  else
    vim.notify("Could not load Go module: " .. (go_module or "unknown error"), vim.log.levels.WARN)
  end
  
  -- Setup Terraform development
  local tf_ok, tf_module = pcall(require, 'user.language-support.terraform')
  if tf_ok then
    tf_module.setup({
      auto_install_tools = true, -- Set to false to disable automatic installation
      auto_format_on_save = true -- Set to false to disable auto-formatting
    })
  else
    vim.notify("Could not load Terraform module: " .. (tf_module or "unknown error"), vim.log.levels.WARN)
  end
  
  -- Setup JSON development
  local json_ok, json_module = pcall(require, 'user.language-support.json')
  if json_ok then
    json_module.setup({
      auto_install_tools = true, -- Set to false to disable automatic installation
      auto_format_on_save = true, -- Set to false to disable auto-formatting
      use_schemas = true -- Enable JSON schema validation
    })
  else
    vim.notify("Could not load JSON module: " .. (json_module or "unknown error"), vim.log.levels.WARN)
  end
  
  -- Setup YAML development
  local yaml_ok, yaml_module = pcall(require, 'user.language-support.yaml')
  if yaml_ok then
    yaml_module.setup({
      auto_install_tools = true, -- Set to false to disable automatic installation
      auto_format_on_save = true, -- Set to false to disable auto-formatting
      use_schemas = true -- Enable YAML schema validation
    })
  else
    vim.notify("Could not load YAML module: " .. (yaml_module or "unknown error"), vim.log.levels.WARN)
  end
  
  -- Setup Kubernetes development
  local k8s_ok, k8s_module = pcall(require, 'user.language-support.kubernetes')
  if k8s_ok then
    k8s_module.setup({
      auto_install_tools = true, -- Set to false to disable automatic installation
      auto_format_on_save = true, -- Set to false to disable auto-formatting
      use_schemas = true, -- Enable Kubernetes schema validation
      operator_schemas = true, -- Enable schemas for common operators (Argo, Cert-Manager, Prometheus, etc.)
      custom_schemas = {
        -- Add any custom CRD schemas you need here, for example:
        -- ["https://raw.githubusercontent.com/my-org/my-operator/main/crds/my-crd.yaml"] = {"*mycrd*.yaml", "*mycrd*.yml"}
      }
    })
  else
    vim.notify("Could not load Kubernetes module: " .. (k8s_module or "unknown error"), vim.log.levels.WARN)
  end
EOF
endif 