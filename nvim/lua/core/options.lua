-- Core Neovim options and settings
-- Migrated from user/options.lua for better organization

local M = {}

-- Setup function to set all core vim options
function M.setup()
  -- Get platform utilities
  local utils = require('core.utils')
  local capabilities = utils.platform.get_capabilities()
  
  -- Setup XDG Directories
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

  -- Provider settings (platform-aware)
  local python_path = vim.fn.expand('$HOME/.asdf/shims/python3')
  if vim.fn.executable(python_path) == 1 then
    vim.g.python3_host_prog = python_path
  elseif utils.platform.command_available('python3') then
    vim.g.python3_host_prog = vim.fn.exepath('python3')
  end
  
  -- Node.js provider (if available)
  if utils.platform.command_available('node') then
    -- Check for neovim npm package instead of node binary
    local neovim_path = vim.fn.system('npm root -g 2>/dev/null'):gsub('\n', '') .. '/neovim/bin/cli.js'
    if vim.fn.filereadable(neovim_path) == 1 then
      vim.g.node_host_prog = neovim_path
    else
      -- Disable node provider if neovim package not found
      vim.g.loaded_node_provider = 0
    end
  else
    -- Disable node provider if node not available
    vim.g.loaded_node_provider = 0
  end
  
  -- Disable unused providers to avoid warnings
  vim.g.loaded_python_provider = 0   -- Disable Python 2
  vim.g.loaded_perl_provider = 0     -- Disable Perl
  -- vim.g.loaded_ruby_provider = 0     -- Disable Ruby (uncomment if not using Ruby)

  -- Set leader key
  vim.g.mapleader = ','

  -- Set undo directory
  vim.opt.undodir = xdg_state_home .. '/nvim/undo'

  -- Behavior options (platform-optimized)
  vim.opt.autoread = true              -- Automatically read changed files
  vim.opt.autowrite = true             -- Automatically save before :next, :make etc.
  vim.opt.hidden = true                -- Buffer should still exist if window is closed
  vim.opt.backup = false               -- Don't create annoying backup files
  vim.opt.swapfile = false             -- Don't use swapfile
  vim.opt.writebackup = false          -- No backup during write
  vim.opt.undofile = true              -- Enable persistent undo
  
  -- Platform-specific timing optimizations
  if utils.platform.is_mac() then
    vim.opt.updatetime = 200           -- Faster on macOS
    vim.opt.timeoutlen = 400           -- Shorter timeout for better responsiveness
  else
    vim.opt.updatetime = 250           -- Standard for Linux
    vim.opt.timeoutlen = 500           -- Standard timeout
  end
  vim.opt.ttimeoutlen = 10             -- Time to wait for key code sequence
  
  vim.opt.shortmess:append("c")        -- Don't give completion messages
  vim.opt.shortmess:append("I")        -- Don't show intro message
  vim.opt.signcolumn = "yes"           -- Always show signcolumn
  vim.opt.inccommand = "nosplit"       -- Show effects of substitute in buffer
  
  -- Platform-aware UI settings
  vim.opt.pumheight = utils.platform.is_mac() and 12 or 15  -- Smaller on macOS for better UX
  vim.opt.pumblend = capabilities.true_color and 10 or 0     -- Transparency only with true color
  vim.opt.winblend = capabilities.true_color and 10 or 0     -- Window transparency

  -- UI options (capability-aware)
  vim.opt.colorcolumn = "80"           -- Show right margin
  vim.opt.cursorline = true            -- Highlight current line
  vim.opt.expandtab = true             -- Use spaces instead of tabs
  vim.opt.ignorecase = true            -- Search case insensitive
  vim.opt.smartcase = true             -- Case sensitive if uppercase present
  vim.opt.hlsearch = true              -- Highlight found searches
  vim.opt.laststatus = 3               -- Global statusline
  vim.opt.number = true                -- Show line numbers
  vim.opt.relativenumber = true        -- Use relative line numbers
  
  -- Platform-specific scrolling behavior
  if utils.platform.is_iterm2() then
    vim.opt.scrolloff = 5              -- Less aggressive on iTerm2 for smoother scrolling
    vim.opt.sidescrolloff = 5
  else
    vim.opt.scrolloff = 8              -- Standard scrolloff
    vim.opt.sidescrolloff = 8
  end
  
  vim.opt.shiftwidth = 2               -- 2 spaces indent
  vim.opt.showmode = false             -- Don't show mode (statusline shows it)
  vim.opt.smartindent = true           -- Smarter indentation
  vim.opt.softtabstop = 2              -- 2 spaces for tabs
  vim.opt.splitbelow = true            -- Horizontal splits go below
  vim.opt.splitright = true            -- Vertical splits go right
  vim.opt.splitkeep = "screen"         -- Keep text on screen when splitting
  vim.opt.tabstop = 2                  -- 2 spaces for tabs
  vim.opt.termguicolors = capabilities.true_color  -- Enable 24-bit RGB colors if supported
  vim.opt.title = true                 -- Set the terminal title
  vim.opt.wrap = false                 -- Don't wrap long lines
  vim.opt.linebreak = true             -- Break lines at word boundaries
  vim.opt.breakindent = true           -- Preserve indentation in wrapped text
  
  -- Enhanced fillchars for better terminals
  local fillchars = {
    eob = " ",                         -- End of buffer
    fold = " ",                        -- Fold
    foldsep = " ",                     -- Fold separator
  }
  
  if capabilities.true_color then
    fillchars.foldopen = "▾"           -- Fold open (Unicode)
    fillchars.foldclose = "▸"          -- Fold close (Unicode)
  else
    fillchars.foldopen = "-"           -- Fold open (ASCII fallback)
    fillchars.foldclose = "+"          -- Fold close (ASCII fallback)
  end
  
  vim.opt.fillchars = fillchars
  
  -- Mouse settings (capability-aware)
  if capabilities.mouse then
    vim.opt.mouse = "a"                -- Enable mouse in all modes
    vim.opt.mousemodel = "popup_setpos" -- Right-click shows context menu and positions cursor
  else
    vim.opt.mouse = ""                 -- Disable mouse if not supported
  end
  
  -- Clipboard settings (platform-aware)
  if capabilities.clipboard then
    vim.opt.clipboard = "unnamedplus"  -- Use system clipboard
  else
    vim.opt.clipboard = ""             -- Disable if no clipboard support
  end

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

  -- Folding (treesitter-aware)
  if utils.platform.command_available('nvim-treesitter') or pcall(require, 'nvim-treesitter') then
    vim.opt.foldmethod = "expr"        -- Use expression for folding
    vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- Use treesitter for folding
  else
    vim.opt.foldmethod = "indent"      -- Fallback to indent-based folding
  end
  vim.opt.foldlevel = 99               -- Start with all folds open
  vim.opt.foldlevelstart = 99          -- Start with all folds open
  
  -- Search and replace
  vim.opt.gdefault = true              -- Global replace by default
  vim.opt.wrapscan = true              -- Wrap around when searching
end

return M 