local M = {}

function M.setup()
  local opts = { noremap = true, silent = true }
  local keymap = vim.keymap.set

  -- Toggle list
  keymap("n", "<leader>l", ":set list!<CR>", opts)

  -- Toggle line numbers
  keymap("n", "<leader>n", ":set relativenumber!<CR>", opts)

  -- Clear search highlight
  keymap("n", "<leader>q", ":nohlsearch<CR>", opts)

  -- Buffer navigation
  keymap("n", "<leader>bn", ":bnext<CR>", opts)
  keymap("n", "<leader>bp", ":bprevious<CR>", opts)
  keymap("n", "<leader>bd", ":bdelete<CR>", opts)
  keymap("n", "<leader>bl", ":buffers<CR>", opts)

  -- Mason keybindings
  keymap("n", "<leader>mm", ":Mason<CR>", opts)
  keymap("n", "<leader>mi", ":MasonInstallAll<CR>", opts)
  keymap("n", "<leader>mu", ":MasonUpdate<CR>", opts)
  keymap("n", "<leader>ml", ":Mason<CR>", opts) -- Alias for Mason

  -- Window navigation
  keymap("n", "<C-h>", "<C-w>h", opts)
  keymap("n", "<C-j>", "<C-w>j", opts)
  keymap("n", "<C-k>", "<C-w>k", opts)
  keymap("n", "<C-l>", "<C-w>l", opts)

  -- macOS specific key remappings
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

  -- VSCode-like keyboard shortcuts
  -- Save with Ctrl+S
  keymap("n", "<C-s>", ":w<CR>", opts)
  keymap("i", "<C-s>", "<Esc>:w<CR>", opts)
  
  -- Select all with Ctrl+A
  keymap("n", "<C-a>", "ggVG", opts)
  
  -- Undo with Ctrl+Z
  keymap("n", "<C-z>", "u", opts)
  keymap("i", "<C-z>", "<C-o>u", opts)
  
  -- Redo with Ctrl+Y (VSCode's default is Ctrl+Shift+Z, but Ctrl+Y is also common)
  keymap("n", "<C-y>", "<C-r>", opts)
  keymap("i", "<C-y>", "<C-o><C-r>", opts)
  
  -- Find with Ctrl+F
  keymap("n", "<C-f>", "/", opts)
  keymap("i", "<C-f>", "<Esc>/", opts)
  
  -- Comment line/block with Ctrl+/
  -- Note: this might not work in all terminals, depends on how Ctrl+/ is sent
  keymap("n", "<C-_>", ":lua require('Comment.api').toggle.linewise.current()<CR>", opts)
  keymap("v", "<C-_>", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)

  -- Terminal mode escape
  keymap("t", "<Esc>", "<C-\\><C-n>", opts)
  
  -- Mouse shortcuts - Make Ctrl+Left/Right click simulate common GUI browser behavior
  if vim.fn.has("mouse") == 1 then
    -- Detect iTerm2
    local is_iterm = false
    if vim.env.TERM_PROGRAM == "iTerm.app" or string.match(vim.env.TERM, "^iterm") or vim.env.LC_TERMINAL == "iTerm2" then
      is_iterm = true
    end
    
    -- Ctrl+Left Click to go to definition (like VSCode)
    keymap("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", opts)
    
    -- Ctrl+Right Click to go back (like VSCode/browser back)
    keymap("n", "<C-RightMouse>", "<LeftMouse><C-o>", opts)
    
    -- Alt+Left Click for references (like VSCode)
    keymap("n", "<A-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.references()<CR>", opts)
    
    -- VSCode-like dragging behaviors
    keymap("v", "<LeftDrag>", "<LeftDrag>", opts)  -- Continue selection with drag
    keymap("v", "<LeftRelease>", "<LeftRelease>", opts)
    
    -- VSCode-like multi-cursor with Alt+Click (similar but not exactly the same)
    keymap("n", "<A-LeftMouse>", "<LeftMouse><cmd>normal! viw<CR>gn", opts)
    
    -- Shift+Click to select text (like VSCode)
    keymap("n", "<S-LeftMouse>", "<LeftMouse>v", opts)
    
    -- Double click to select word (already works in Neovim)
    
    -- Triple click to select line (already works in Neovim)
    
    -- Mouse wheel scroll speed adjustments handled in options.lua
    
    -- iTerm2-specific: Enable smooth scrolling
    if is_iterm then
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

  -- :GoBuild and :GoTestCompile
  keymap("n", "<leader>b", "<cmd>lua require('user.go').build_go_files()<CR>", opts)

  -- :GoTest
  keymap("n", "<leader>t", "<Plug>(go-test)", { silent = true, buffer = true })

  -- :GoRun
  keymap("n", "<leader>r", "<Plug>(go-run)", { silent = true, buffer = true })

  -- :GoDoc
  keymap("n", "<leader>d", "<Plug>(go-doc)", { silent = true, buffer = true })

  -- :GoCoverageToggle
  keymap("n", "<leader>c", "<Plug>(go-coverage-toggle)", { silent = true, buffer = true })

  -- :GoInfo
  keymap("n", "<leader>i", "<Plug>(go-info)", { silent = true, buffer = true })

  -- :GoMetaLinter
  keymap("n", "<leader>l", "<Plug>(go-metalinter)", { silent = true, buffer = true })

  -- :GoDef but opens in a vertical split
  keymap("n", "<leader>v", "<Plug>(go-def-vertical)", { silent = true, buffer = true })
  
  -- :GoDef but opens in a horizontal split
  keymap("n", "<leader>s", "<Plug>(go-def-split)", { silent = true, buffer = true })
end

return M 