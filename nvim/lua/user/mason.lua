-- Mason configuration module
local M = {}

-- List of servers to install and configure
-- These names must match what mason-lspconfig recognizes
local servers = {
  -- LSP Servers
  "gopls",            -- Go
  "pyright",          -- Python
  -- "tsserver" is handled by typescript-tools.nvim, no need to include it here
  "lua_ls",           -- Lua
  "jsonls",           -- JSON
  "yamlls",           -- YAML
  "bashls",           -- Bash
  "terraformls",      -- Terraform
  "html",             -- HTML
  "cssls",            -- CSS
  "dockerls",         -- Dockerfile
}

-- List of tools to install via mason-tool-installer
local tools = {
  -- Formatters
  "prettier",        -- JavaScript/TypeScript/CSS/HTML formatter
  "stylua",          -- Lua formatter
  "gofumpt",         -- Go formatter
  "goimports",       -- Go imports formatter
  "black",           -- Python formatter
  "isort",           -- Python import formatter

  -- Linters
  "eslint_d",        -- JavaScript/TypeScript linter
  "golangci-lint",   -- Go linter
  "shellcheck",      -- Shell script linter
  
  -- Language servers (that might not be in the servers list above)
  "typescript-language-server", -- TypeScript/JavaScript (we'll let mason install it but not configure via mason-lspconfig)
}

-- Setup mason
function M.setup()
  -- Check if mason is available
  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    vim.notify("mason.nvim not found. LSP management will be limited.", vim.log.levels.WARN)
    return
  end

  -- Setup with UI configuration
  mason.setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      },
      border = "rounded",
      width = 0.8,
      height = 0.8,
    },
  })

  -- Setup mason-lspconfig bridge
  local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not mason_lspconfig_ok then
    vim.notify("mason-lspconfig.nvim not found. LSP configuration will be limited.", vim.log.levels.WARN)
    return
  end

  -- Configure mason-lspconfig
  mason_lspconfig.setup({
    ensure_installed = servers,
    automatic_installation = true,
  })

  -- Setup automatic installation of other tools
  local mason_tool_installer_ok, mason_tool_installer = pcall(require, "mason-tool-installer")
  if mason_tool_installer_ok then
    mason_tool_installer.setup({
      ensure_installed = tools,
      auto_update = true,
      run_on_start = true,
    })
  end

  -- Get LSP common settings
  local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
  if not lsp_common_ok then
    vim.notify("Could not load LSP common module. Using basic LSP settings.", vim.log.levels.WARN)
    return
  end

  -- Get common configuration
  local capabilities = lsp_common.get_capabilities()
  local on_attach = lsp_common.create_on_attach()

  -- Setup LSP servers
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("nvim-lspconfig not found. LSP features will be limited.", vim.log.levels.WARN)
    return
  end

  -- Configure each server manually since mason-lspconfig might not have setup_handlers yet
  -- This is a more compatible approach
  for _, server_name in ipairs(servers) do
    -- Skip gopls setup if it's being managed by go.nvim
    if server_name == "gopls" then
      local go_ok, go_nvim = pcall(require, "go")
      if go_ok and go_nvim.lsp_cfg == true then
        goto continue -- Skip, as this will be handled by go.nvim
      end
    end

    -- Default configuration
    local opts = {
      on_attach = on_attach,
      capabilities = capabilities,
    }

    -- Server-specific settings
    if server_name == "lua_ls" then
      opts.settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" }, -- Recognize vim global
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      }
    elseif server_name == "jsonls" then
      -- Try to load SchemaStore
      local schemastore_ok, schemastore = pcall(require, "schemastore")
      if schemastore_ok then
        opts.settings = {
          json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true },
          },
        }
      end
    end

    -- Setup the server
    lspconfig[server_name].setup(opts)
    
    ::continue::
  end

  -- Manually setup TypeScript if not using typescript-tools.nvim
  if vim.g.skip_ts_tools then
    -- Check if typescript-language-server is available via PATH or Mason
    if vim.fn.executable("typescript-language-server") == 1 then
      local ts_opts = {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      }
      lspconfig.tsserver.setup(ts_opts)
    end
  end

  -- Create user commands for Mason
  vim.api.nvim_create_user_command("MasonInstallAll", function()
    -- Install all configured LSP servers
    vim.cmd("MasonInstall " .. table.concat(tools, " "))
  end, { desc = "Install all configured Mason packages" })

  vim.api.nvim_create_user_command("MasonUpdateAll", function()
    -- Update all installed packages
    vim.cmd("MasonUpdate")
  end, { desc = "Update all Mason packages" })
end

return M 