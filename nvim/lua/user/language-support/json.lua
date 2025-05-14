-- JSON configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true, -- Enable formatting on save
  use_schemas = true -- Enable JSON schema validation
}

-- Function to check if a tool is installed and install it if needed
local function ensure_json_tool(tool, install_cmd)
  if not config.auto_install_tools then
    return
  end

  -- Check if tool is already installed
  if vim.fn.executable(tool) == 1 then
    -- Tool is already installed and available
    return
  end
  
  vim.notify(tool .. " not found, installing...", vim.log.levels.INFO)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system(install_cmd)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install " .. tool .. ": " .. install_result, vim.log.levels.ERROR)
  else
    vim.notify(tool .. " installed successfully", vim.log.levels.INFO)
  end
end

-- Function to install all required JSON tools
local function ensure_json_tools()
  if vim.fn.has("mac") == 1 then
    -- macOS installation via npm/Homebrew
    ensure_json_tool("jq", "brew install jq")
    -- Install the JSON language server if not already installed
    ensure_json_tool("vscode-json-language-server", "npm install -g vscode-langservers-extracted")
  elseif vim.fn.has("unix") == 1 then
    -- Linux installation
    ensure_json_tool("jq", "sudo apt-get install -y jq")
    -- Install the JSON language server if not already installed
    ensure_json_tool("vscode-json-language-server", "npm install -g vscode-langservers-extracted")
  end
end

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Ensure JSON tools are installed
  ensure_json_tools()
  
  -- Configure LSP for JSON if nvim-lspconfig is available
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok and lspconfig.jsonls then
    -- Try to load SchemaStore for JSON schemas
    local schemas = {}
    if config.use_schemas then
      local schemastore_ok, schemastore = pcall(require, "schemastore")
      if schemastore_ok then
        schemas = schemastore.json.schemas()
        vim.notify("Loaded " .. #schemas .. " JSON schemas from SchemaStore", vim.log.levels.INFO)
      else
        vim.notify("SchemaStore not found. Schema validation will be limited.", vim.log.levels.WARN)
      end
    end
    
    -- Set up JSON language server with enhanced settings
    lspconfig.jsonls.setup({
      on_attach = function(client, bufnr)
        -- Call the base LSP on_attach if available
        local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
        if lsp_common_ok and lsp_common.create_on_attach then
          lsp_common.create_on_attach()(client, bufnr)
        end
        
        -- Set up formatting on save
        if config.auto_format_on_save then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("JSONFormat", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
        
        -- Add additional keymaps for JSON
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<leader>jf', function() 
          vim.lsp.buf.format({ async = true }) 
        end, opts)
        vim.keymap.set('n', '<leader>jv', function() 
          vim.cmd('!jq . ' .. vim.fn.shellescape(vim.fn.expand('%')))
        end, opts)
      end,
      settings = {
        json = {
          schemas = schemas,
          validate = { enable = true },
          format = { enable = true }
        }
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
  
  -- Configure JSON specific settings
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"json", "jsonc"},
    callback = function()
      -- Set JSON-specific options
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
      
      -- Add JSON-specific commands
      vim.api.nvim_buf_create_user_command(0, "JSONFormat", function()
        if vim.fn.executable("jq") == 1 then
          -- Format using jq
          vim.cmd('%!jq .')
        else
          -- Fallback to LSP formatting
          vim.lsp.buf.format({ async = false })
        end
      end, {})
      
      vim.api.nvim_buf_create_user_command(0, "JSONMinify", function()
        if vim.fn.executable("jq") == 1 then
          -- Minify using jq
          vim.cmd('%!jq -c .')
        end
      end, {})
    end
  })
end

return M 