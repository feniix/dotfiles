local M = {}

-- TypeScript configuration
M.setup = function()
  -- Check if typescript-tools is available
  local typescript_tools_ok, typescript_tools = pcall(require, "typescript-tools")
  if not typescript_tools_ok then
    vim.notify("typescript-tools.nvim not found. TypeScript features will be limited.", vim.log.levels.WARN)
    return
  end

  -- Get common LSP configuration
  local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
  if not lsp_common_ok then
    vim.notify("Could not load LSP common module. Using basic TypeScript configuration.", vim.log.levels.WARN)
    return
  end

  -- TypeScript specific mappings to add to the common on_attach
  local ts_on_attach_extra = function(client, bufnr, bufopts)
    if client.name == "typescript-tools" or client.name == "tsserver" then
      vim.keymap.set("n", "<leader>to", "<cmd>TSToolsOrganizeImports<cr>", bufopts)
      vim.keymap.set("n", "<leader>ta", "<cmd>TSToolsAddMissingImports<cr>", bufopts)
      vim.keymap.set("n", "<leader>tf", "<cmd>TSToolsFixAll<cr>", bufopts)
      vim.keymap.set("n", "<leader>tr", "<cmd>TSToolsRenameFile<cr>", bufopts)
      vim.keymap.set("n", "<leader>tg", "<cmd>TSToolsGoToSourceDefinition<cr>", bufopts)
    end
  end

  -- Configure typescript-tools with optimal settings
  typescript_tools.setup({
    -- Server settings
    on_attach = lsp_common.create_on_attach(ts_on_attach_extra),
    capabilities = lsp_common.get_capabilities(),
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
end

return M 