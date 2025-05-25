-- Core Neovim keymaps and shortcuts
-- Migrated from user/keymaps.lua for better organization

local M = {}

function M.setup()
  local opts = { noremap = true, silent = true }
  local keymap = vim.keymap.set

  -- Toggle operations - using <leader>t prefix
  keymap("n", "<leader>tn", ":set relativenumber!<CR>", opts)

  -- Clear search highlight
  keymap("n", "<leader>q", ":nohlsearch<CR>", opts)

  -- Luacheck
  keymap("n", "<leader>lc", ":!luacheck %<CR>", { desc = "Luacheck current file" })

  -- LSP operations - toggle list
  keymap("n", "<leader>ll", ":set list!<CR>", opts)

  -- Indent guides toggle
  keymap("n", "<leader>ti", ":IndentBlanklineToggle<CR>", opts)
  keymap("n", "<leader>tI", ":IndentBlanklineScopeToggle<CR>", opts)

  -- Buffer navigation
  keymap("n", "<leader>bn", ":bnext<CR>", opts)
  keymap("n", "<leader>bp", ":bprevious<CR>", opts)
  keymap("n", "<leader>bd", ":bdelete<CR>", opts)
  keymap("n", "<leader>bl", ":buffers<CR>", opts)

  -- Window navigation
  keymap("n", "<C-h>", "<C-w>h", opts)
  keymap("n", "<C-j>", "<C-w>j", opts)
  keymap("n", "<C-k>", "<C-w>k", opts)
  keymap("n", "<C-l>", "<C-w>l", opts)

  -- Platform-specific key mappings
  local utils = require('core.utils')
  
  -- Apply platform-specific movement keymaps
  local platform_keymaps = utils.platform.get_platform_keymaps()
  for _, mapping in ipairs(platform_keymaps) do
    keymap(mapping.mode, mapping.lhs, mapping.rhs, { noremap = true, silent = true, desc = mapping.desc })
  end
  
  -- Apply platform-specific clipboard keymaps
  local clipboard_keymaps = utils.platform.get_clipboard_keymaps()
  for _, mapping in ipairs(clipboard_keymaps) do
    keymap(mapping.mode, mapping.lhs, mapping.rhs, { noremap = true, silent = true, desc = mapping.desc })
  end

  -- VSCode-like keyboard shortcuts (platform-aware)
  if utils.platform.is_mac() then
    -- macOS uses Cmd key for system shortcuts
    keymap("n", "<D-s>", ":w<CR>", opts)
    keymap("i", "<D-s>", "<Esc>:w<CR>", opts)
    keymap("n", "<D-a>", "ggVG", opts)
    keymap("n", "<D-z>", "u", opts)
    keymap("i", "<D-z>", "<C-o>u", opts)
    keymap("n", "<D-y>", "<C-r>", opts)
    keymap("i", "<D-y>", "<C-o><C-r>", opts)
    keymap("n", "<D-/>", ":lua require('Comment.api').toggle.linewise.current()<CR>", opts)
    keymap("v", "<D-/>", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)
  else
    -- Linux uses Ctrl key
    keymap("n", "<C-s>", ":w<CR>", opts)
    keymap("i", "<C-s>", "<Esc>:w<CR>", opts)
    keymap("n", "<C-a>", "ggVG", opts)
    keymap("n", "<C-z>", "u", opts)
    keymap("i", "<C-z>", "<C-o>u", opts)
    keymap("n", "<C-y>", "<C-r>", opts)
    keymap("i", "<C-y>", "<C-o><C-r>", opts)
    keymap("n", "<C-_>", ":lua require('Comment.api').toggle.linewise.current()<CR>", opts)
    keymap("v", "<C-_>", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)
  end

  -- Terminal mode escape
  keymap("t", "<Esc>", "<C-\\><C-n>", opts)
  
  -- Mouse shortcuts and behaviors
  local capabilities = utils.platform.get_capabilities()
  if capabilities.mouse then
    local terminal_config = utils.platform.get_terminal_config()
    
    -- Ctrl+Right Click to go back (like VSCode/browser back)
    keymap("n", "<C-RightMouse>", "<LeftMouse><C-o>", opts)
    
    -- VSCode-like dragging behaviors
    keymap("v", "<LeftDrag>", "<LeftDrag>", opts)
    keymap("v", "<LeftRelease>", "<LeftRelease>", opts)
    
    -- VSCode-like multi-cursor with Alt+Click
    keymap("n", "<A-LeftMouse>", "<LeftMouse><cmd>normal! viw<CR>gn", opts)
    
    -- Shift+Click to select text (like VSCode)
    keymap("n", "<S-LeftMouse>", "<LeftMouse>v", opts)
    
    -- Terminal-specific mouse optimizations
    if terminal_config.enable_smooth_scrolling and utils.platform.is_iterm2() then
      -- Better mouse wheel handling in iTerm2
      vim.cmd([[
        " Smoother mouse wheel scrolling for iTerm2
        map <ScrollWheelUp> <C-Y><C-Y>
        map <ScrollWheelDown> <C-E><C-E>
        
        " Enable scroll acceleration
        map <S-ScrollWheelUp> <C-Y><C-Y><C-Y><C-Y>
        map <S-ScrollWheelDown> <C-E><C-E><C-E><C-E>
      ]])
    end
  end
end

-- Setup Go specific keybindings in a separate function so they can be called from an autocommand
function M.setup_go_keymaps()
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = true }

  -- Go commands using <leader>G prefix to avoid conflicts
  keymap("n", "<leader>Gb", "<cmd>lua require('plugins.config.lang.go').build_go_files()<CR>", opts)
  keymap("n", "<leader>Gt", "<Plug>(go-test)", { silent = true, buffer = true })
  keymap("n", "<leader>Gr", "<Plug>(go-run)", { silent = true, buffer = true })
  keymap("n", "<leader>Gd", "<Plug>(go-doc)", { silent = true, buffer = true })
  keymap("n", "<leader>Gc", "<Plug>(go-coverage-toggle)", { silent = true, buffer = true })
  keymap("n", "<leader>Gi", "<Plug>(go-info)", { silent = true, buffer = true })
  keymap("n", "<leader>Gl", "<Plug>(go-metalinter)", { silent = true, buffer = true })
  keymap("n", "<leader>Gv", "<Plug>(go-def-vertical)", { silent = true, buffer = true })
  keymap("n", "<leader>Gs", "<Plug>(go-def-split)", { silent = true, buffer = true })
end

return M 