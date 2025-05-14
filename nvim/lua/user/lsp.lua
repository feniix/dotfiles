local M = {}

-- LSP settings
M.setup = function()
  -- Safely load LSP configuration
  local lspconfig_ok, nvim_lsp = pcall(require, 'lspconfig')
  if not lspconfig_ok then
    vim.notify("nvim-lspconfig not found. LSP features will be disabled.", vim.log.levels.WARN)
    return
  end
  
  -- Load common LSP configuration
  local lsp_common_ok, lsp_common = pcall(require, 'user.lsp_common')
  if not lsp_common_ok then
    vim.notify("Could not load LSP common module. Using basic LSP configuration.", vim.log.levels.WARN)
    return
  end

  -- Get capabilities from common module
  local capabilities = lsp_common.get_capabilities()
  
  -- Get the base on_attach function
  local on_attach = lsp_common.create_on_attach()
  
  -- Setup diagnostics
  lsp_common.setup_diagnostics()
  
  -- Define language servers that are managed by dedicated language modules
  -- This prevents duplicate configuration
  local language_module_servers = {
    gopls = true,        -- Managed by lua/user/language-support/go.lua
    yamlls = true,       -- Managed by lua/user/language-support/yaml.lua and kubernetes.lua
    jsonls = true,       -- Managed by lua/user/language-support/json.lua
    terraformls = true,  -- Managed by lua/user/language-support/terraform.lua
  }
  
  -- Helper function to safely setup LSP servers
  local function setup_server(server, config)
    -- Skip servers that are managed by language modules
    if language_module_servers[server] then
      return
    end
    
    if not nvim_lsp[server] then return end
    
    if type(nvim_lsp[server].setup) ~= "function" then
      vim.notify(server .. " LSP setup function not available.", vim.log.levels.WARN)
      return
  end

    -- Default config with capabilities and on_attach
    local default_config = {
      on_attach = on_attach,
      capabilities = capabilities,
    }
    
    -- Merge with provided config
    if config then
      for k, v in pairs(config) do
        default_config[k] = v
      end
    end
    
    -- Setup the server
    nvim_lsp[server].setup(default_config)
  end

  -- Python
  if nvim_lsp.pyright then
    setup_server("pyright", {
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            useLibraryCodeForTypes = true,
          }
        }
      }
    })
  end

  -- TypeScript/JavaScript - using typescript-tools.nvim (modern alternative to tsserver)
  -- This module handles the setup of typescript-tools.nvim and related settings
  if not vim.g.skip_ts_tools then
    local ts_ok, ts = pcall(require, 'user.language-support.typescript')
    if ts_ok and ts then
      ts.setup()
    else
      vim.notify("TypeScript module not loaded. TypeScript features will be limited.", vim.log.levels.WARN)
    end
  end

  -- TOML language server
  if nvim_lsp.taplo then
    setup_server("taplo", {
      settings = {
        taplo = {
          diagnostics = {
            enable = true,
          },
          formatter = {
            enable = true,
            indentTables = true,
          },
        },
      }
    })
  end

  -- Docker language server
  if nvim_lsp.dockerls then
    setup_server("dockerls", {
      -- Default config is usually sufficient
      filetypes = { "dockerfile" },
    })
  end

  -- Jsonnet language server
  if nvim_lsp.jsonnet_ls then
    setup_server("jsonnet_ls", {
      -- Basic configuration for jsonnet-language-server
      cmd = { "jsonnet-language-server", "--stdio" },
      filetypes = { "jsonnet", "libsonnet" },
      settings = {
        jsonnet = {
          extStrs = {}, -- Provide external string values if needed
          formatting = {
            options = {
              -- Default formatting options
              indent = 2,
              padding = 2,
              disableSuggestStringMistakes = false,
            }
          },
        }
      },
    })
  end

  -- Ruby LSP
  -- Note: As of lspconfig 0.2.1, ruby_ls is deprecated in favor of ruby_lsp
  if nvim_lsp.ruby_lsp then
    setup_server("ruby_lsp", {
      settings = {
        rubyLsp = {
          formatter = "auto", -- "rubocop", "standardrb", "auto", or nil
          enabledFeatures = {
            "documentHighlights",
            "documentSymbols",
            "foldingRanges",
            "selectionRanges",
            "semanticHighlighting",
            "formatting",
            "diagnostics",
          },
        }
      }
    })
  elseif nvim_lsp.ruby_ls then
    vim.notify("ruby_ls is deprecated, use ruby_lsp instead", vim.log.levels.WARN)
  end

  -- Lua (for Neovim configuration)
  if nvim_lsp.lua_ls then
    setup_server("lua_ls", {
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
    })
  end
end

return M 