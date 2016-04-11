if &compatible
  set nocompatible               " Be iMproved
endif

call plug#begin('~/.vim/plugged')

function! BuildYCM(info)
  " info is a dictionary with 3 fields
  " - name:   name of the plugin
  " - status: 'installed', 'updated', or 'unchanged'
  " - force:  set on PlugInstall! or PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py --gocode-completer --clang-completer
  endif
endfunction

Plug 'Shougo/neocomplete.vim'
" Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }

Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'Shougo/neocomplete.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'bling/vim-airline'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'elzr/vim-json'
Plug 'ervandew/supertab'
Plug 'fatih/vim-go'
Plug 'luochen1990/rainbow'
Plug 'marijnh/tern_for_vim'
Plug 'markcornick/vim-terraform'
Plug 'mhinz/vim-signify'
Plug 'ntpeters/vim-better-whitespace'
Plug 'robbles/logstash.vim'
Plug 'rodjek/vim-puppet'
Plug 'scrooloose/Syntastic'
Plug 'sjl/gundo.vim'
Plug 'stephpy/vim-yaml'
Plug 'tfnico/vim-gradle'
Plug 'tomtom/tlib_vim'
Plug 'tpope/vim-classpath'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-git'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-salve'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-ruby/vim-ruby'
Plug 'vim-scripts/L9'
Plug 'vim-scripts/Specky'
Plug 'vim-scripts/Tabular'

call plug#end()

" Required:
filetype plugin indent on

" Last edited line when reopening
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ~> General
syntax on
set history=1000
set title                                               " vim sets terminal title

set undofile                                            " save central undo files
set undodir=~/.vim/tmp/undo/
set backup                                              " enable backups
set backupdir=~/.vim/tmp/backup/

"set ignorecase                                          " Do case insensitive matching
set smartcase                                           " Do smart case matching
set incsearch                                           " Incremental search
set autowrite                                           " Automatically save before commands like :next and :make
set hidden                                              " Hide buffers when they are abandoned

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ~> Visual Behaviors
set showcmd                                             " show command in status line

set lazyredraw                                          " redraw a/ macros or registers
set visualbell                                          " Flash screen not bell
set showmatch                                           " flash to the matching paren
set matchtime=2                                         " for 2 seconds (default 5)
set wrap                                                " Wrap long lines
set textwidth=80                                        " consider PEP8 by default
set scrolloff=2                                         " keep 2 lines between cursor and edge
set formatoptions=qn2                                   " Format comments gq
                                                        "   reconize numbered lists
                                                        "   No break lines after 1 letter word

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ~> Tab behaviors
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smarttab
set autoindent

set fileformat=unix
set encoding=utf-8
set hls

nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode
set wildmenu
set wildmode=list:longest
set ttyfast
set laststatus=2

autocmd FileType json setlocal shiftwidth=2
autocmd FileType json setlocal tabstop=2

" Save global variables, those whose names are all uppercase
" Remember the marks used in the past 1000 edited files
" Remember 1000 lines of each register between sessions
" Don’t highlight the last search when starting a new session
" Store the file as ~/.vim/viminfo
set viminfo=!,'1000,<1000,h,n~/.vim/viminfo

if &encoding == "utf-8"
  set listchars=tab:▸\ ,trail:.,eol:¬
else
  set listchars=tab:>\ ,trail:.,eol:-
endif
nmap <leader>l :set list!<CR>
nmap <leader>n :setlocal number!<CR>
nmap <leader>q :nohlsearch<CR>

if $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal"
  set t_Co=256
endif

filetype on
filetype plugin on
" Auto completion via ctrl-space (instead of the nasty ctrl-x ctrl-o)
inoremap <Nul> <C-x><C-o>

let g:syntastic_python_checkers=['flake8']

let g:solarized_termcolors=256
set background=dark
colorscheme solarized

let g:vim_json_syntax_conceal=0

let g:airline_powerline_fonts = 1

autocmd BufNewFile,BufRead Packerfile set filetype=json

let g:rainbow_active = 1

highlight ColorColumn ctermbg=magenta
call matchadd('ColorColumn', '\%81v', 100)

set backspace=indent,eol,start

nnoremap <F5> :GundoToggle<CR>

let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif

