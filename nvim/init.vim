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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Neovim Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim')
  " Load the Lua configuration
  " This will initialize all required modules through the unified loading mechanism
  lua require('init')
endif 