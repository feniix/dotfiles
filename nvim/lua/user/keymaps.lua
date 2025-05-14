-- Keymaps configuration
local M = {}

M.setup = function()
  -- Leader key is defined in init.vim: let mapleader = ','
  
  -- Save keymaps
  vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })
  vim.keymap.set('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit' })
  vim.keymap.set('n', '<leader>wq', '<cmd>wq<CR>', { desc = 'Save and quit' })
  
  -- Buffer navigation
  vim.keymap.set('n', '<leader>bn', '<cmd>bnext<CR>', { desc = 'Next buffer' })
  vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
  vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'Delete buffer' })
  
  -- Window navigation
  vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
  vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
  vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
  vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })
  
  -- Window resizing
  vim.keymap.set('n', '<M-h>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease window width' })
  vim.keymap.set('n', '<M-j>', '<cmd>resize +2<CR>', { desc = 'Increase window height' })
  vim.keymap.set('n', '<M-k>', '<cmd>resize -2<CR>', { desc = 'Decrease window height' })
  vim.keymap.set('n', '<M-l>', '<cmd>vertical resize +2<CR>', { desc = 'Increase window width' })
  
  -- Better indenting
  vim.keymap.set('v', '<', '<gv', { desc = 'Decrease indent and reselect' })
  vim.keymap.set('v', '>', '>gv', { desc = 'Increase indent and reselect' })
  
  -- Move lines up and down
  vim.keymap.set('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
  vim.keymap.set('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
  vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
  vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
  
  -- LSP keymaps
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Show references' })
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Show hover documentation' })
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
  
  -- Formatting
  vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = 'Format document' })
  
  -- Search
  vim.keymap.set('n', '<leader>/', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
  
  -- Terraform specific keymaps
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "terraform",
    callback = function()
      local opts = { buffer = true, noremap = true, silent = true }
      vim.keymap.set('n', '<leader>ti', '<cmd>!terraform init<CR>', opts)
      vim.keymap.set('n', '<leader>tv', '<cmd>!terraform validate<CR>', opts)
      vim.keymap.set('n', '<leader>tp', '<cmd>!terraform plan<CR>', opts)
      vim.keymap.set('n', '<leader>ta', '<cmd>!terraform apply<CR>', opts)
    end
  })
  
  -- Go specific keymaps
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      local opts = { buffer = true, noremap = true, silent = true }
      vim.keymap.set('n', '<leader>gtj', vim.lsp.buf.type_definition, opts)
      vim.keymap.set('n', '<leader>gim', '<cmd>lua require("telescope").extensions.goimpl.goimpl()<CR>', opts)
      vim.keymap.set('n', '<leader>gt', '<cmd>GoTest<CR>', opts)
      vim.keymap.set('n', '<leader>gtf', '<cmd>GoTestFunc<CR>', opts)
      vim.keymap.set('n', '<leader>gb', '<cmd>GoBuild<CR>', opts)
      vim.keymap.set('n', '<leader>gr', '<cmd>GoRun<CR>', opts)
    end
  })
end

return M 