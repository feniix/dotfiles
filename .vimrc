" Basic Vim configuration for Vim 9.x
" This provides sensible defaults for basic editing

" Use Vim settings, rather than Vi settings
set nocompatible

" Enable syntax highlighting
syntax on

" Enable file type detection
filetype plugin indent on

" Set sensible tab settings
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent

" Basic interface settings
set number          " Show line numbers
set ruler           " Show cursor position
set showcmd         " Show incomplete commands
set showmode        " Show current mode
set wildmenu        " Enhanced command-line completion
set laststatus=2    " Always show status line
set scrolloff=3     " Keep 3 lines between cursor and edge

" Search settings
set incsearch       " Incremental search
set hlsearch        " Highlight search matches
set ignorecase      " Case insensitive searching
set smartcase       " Case sensitive if pattern contains uppercase

" Backup and swap settings
set nobackup        " Don't use backup files
set nowritebackup   " Don't backup file while editing
set noswapfile      " Don't use swapfile

" Mouse support
set mouse=a         " Enable mouse in all modes

" Leader key
let mapleader = ','

" Basic key mappings
" Clear search highlight
nnoremap <leader>q :nohlsearch<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Enable clipboard integration if available
if has('clipboard')
  set clipboard=unnamed
  if has('unnamedplus')
    set clipboard+=unnamedplus
  endif
endif

" Return to last edit position when opening files
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif 