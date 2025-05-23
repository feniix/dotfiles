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
  local platform = _G.platform or safe_require('user.platform')
  if platform and platform.get_platform_keymaps then
    local platform_keymaps = platform.get_platform_keymaps()
    for _, mapping in ipairs(platform_keymaps) do
      keymap(mapping.mode, mapping.lhs, mapping.rhs, { noremap = true, silent = true, desc = mapping.desc })
    end
  else
    -- Fallback to macOS keymaps if platform detection fails
    if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
      -- Map Option+j/k to move lines up and down
      keymap("n", "∆", ":m .+1<CR>==", opts)
      keymap("n", "˚", ":m .-2<CR>==", opts)
      keymap("i", "∆", "<Esc>:m .+1<CR>==gi", opts)
      keymap("i", "˚", "<Esc>:m .-2<CR>==gi", opts)
      keymap("v", "∆", ":m '>+1<CR>gv=gv", opts)
      keymap("v", "˚", ":m '<-2<CR>gv=gv", opts)

      -- Map Option+h/l to jump words
      keymap("n", "˙", "b", opts)
      keymap("n", "¬", "w", opts)
    end
  end

  -- VSCode-like keyboard shortcuts
  -- Save with Ctrl+S
  keymap("n", "<C-s>", ":w<CR>", opts)
  keymap("i", "<C-s>", "<Esc>:w<CR>", opts)
  
  -- Select all with Ctrl+A
  keymap("n", "<C-a>", "ggVG", opts)
  
  -- Undo with Ctrl+Z
  keymap("n", "<C-z>", "u", opts)
  keymap("i", "<C-z>", "<C-o>u", opts)
  
  -- Redo with Ctrl+Y
  keymap("n", "<C-y>", "<C-r>", opts)
  keymap("i", "<C-y>", "<C-o><C-r>", opts)
  
  -- Comment line/block with Ctrl+/
  keymap("n", "<C-_>", ":lua require('Comment.api').toggle.linewise.current()<CR>", opts)
  keymap("v", "<C-_>", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)

  -- Terminal mode escape
  keymap("t", "<Esc>", "<C-\\><C-n>", opts)
  
  -- Mouse shortcuts and behaviors
  if vim.fn.has("mouse") == 1 then
    -- Get terminal configuration for terminal-specific optimizations
    local terminal_config = platform and platform.get_terminal_config and platform.get_terminal_config() or {}
    
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
    if terminal_config.enable_smooth_scrolling and platform and platform.get_terminal and platform.get_terminal() == "iterm2" then
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
  keymap("n", "<leader>Gb", "<cmd>lua require('user.go').build_go_files()<CR>", opts)
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