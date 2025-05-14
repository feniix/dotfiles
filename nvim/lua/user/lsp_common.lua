-- Common LSP functionality shared across language modules
local M = {}

-- Shared on_attach function to be used by all LSP configurations
function M.create_on_attach(extra_mappings)
  -- Return a function that can be used as the on_attach callback
  return function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    
    -- Go to declarations/definitions
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    
    -- Documentation and help
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    
    -- Workspace management
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    
    -- Code actions and refactoring
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
    
    -- Diagnostics
    vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, bufopts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
    vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, bufopts)
    
    -- Apply any extra language-specific mappings
    if extra_mappings then
      extra_mappings(client, bufnr, bufopts)
    end
  end
end

-- Safely get capabilities from cmp_nvim_lsp if available
function M.get_capabilities()
  local capabilities
  local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if cmp_nvim_lsp_ok then
    capabilities = cmp_nvim_lsp.default_capabilities()
  else
    capabilities = vim.lsp.protocol.make_client_capabilities()
  end
  return capabilities
end

-- Configure diagnostics (shared settings)
function M.setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })

  -- Change diagnostic symbols in the sign column
  local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

return M 