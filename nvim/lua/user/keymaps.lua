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

  -- Terminal mode escape
  keymap("t", "<Esc>", "<C-\\><C-n>", opts)
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