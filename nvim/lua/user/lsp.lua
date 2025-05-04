local M = {}

-- LSP settings
M.setup = function()
  -- Safely load LSP configuration
  local lspconfig_ok, nvim_lsp = pcall(require, 'lspconfig')
  if not lspconfig_ok then
    vim.notify("nvim-lspconfig not found. LSP features will be disabled.", vim.log.levels.WARN)
    return
  end
  
  -- Safely get capabilities from cmp_nvim_lsp if available
  local capabilities
  local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if cmp_nvim_lsp_ok then
    capabilities = cmp_nvim_lsp.default_capabilities()
  else
    capabilities = vim.lsp.protocol.make_client_capabilities()
    vim.notify("cmp_nvim_lsp not found. Using basic LSP capabilities.", vim.log.levels.INFO)
  end

  -- Use an on_attach function to set keymaps for each buffer with an active LSP
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
  end

  -- Configure diagnostics
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

  -- Configure individual language servers
  
  -- Go
  if nvim_lsp.gopls then
    nvim_lsp.gopls.setup {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    }
  end

  -- Python
  if nvim_lsp.pyright then
    nvim_lsp.pyright.setup {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            useLibraryCodeForTypes = true,
          }
        }
      }
    }
  end

  -- TypeScript/JavaScript - using typescript-tools.nvim (modern alternative to tsserver)
  -- We've moved TypeScript configuration to its own module
  -- This module handles the setup of typescript-tools.nvim and related settings
  if not vim.g.skip_ts_tools then
    local ts = safe_require('user.typescript')
    if ts then
      ts.setup()
    else
      vim.notify("TypeScript module not loaded. TypeScript features will be limited.", vim.log.levels.WARN)
    end
  end

  -- Terraform
  if nvim_lsp.terraformls then
    nvim_lsp.terraformls.setup {
      on_attach = on_attach,
      capabilities = capabilities,
    }
  end

  -- Lua (for Neovim configuration)
  if nvim_lsp.lua_ls then
    nvim_lsp.lua_ls.setup {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = {'vim'},
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    }
  end

  -- Rust
  if nvim_lsp.rust_analyzer then
    nvim_lsp.rust_analyzer.setup {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          assist = {
            importGranularity = "module",
            importPrefix = "self",
          },
          cargo = {
            loadOutDirsFromCheck = true
          },
          procMacro = {
            enable = true
          },
        }
      }
    }
  end
end

return M 