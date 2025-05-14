-- Common YAML LSP configuration to be used by multiple modules
local M = {}

-- Configuration
local config = {
  auto_format_on_save = true, -- Enable formatting on save
  use_schemas = true, -- Enable YAML schema validation
  configured_lsp_servers = {}, -- To track which servers are already configured
  custom_tags = {
    "!include scalar",
    "!vault scalar",
    "!reference scalar",
    -- Helm template tags
    "!include-template scalar",
    "!template scalar",
  }
}

-- Setup the YAML language server
function M.setup_yaml_ls(schemas, options)
  -- Check if YAML LSP is already configured
  if config.configured_lsp_servers.yamlls then
    vim.notify("YAML LSP already configured, skipping setup", vim.log.levels.DEBUG)
    return
  end
  
  -- Load lspconfig
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("lspconfig not found, cannot set up YAML LSP", vim.log.levels.WARN)
    return
  end
  
  -- Get LSP common module
  local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
  if not lsp_common_ok then
    vim.notify("LSP common module not found, using basic LSP configuration", vim.log.levels.WARN)
    return
  end
  
  -- Get capabilities and on_attach from LSP common
  local capabilities = lsp_common.get_capabilities()
  local base_on_attach = lsp_common.create_on_attach()
  
  -- Create on_attach function with format-on-save
  local on_attach = function(client, bufnr)
    -- Call the base on_attach function
    base_on_attach(client, bufnr)
    
    -- Format on save if enabled
    if config.auto_format_on_save then
      -- Use the tools module if available
      local tools_ok, tools = pcall(require, "user.tools")
      if tools_ok then
        tools.setup_format_on_save(bufnr, "YAML")
      else
        -- Fallback to direct implementation
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = vim.api.nvim_create_augroup("YAMLFormat", { clear = true }),
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end
    end
    
    -- Additional YAML-specific keymaps
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', '<leader>yf', function() vim.lsp.buf.format({ async = true }) end, opts)
  end
  
  -- Configure and set up YAML language server
  lspconfig.yamlls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      yaml = {
        schemaStore = {
          enable = config.use_schemas,
          url = "https://www.schemastore.org/api/json/catalog.json",
        },
        schemas = schemas or {},
        validate = true,
        completion = true,
        hover = true,
        format = {
          enable = true,
          singleQuote = false,
          bracketSpacing = true,
          proseWrap = "preserve",
          printWidth = 120,
        },
        customTags = config.custom_tags
      }
    }
  })
  
  -- Mark as configured
  config.configured_lsp_servers.yamlls = true
end

-- Add custom filetype handlers for YAML
function M.setup_yaml_filetypes(filetypes)
  -- Set up autocmd to configure YAML files
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = filetypes or {"yaml", "yml"},
    callback = function()
      -- Set YAML-specific options
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
    end
  })
end

-- Register custom YAML filetypes with an existing YAML LSP server
function M.register_custom_filetypes(filetypes)
  if not filetypes or #filetypes == 0 then
    return
  end
  
  -- Get current server configuration if it exists
  local clients = vim.lsp.get_active_clients({ name = "yamlls" })
  if #clients == 0 then
    vim.notify("No active YAML LSP server found to register filetypes with", vim.log.levels.WARN)
    return
  end
  
  local current_config = clients[1]
  
  -- Register our custom filetypes with the existing server
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = filetypes,
    callback = function()
      -- Set YAML-specific options
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
      
      -- Attach the server to this buffer if it's not already attached
      vim.lsp.buf_attach_client(0, current_config.id)
    end
  })
end

-- Configure settings
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end
end

return M 