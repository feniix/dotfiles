"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Neovim Transitional Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This is a transitional file for Neovim that redirects to the main Lua config
" All configuration is now managed in init.lua and related Lua modules

" Ensure nocompatible mode
set nocompatible

" Suppress vim-plug not available messages
let g:loaded_vim_plug = 1

" XDG directories setup (for compatibility)
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

" Check if folders exist and create them if they don't
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

" NOTE: This file exists only for backward compatibility.
" Neovim configuration has been fully migrated to Lua.
" See $XDG_CONFIG_HOME/nvim/init.lua for the main configuration entry point.

" Load the Lua configuration
if has('nvim')
  lua require('init')
endif

" Forward to the main configuration
source <sfile>:h/init.lua
