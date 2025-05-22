local M = {}

-- Note: Most LSP server configurations have been moved to the Mason module (user/mason.lua).
-- This file is kept for backward compatibility and for custom LSP configurations not handled by Mason.
-- 
-- IMPORTANT: To install or update language servers, use:
--  - :Mason - to open the Mason UI
--  - :MasonInstallAll - to install all configured tools
--  - :MasonUpdate - to update all installed tools

-- Set a global flag to disable all Mason-related notifications
vim.g.disable_mason_notifications = true

-- Add a guard to prevent recursive setup
local setup_in_progress = false

-- LSP settings
M.setup = function()
  -- Prevent recursive setup
  if setup_in_progress then
    return
  end
  setup_in_progress = true

  -- Safely load LSP configuration
  local lspconfig_ok, nvim_lsp = pcall(require, 'lspconfig')
  if not lspconfig_ok then
    vim.notify("nvim-lspconfig not found. LSP features will be disabled.", vim.log.levels.WARN)
    setup_in_progress = false
    return
  end
  
  -- Load common LSP configuration
  local lsp_common_ok, lsp_common = pcall(require, 'user.lsp_common')
  if not lsp_common_ok then
    vim.notify("Could not load LSP common module. Using basic LSP configuration.", vim.log.levels.WARN)
    setup_in_progress = false
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

  -- Check if Mason is available
  local mason_ok = pcall(require, "mason")
  if mason_ok and not vim.g.disable_mason_notifications then
    -- Only show this notification once per Neovim session
    if not vim.g.mason_notification_shown then
      vim.notify("Using Mason for LSP server management. This file handles only custom servers.", vim.log.levels.INFO)
      vim.g.mason_notification_shown = true
    end
  end

  -- ---- Custom server configurations not managed by Mason ----

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

  -- Add special server configurations below that aren't handled by Mason
  -- For example, servers with complex configurations or that need special handling
  
  -- TOML language server (if not handled by Mason)
  if not mason_ok and nvim_lsp.taplo then
    setup_server("taplo", {
      settings = {
        taplo = {
          diagnostics = { enable = true },
          formatter = { enable = true, indentTables = true },
        },
      }
    })
  end

  -- Jsonnet language server (if not handled by Mason)
  if nvim_lsp.jsonnet_ls then
    setup_server("jsonnet_ls", {
      cmd = { "jsonnet-language-server", "--stdio" },
      filetypes = { "jsonnet", "libsonnet" },
      settings = {
        jsonnet = {
          extStrs = {},
          formatting = { options = { indent = 2, padding = 2 } }
        }
      },
    })
  end

  -- Reset the recursion guard when done
  setup_in_progress = false
end

return M 