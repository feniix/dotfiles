-- Editor options configuration
local M = {}

M.setup = function()
  -- Behavior
  vim.opt.autoindent = true                -- Enable autoindent
  vim.opt.autoread = true                  -- Automatically read changed files
  vim.opt.autowrite = true                 -- Automatically save before :next, :make etc.
  vim.opt.backspace = "indent,eol,start"   -- Makes backspace key more powerful
  vim.opt.hidden = true                    -- Buffer should still exist if window is closed
  vim.opt.backup = false                   -- No backup files
  vim.opt.swapfile = false                 -- No swap files
  vim.opt.undofile = false                 -- No undo files

  -- Searching
  vim.opt.hlsearch = true                  -- Highlight search results
  vim.opt.ignorecase = true                -- Search case insensitive...
  vim.opt.smartcase = true                 -- ... unless contains uppercase
  vim.opt.incsearch = true                 -- Shows the match while typing

  -- Indentation
  vim.opt.expandtab = true                 -- Use spaces instead of tabs
  vim.opt.shiftwidth = 2                   -- 1 tab == 2 spaces
  vim.opt.tabstop = 2                      -- 1 tab == 2 spaces

  -- Display
  vim.opt.number = true                    -- Show line numbers
  vim.opt.relativenumber = true            -- Show relative line numbers
  vim.opt.ruler = true                     -- Show the cursor position all the time
  vim.opt.scrolloff = 7                    -- Keep 7 lines visible when scrolling
  vim.opt.sidescrolloff = 5                -- Keep 5 columns visible when scrolling horizontally
  vim.opt.splitbelow = true                -- New split below the current one
  vim.opt.splitright = true                -- New split to the right of the current one

  -- Encoding
  vim.opt.encoding = "utf-8"               -- The default encoding
  vim.opt.fileformats = "unix,dos,mac"     -- Use Unix line endings by default

  -- Performance
  vim.opt.lazyredraw = true                -- Don't redraw while executing macros

  -- Key timeout values
  vim.opt.timeout = true
  vim.opt.timeoutlen = 500                 -- Speed up the timeout
  vim.opt.ttimeoutlen = 100                -- Make Escape work faster

  -- Set completeopt
  vim.opt.completeopt = "menu,menuone,noselect"

  -- Wildmenu
  vim.opt.wildmenu = true                  -- Better command-line completion
  vim.opt.wildmode = "longest:full,full"   -- Complete longest common string, then each full match

  -- Add patience algorithm to diff options
  vim.opt.diffopt:append("algorithm:patience")

  -- Support true colors in terminal if available
  if vim.fn.has('termguicolors') == 1 then
    vim.opt.termguicolors = true
  end

  -- Remember longer file/command history
  vim.opt.history = 1000

  -- Always show status line
  vim.opt.laststatus = 2

  -- Set up autocommands
  vim.api.nvim_create_autocmd("VimResized", {
    pattern = "*",
    command = "wincmd =",
    desc = "Automatically equalize splits when vim is resized"
  })

  -- Return to last edit position when opening files
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
      if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
        vim.cmd("normal! g`\"")
      end
    end,
    desc = "Return to last edit position when opening files"
  })
end

return M 