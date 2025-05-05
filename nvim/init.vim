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
Plug 'vim-scripts/L9'                      " Utility functions
Plug 'tpope/vim-sensible'                  " Sensible defaults
Plug 'ryanoasis/vim-devicons'              " File type icons
Plug 'ntpeters/vim-better-whitespace'      " Highlight trailing whitespace
Plug 'airblade/vim-gitgutter'              " Git diff in sign column
Plug 'tpope/vim-endwise'                   " Add 'end' in ruby, shell, etc.
Plug 'tpope/vim-surround'                  " Surround text objects
Plug 'editorconfig/editorconfig-vim'       " Support for .editorconfig

" ---- UI ----
Plug 'altercation/vim-colors-solarized'    " Solarized colorscheme
Plug 'vim-airline/vim-airline'             " Status line
Plug 'vim-airline/vim-airline-themes'      " Status line themes
Plug 'luochen1990/rainbow'                 " Rainbow parentheses

" ---- Navigation ----
Plug 'majutsushi/tagbar'                   " Tag sidebar
Plug 'ctrlpvim/ctrlp.vim'                  " Fuzzy file finder

" ---- Language Support ----
" Syntax and linting
Plug 'dense-analysis/ale'                  " Asynchronous Lint Engine
Plug 'elzr/vim-json'                       " JSON syntax highlighting
Plug 'cespare/vim-toml'                    " TOML syntax
Plug 'ekalinin/Dockerfile.vim'             " Dockerfile syntax
Plug 'hashivim/vim-terraform'              " Terraform
Plug 'juliosueiras/vim-terraform-completion' " Terraform completion
Plug 'google/vim-jsonnet'                  " Jsonnet

" Languages
Plug 'vim-ruby/vim-ruby'                   " Ruby
Plug 'rodjek/vim-puppet'                   " Puppet
Plug 'stephpy/vim-yaml'                    " YAML
Plug 'hdiniz/vim-gradle'                   " Gradle
Plug 'udalov/kotlin-vim'                   " Kotlin

" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'AndrewRadev/splitjoin.vim'
Plug 'SirVer/ultisnips'

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
  
  
  " Extra niceties
  Plug 'folke/todo-comments.nvim'         " TODO comments
  Plug 'lewis6991/gitsigns.nvim'          " Git decorations
  Plug 'numToStr/Comment.nvim'            " Commenting plugin
  Plug 'windwp/nvim-autopairs'            " Auto pairs
endif

call plug#end()

" Required:
filetype plugin indent on
syntax on

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" ALE (replaces Syntastic for Neovim)
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
let g:ale_linters = {
\   'python': ['flake8'],
\   'go': ['gopls', 'golangci-lint'],
\   'javascript': ['eslint']
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': ['black', 'isort'],
\   'go': ['gofmt', 'goimports'],
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\}
let g:ale_fix_on_save = 1
let g:ale_hover_cursor = 1

if has('nvim')
  " Load init.lua which contains utility functions
  lua require('init')
  
  " Set up todo-comments
  lua << EOF
  local todo_comments_ok, todo_comments = pcall(require, "todo-comments")
  if todo_comments_ok then
    todo_comments.setup {
      signs = true,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } }
      }
    }
  end
EOF

  " Set up nvim-cmp
  lua << EOF
  local cmp_ok, cmp = pcall(require, 'cmp')
  local luasnip_ok, luasnip = pcall(require, 'luasnip')
  
  if cmp_ok and luasnip_ok then
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
  elseif not cmp_ok then
    vim.notify("nvim-cmp not found. Completion may be limited.", vim.log.levels.WARN)
  elseif not luasnip_ok then
    vim.notify("LuaSnip not found. Snippet expansion may be limited.", vim.log.levels.WARN)
  end
EOF

  " Load Lua modules safely
  lua << EOF
  -- Setup LSP if available
  safe_require('user.lsp').setup()
  
  -- Setup Treesitter if available
  local treesitter = safe_require('user.treesitter')
  if treesitter then treesitter.setup() end
  
  -- Setup TypeScript if available
  if not vim.g.skip_ts_tools then
    local typescript = safe_require('user.typescript')
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
  
  -- Setup additional modules with fallback options
  local autopairs_ok, autopairs = pcall(require, 'nvim-autopairs')
  if autopairs_ok then autopairs.setup{} end
  
  local gitsigns_ok, gitsigns = pcall(require, 'gitsigns')
  if gitsigns_ok then gitsigns.setup() end
  
  local comment_ok, comment = pcall(require, 'Comment')
  if comment_ok then comment.setup() end
EOF
endif

" Rainbow Parentheses
let g:rainbow_active = 1

" Terraform
let g:terraform_align=0
let g:terraform_fmt_on_save=1
autocmd FileType terraform setlocal commentstring=#%s
autocmd BufNewFile,BufRead *.hcl set filetype=terraform

" Go settings
let g:go_fmt_command = 'goimports'
let g:go_list_type = 'quickfix'
let g:go_test_timeout = '10s'
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

" JSON
let g:vim_json_syntax_conceal=0

" Airline
let g:airline_powerline_fonts = 1
let g:airline_theme = 'solarized'
let g:airline#extensions#tabline#enabled = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editor Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Behavior
set autoindent                  " Enable autoindent
set autoread                    " Automatically read changed files
set autowrite                   " Automatically save before :next, :make etc.
set backspace=indent,eol,start  " Makes backspace key more powerful.
set hidden                      " Buffer should still exist if window is closed
set history=10000               " Keep more history
set lazyredraw                  " Wait to redraw
set nobackup                    " Don't create annoying backup files
set noerrorbells                " No beeps
set noswapfile                  " Don't use swapfile
set nowritebackup               " No backup during write
set pumheight=10                " Completion window max size
set undofile                    " Enable persistent undo
set updatetime=300              " Faster update time for better UX
set shortmess+=c                " Don't give completion messages
set signcolumn=yes              " Always show signcolumn
if has('nvim')
  set inccommand=split          " Show effects of substitute command in real time
endif

" UI
set colorcolumn=80              " Show right margin
set cursorline                  " Highlight current line
set expandtab                   " Use spaces instead of tabs
set ignorecase                  " Search case insensitive...
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set laststatus=2                " Show status line always
set matchtime=2                 " Show matching bracket for 2 tenths of a second
set number                      " Show line numbers
set relativenumber              " Use relative line numbers
set ruler                       " Show the cursor position all the time
set scrolloff=5                 " Keep 5 lines between cursor and edge
set shiftwidth=2                " 2 spaces indent
set showcmd                     " Show me what I'm typing
set showmatch                   " Flash to the matching paren
set showmode                    " Show current mode
set smartcase                   " ... but not if it begins with upper case
set smartindent                 " Smarter indentation
set smarttab                    " Better tabs
set softtabstop=2               " 2 spaces for tabs
set splitbelow                  " Horizontal splits go below
set splitright                  " Vertical splits go right
set tabstop=2                   " 2 spaces for tabs
set textwidth=80                " Text wrapping
set title                       " Set the terminal title
set visualbell                  " Flash screen instead of beep
set wildmenu                    " Command-line completion
set wildmode=list:longest,full  " Better command line completion
set wrap                        " Wrap long lines
set mouse=a                     " Enable mouse in all modes

" Set clipboard
set clipboard^=unnamed
set clipboard^=unnamedplus

" Set listchars
set listchars=tab:▸\ ,trail:.,eol:¬,extends:❯,precedes:❮,nbsp:·

" Colorscheme
let g:solarized_termcolors=256
set background=dark
colorscheme solarized

" Highlight overlength
highlight ColorColumn ctermbg=magenta
call matchadd('ColorColumn', '\%81v', 100)

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keybindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Toggle list
nmap <leader>l :set list!<CR>

" Toggle line numbers
nmap <leader>n :set relativenumber!<CR>

" Clear search highlight
nmap <leader>q :nohlsearch<CR>

" Open tagbar
nmap <F8> :TagbarToggle<CR>

" Buffer navigation
nmap <leader>bn :bnext<CR>
nmap <leader>bp :bprevious<CR>
nmap <leader>bd :bdelete<CR>
nmap <leader>bl :buffers<CR>

" Window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" macOS specific key remappings
if has("mac") || has("macunix")
  " Map Option+j/k to move lines up and down
  nnoremap <silent> ∆ :m .+1<CR>==
  nnoremap <silent> ˚ :m .-2<CR>==
  inoremap <silent> ∆ <Esc>:m .+1<CR>==gi
  inoremap <silent> ˚ <Esc>:m .-2<CR>==gi
  vnoremap <silent> ∆ :m '>+1<CR>gv=gv
  vnoremap <silent> ˚ :m '<-2<CR>gv=gv
  
  " Map Option+h/l to jump words
  nnoremap <silent> ˙ b
  nnoremap <silent> ¬ w
endif

" Go specific keybindings
augroup go
  autocmd!

  " Show by default 4 spaces for a tab
  autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4

  " :GoBuild and :GoTestCompile
  autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>

  " :GoTest
  autocmd FileType go nmap <leader>t  <Plug>(go-test)

  " :GoRun
  autocmd FileType go nmap <leader>r  <Plug>(go-run)

  " :GoDoc
  autocmd FileType go nmap <Leader>d <Plug>(go-doc)

  " :GoCoverageToggle
  autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)

  " :GoInfo
  autocmd FileType go nmap <Leader>i <Plug>(go-info)

  " :GoMetaLinter
  autocmd FileType go nmap <Leader>l <Plug>(go-metalinter)

  " :GoDef but opens in a vertical split
  autocmd FileType go nmap <Leader>v <Plug>(go-def-vertical)
  " :GoDef but opens in a horizontal split
  autocmd FileType go nmap <Leader>s <Plug>(go-def-split)

  " :GoAlternate  commands :A, :AV, :AS and :AT
  autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
  autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
  autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
  autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
augroup END

" Terminal mode escape
if has('nvim')
  tnoremap <Esc> <C-\><C-n>
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Return to last edit position when opening files
augroup last_edit
  autocmd!
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
augroup END

" JSON settings
augroup json_settings
  autocmd!
  autocmd FileType json setlocal shiftwidth=2 tabstop=2
augroup END

" Set Packerfile as JSON
augroup packerfile
  autocmd!
  autocmd BufNewFile,BufRead Packerfile set filetype=json
augroup END

" Trim trailing whitespace on save
autocmd BufWritePre * %s/\s\+$//e

" Helper function for Go files
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

" Rust settings
let g:rustfmt_autosave = 1
let g:racer_experimental_completer = 1

" Elixir settings
let g:mix_format_on_save = 1 