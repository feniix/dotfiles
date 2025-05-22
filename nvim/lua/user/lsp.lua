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
  
  -- Helper function to safely setup LSP servers
  local function setup_server(server, config)
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

  -- Check what language servers are available
  local servers_available = true
  
  -- Go
  -- Only set up gopls if go.nvim's lsp_cfg is disabled
  -- We check if go.nvim is loaded and has lsp_cfg enabled first
  local setup_gopls = true
  local go_ok, go_nvim = pcall(require, "go")
  if go_ok then
    -- Check if go.nvim has lsp_cfg enabled (it manages gopls)
    if go_nvim.lsp_cfg == true then
      setup_gopls = false
      vim.notify("gopls configuration handled by go.nvim", vim.log.levels.INFO)
    end
  end
  
  if setup_gopls and nvim_lsp.gopls then
    -- Get the Go binary path
    local go_bin_path = ""
    local function get_go_bin_path()
      local gopath = vim.fn.trim(vim.fn.system("go env GOPATH"))
      if gopath == "" then
        gopath = vim.fn.expand("$HOME/.local/share/go")
      end
      return gopath .. "/bin"
    end
    go_bin_path = get_go_bin_path()
    
    -- Define gopls path
    local gopls_path = go_bin_path .. "/gopls"
    if vim.fn.executable(gopls_path) ~= 1 then
      -- Try with just the command name (using PATH)
      if vim.fn.executable("gopls") == 1 then
        gopls_path = "gopls"
      else
        vim.notify("gopls executable not found. Go LSP will not work. Please install gopls.", vim.log.levels.ERROR)
      end
    end
    
    setup_server("gopls", {
      cmd = {gopls_path, "serve"},
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
            shadow = true,
            nilness = true,
            unusedwrite = true,
            useany = true,
          },
          staticcheck = true,
          gofumpt = true,
          usePlaceholders = true,
          completeUnimported = true,
          semanticTokens = true,
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          hoverKind = "FullDocumentation",
          vulncheck = "Imports",
        },
      },
      filetypes = {"go", "gomod", "gowork", "gotmpl"},
      root_dir = function(fname)
        local util = require('lspconfig.util')
        return util.root_pattern("go.work", "go.mod", ".git")(fname)
      end,
      on_attach = function(client, bufnr)
        -- Call the base on_attach function
        on_attach(client, bufnr)
        
        -- Add Go-specific keymaps here
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<leader>gtj', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<leader>gim', '<cmd>lua require("telescope").extensions.goimpl.goimpl()<CR>', opts)
        
        -- Auto-format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = vim.api.nvim_create_augroup("GoFormat", { clear = true }),
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
        
        -- Notify that gopls is properly attached
        vim.notify("gopls attached to buffer", vim.log.levels.INFO)
      end,
    })
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
    local ts_ok, ts = pcall(require, 'user.typescript')
    if ts_ok and ts then
      ts.setup()
    else
      vim.notify("TypeScript module not loaded. TypeScript features will be limited.", vim.log.levels.WARN)
    end
  end

  -- Terraform
  if nvim_lsp.terraformls then
    setup_server("terraformls", {
      settings = {
        terraform = {
          path = "terraform",
          telemetry = { enable = false },
          experimentalFeatures = {
            validateOnSave = true,
          },
        },
      },
    })
    
    -- Format on save for terraform files
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.tf", "*.tfvars" },
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end

  -- JSON language server
  if nvim_lsp.jsonls then
    -- Try to load SchemaStore, but handle if not yet available
    local schemas = {}
    local schemastore_ok, schemastore = pcall(require, 'schemastore')
    if schemastore_ok then
      schemas = schemastore.json.schemas()
    end
    
    setup_server("jsonls", {
      settings = {
        json = {
          schemas = schemas,
          validate = { enable = true },
          format = { enable = true },
        },
      },
      commands = {
        Format = {
          function()
            vim.lsp.buf.range_formatting({}, {0, 0}, {vim.fn.line("$"), 0})
          end
        }
      }
    })
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

  -- YAML LSP
  if nvim_lsp.yamlls then
    setup_server("yamlls", {
      settings = {
        yaml = {
          schemaStore = {
            enable = true,
            url = "https://www.schemastore.org/api/json/catalog.json",
          },
          validate = true,
          completion = true,
          hover = true,
          format = {
            enable = true,
          },
        },
      },
    })
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