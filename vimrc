" This line should not be removed as it ensures that various options are
" properly set to work with the Vim-related packages available in Debian.
runtime! debian.vim

if has("syntax")
  syntax on
endif

set background=dark

" Last edited line when reopening
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

if has("autocmd")
  filetype plugin indent on
endif

set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Do smart case matching
set incsearch		" Incremental search
set autowrite		" Automatically save before commands like :next and :make
set hidden             " Hide buffers when they are abandoned
set history=1000


" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

set shiftwidth=2
set tabstop=2
set expandtab
set smarttab
set fileformat=unix
set encoding=utf-8
set hls
set autoindent

nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode
set wildmenu
set wildmode=list:longest
set visualbell
set ttyfast
set laststatus=2

autocmd FileType python set complete+=k~/.vim/syntax/python.vim isk+=.,(
autocmd FileType python set tags+=$HOME/.vim/tags/python.ctags
" autocmd FileType python compiler pylint
autocmd FileType json setlocal shiftwidth=2
autocmd FileType json setlocal tabstop=2

" Save global variables, those whose names are all uppercase
" Remember the marks used in the past 1000 edited files
" Remember 1000 lines of each register between sessions
" Don’t highlight the last search when starting a new session
" Store the file as ~/.vim/viminfo
set viminfo=!,'1000,<1000,h,n~/.vim/viminfo

" let g:pylint_onwrite = 0

" Display invisible characters
"
" For utf-8 use the following characters
"
"   ▸ for tabs
"   . for trailing spaces
"   ¬ for line breaks
"
" otherwise, fall back to
"
"   > for tabs
"   . for trailing spaces
"   - for line breaks
"
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

" filetype plugin on
let g:pydiction_location = '$HOME/.vim/pydiction/complete-dict'

filetype on
filetype plugin on
" Auto completion via ctrl-space (instead of the nasty ctrl-x ctrl-o)
inoremap <Nul> <C-x><C-o>

set nocompatible               " be iMproved
filetype off                   " required!

filetype plugin indent on     " required!

call pathogen#infect()
let g:syntastic_python_checkers=['flake8']

let g:solarized_termcolors=256
set background=dark
colorscheme solarized

let g:vim_json_syntax_conceal=0

let g:airline_powerline_fonts = 1
set laststatus=2

