local M = {}

-- Setup function to set all options
function M.setup()
  -- Setup XDG Directories
  local xdg_config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand('~/.config')
  local xdg_data_home = vim.env.XDG_DATA_HOME or vim.fn.expand('~/.local/share')
  local xdg_cache_home = vim.env.XDG_CACHE_HOME or vim.fn.expand('~/.cache')
  local xdg_state_home = vim.env.XDG_STATE_HOME or vim.fn.expand('~/.local/state')

  -- Create directories if they don't exist
  local directories = {
    xdg_data_home .. '/nvim',
    xdg_cache_home .. '/nvim',
    xdg_state_home .. '/nvim',
    xdg_state_home .. '/nvim/undo',
  }

  for _, dir in ipairs(directories) do
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p', 0700)
    end
  end

  -- Python provider settings
  local python_path = vim.fn.expand('$HOME/.asdf/shims/python3')
  if vim.fn.executable(python_path) == 1 then
    vim.g.python3_host_prog = python_path
  elseif vim.fn.executable('python3') == 1 then
    vim.g.python3_host_prog = vim.fn.exepath('python3')
  end
  vim.g.loaded_python_provider = 0  -- Disable Python 2

  -- Set leader key
  vim.g.mapleader = ','

  -- Set undo directory
  vim.opt.undodir = xdg_state_home .. '/nvim/undo'

  -- Behavior options
  vim.opt.autoindent = true            -- Enable autoindent
  vim.opt.autoread = true              -- Automatically read changed files
  vim.opt.autowrite = true             -- Automatically save before :next, :make etc.
  vim.opt.backspace = "indent,eol,start" -- Makes backspace key more powerful
  vim.opt.hidden = true                -- Buffer should still exist if window is closed
  vim.opt.history = 10000              -- Keep more history
  vim.opt.lazyredraw = true            -- Wait to redraw
  vim.opt.backup = false               -- Don't create annoying backup files
  vim.opt.errorbells = false           -- No beeps
  vim.opt.swapfile = false             -- Don't use swapfile
  vim.opt.writebackup = false          -- No backup during write
  vim.opt.pumheight = 10               -- Completion window max size
  vim.opt.undofile = true              -- Enable persistent undo
  vim.opt.updatetime = 300             -- Faster update time for better UX
  vim.opt.shortmess:append("c")        -- Don't give completion messages
  vim.opt.signcolumn = "yes"           -- Always show signcolumn
  vim.opt.inccommand = "split"         -- Show effects of substitute command in real time

  -- UI options
  vim.opt.colorcolumn = "80"           -- Show right margin
  vim.opt.cursorline = true            -- Highlight current line
  vim.opt.expandtab = true             -- Use spaces instead of tabs
  vim.opt.ignorecase = true            -- Search case insensitive
  vim.opt.incsearch = true             -- Shows the match while typing
  vim.opt.hlsearch = true              -- Highlight found searches
  vim.opt.laststatus = 2               -- Show status line always
  vim.opt.matchtime = 2                -- Show matching bracket for 2 tenths of a second
  vim.opt.number = true                -- Show line numbers
  vim.opt.relativenumber = true        -- Use relative line numbers
  vim.opt.ruler = true                 -- Show the cursor position all the time
  vim.opt.scrolloff = 5                -- Keep 5 lines between cursor and edge
  vim.opt.shiftwidth = 2               -- 2 spaces indent
  vim.opt.showcmd = true               -- Show me what I'm typing
  vim.opt.showmatch = true             -- Flash to the matching paren
  vim.opt.showmode = true              -- Show current mode
  vim.opt.smartcase = true             -- ... but not if it begins with upper case
  vim.opt.smartindent = true           -- Smarter indentation
  vim.opt.smarttab = true              -- Better tabs
  vim.opt.softtabstop = 2              -- 2 spaces for tabs
  vim.opt.splitbelow = true            -- Horizontal splits go below
  vim.opt.splitright = true            -- Vertical splits go right
  vim.opt.tabstop = 2                  -- 2 spaces for tabs
  vim.opt.textwidth = 80               -- Text wrapping
  vim.opt.title = true                 -- Set the terminal title
  vim.opt.visualbell = true            -- Flash screen instead of beep
  vim.opt.wildmenu = true              -- Command-line completion
  vim.opt.wildmode = "list:longest,full" -- Better command line completion
  vim.opt.wrap = true                  -- Wrap long lines
  
  -- Mouse settings
  vim.opt.mouse = "a"                  -- Enable mouse in all modes
  vim.opt.mousemodel = "popup_setpos"  -- Right-click shows context menu and positions cursor
  vim.opt.selection = "exclusive"      -- More VSCode-like selection behavior
  vim.opt.selectmode = "mouse,key"     -- Enable visual selection with mouse
  
  -- Platform-specific configurations (clipboard, terminal support, etc.)
  -- Note: These are now handled by the platform module in init.lua
  -- but we keep the universal clipboard settings here
  
  -- Make Neovim behave more like VSCode when selecting text
  -- Enable visual block mode when selecting with mouse + shift  
  vim.keymap.set('n', '<S-LeftMouse>', '<LeftMouse><Cmd>set mouse=a<CR><Cmd>normal! V<CR>', {silent = true})
  vim.keymap.set('n', '<S-RightMouse>', '<LeftMouse><Cmd>set mouse=a<CR><Cmd>normal! v<CR>', {silent = true})
  
  -- Set clipboard - the platform module handles the provider configuration
  vim.opt.clipboard:append("unnamed")
  vim.opt.clipboard:append("unnamedplus")

  -- Set listchars
  vim.opt.listchars = {
    tab = "▸ ",
    trail = ".",
    eol = "¬",
    extends = "❯",
    precedes = "❮",
    nbsp = "·"
  }

  -- Set background
  vim.opt.background = "dark"

  -- Highlight overlength
  vim.api.nvim_set_hl(0, 'ColorColumn', { ctermbg = 'magenta' })
  vim.fn.matchadd('ColorColumn', '\\%81v', 100)
end

return M 