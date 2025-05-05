local M = {}

-- TypeScript configuration
M.setup = function()
  -- Check if typescript-tools is available
  local typescript_tools_ok, typescript_tools = pcall(require, "typescript-tools")
  if not typescript_tools_ok then
    vim.notify("typescript-tools.nvim not found. TypeScript features will be limited.", vim.log.levels.WARN)
    return
  end

  -- Get lsp shared on_attach function if available
  local on_attach = function(client, bufnr)
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
    
    -- Code actions and refactoring
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
    
    -- TypeScript specific commands
    if client.name == "typescript-tools" or client.name == "tsserver" then
      vim.keymap.set("n", "<leader>to", "<cmd>TSToolsOrganizeImports<cr>", bufopts)
      vim.keymap.set("n", "<leader>ta", "<cmd>TSToolsAddMissingImports<cr>", bufopts)
      vim.keymap.set("n", "<leader>tf", "<cmd>TSToolsFixAll<cr>", bufopts)
      vim.keymap.set("n", "<leader>tr", "<cmd>TSToolsRenameFile<cr>", bufopts)
      vim.keymap.set("n", "<leader>tg", "<cmd>TSToolsGoToSourceDefinition<cr>", bufopts)
    end
  end

  -- Safely get capabilities from cmp_nvim_lsp if available
  local capabilities
  local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if cmp_nvim_lsp_ok then
    capabilities = cmp_nvim_lsp.default_capabilities()
  else
    capabilities = vim.lsp.protocol.make_client_capabilities()
  end

  -- Configure typescript-tools with optimal settings
  typescript_tools.setup({
    -- Server settings
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      -- Specify typescript-tools.nvim specific settings
      expose_as_code_action = "all",
      -- Enable inlay hints
      tsserver_file_preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      -- Formatting options
      tsserver_format_options = {
        allowIncompleteCompletions = false,
        allowRenameOfImportPath = false,
      },
      -- JSDoc settings
      complete_function_calls = true,
      include_completions_with_insert_text = true,
    },
    -- LSP settings
    handlers = {
      ["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
        if result.diagnostics == nil then
          return
        end

        -- Filter out some specific TypeScript diagnostics if needed
        local filtered_diagnostics = vim.tbl_filter(function(diagnostic)
          -- Example: filter out "requires type annotations" messages if they're too noisy
          -- return diagnostic.code ~= 7016
          return true
        end, result.diagnostics)

        result.diagnostics = filtered_diagnostics
        vim.lsp.handlers["textDocument/publishDiagnostics"](_, result, ctx, config)
      end,
    },
  })
  
  -- Disable ALE for TypeScript files since LSP will handle diagnostics
  vim.cmd([[
    augroup typescript_ale_disable
      autocmd!
      autocmd FileType typescript,typescriptreact,javascript,javascriptreact let b:ale_disable_lsp = 1
    augroup END
  ]])
end

return M 