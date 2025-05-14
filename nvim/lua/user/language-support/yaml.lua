-- YAML configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true, -- Enable formatting on save
  use_schemas = true -- Enable YAML schema validation
}

-- Function to check if a tool is installed and install it if needed
local function ensure_yaml_tool(tool, install_cmd)
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

-- Function to install all required YAML tools
local function ensure_yaml_tools()
  if vim.fn.has("mac") == 1 then
    -- macOS installation via npm/Homebrew
    ensure_yaml_tool("yq", "brew install yq")
    ensure_yaml_tool("yamllint", "brew install yamllint")
    -- Install the YAML language server if not already installed
    ensure_yaml_tool("yaml-language-server", "npm install -g yaml-language-server")
  elseif vim.fn.has("unix") == 1 then
    -- Linux installation
    ensure_yaml_tool("yq", "sudo apt-get install -y yq")
    ensure_yaml_tool("yamllint", "sudo apt-get install -y yamllint")
    -- Install the YAML language server if not already installed
    ensure_yaml_tool("yaml-language-server", "npm install -g yaml-language-server")
  end
end

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Ensure YAML tools are installed
  ensure_yaml_tools()
  
  -- Configure LSP for YAML if nvim-lspconfig is available
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok and lspconfig.yamlls then
    -- Set up YAML language server with enhanced settings
    lspconfig.yamlls.setup({
      on_attach = function(client, bufnr)
        -- Call the base LSP on_attach if available
        local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
        if lsp_common_ok and lsp_common.create_on_attach then
          lsp_common.create_on_attach()(client, bufnr)
        end
        
        -- Set up formatting on save
        if config.auto_format_on_save then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("YAMLFormat", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
        
        -- Add additional keymaps for YAML
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<leader>yf', function() 
          vim.lsp.buf.format({ async = true }) 
        end, opts)
        vim.keymap.set('n', '<leader>yv', function() 
          if vim.fn.executable('yamllint') == 1 then
            vim.cmd('!yamllint ' .. vim.fn.shellescape(vim.fn.expand('%')))
          end
        end, opts)
      end,
      settings = {
        yaml = {
          schemaStore = {
            enable = config.use_schemas,
            url = "https://www.schemastore.org/api/json/catalog.json",
          },
          schemas = {
            kubernetes = {"/*.k8s.yaml", "/*.k8s.yml", "/kubernetes/**/*.yaml", "/kubernetes/**/*.yml"},
            ["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = {
              "docker-compose.yml", "docker-compose.yaml"
            },
            ["https://json.schemastore.org/github-workflow.json"] = {
              ".github/workflows/*.{yml,yaml}"
            },
            ["https://json.schemastore.org/github-action.json"] = {
              "action.{yml,yaml}"
            },
            ["https://json.schemastore.org/circleciconfig.json"] = {
              ".circleci/config.{yml,yaml}"
            },
            ["https://json.schemastore.org/gitlab-ci.json"] = {
              ".gitlab-ci.{yml,yaml}"
            },
            ["https://json.schemastore.org/kustomization.json"] = {
              "kustomization.{yml,yaml}"
            },
            ["https://json.schemastore.org/helmfile.json"] = {
              "helmfile.{yml,yaml}"
            },
          },
          validate = true,
          format = {
            enable = true
          },
          hover = true,
          completion = true,
          customTags = {
            "!include scalar",
            "!vault scalar"
          }
        }
      }
    })
  end
  
  -- Configure YAML specific settings
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"yaml", "yml"},
    callback = function()
      -- Set YAML-specific options
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
      
      -- Add YAML-specific commands
      vim.api.nvim_buf_create_user_command(0, "YAMLLint", function()
        if vim.fn.executable("yamllint") == 1 then
          vim.cmd('!yamllint ' .. vim.fn.shellescape(vim.fn.expand('%')))
        else
          vim.notify("yamllint not installed. Run :PlugInstall to install missing tools.", vim.log.levels.WARN)
        end
      end, {})
      
      -- Add command to convert YAML to JSON
      vim.api.nvim_buf_create_user_command(0, "YAMLToJSON", function()
        if vim.fn.executable("yq") == 1 then
          vim.cmd('%!yq -o=json .')
          vim.bo.filetype = "json"
        else
          vim.notify("yq not installed. Run :PlugInstall to install missing tools.", vim.log.levels.WARN)
        end
      end, {})
      
      -- Add command to convert JSON to YAML
      vim.api.nvim_buf_create_user_command(0, "JSONToYAML", function()
        if vim.fn.executable("yq") == 1 then
          vim.cmd('%!yq -P .')
          vim.bo.filetype = "yaml"
        else
          vim.notify("yq not installed. Run :PlugInstall to install missing tools.", vim.log.levels.WARN)
        end
      end, {})
    end
  })
end

return M 