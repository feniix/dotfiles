-- YAML configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true, -- Enable formatting on save
  use_schemas = true, -- Enable YAML schema validation
  configured_lsp_servers = {} -- To track which servers are already configured
}

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Load the common tools module
  local tools_ok, tools = pcall(require, "user.tools")
  if not tools_ok then
    vim.notify("Tools module not found. Manual installation may be required.", vim.log.levels.WARN)
  else
    -- Install required tools using the common tools module
    if vim.fn.has("mac") == 1 then
      tools.ensure_tool("yq", "brew install yq", config.auto_install_tools)
      tools.ensure_tool("yamllint", "brew install yamllint", config.auto_install_tools)
      tools.ensure_tool("yaml-language-server", "npm install -g yaml-language-server", config.auto_install_tools)
    elseif vim.fn.has("unix") == 1 then
      tools.ensure_tool("yq", "sudo apt-get install -y yq", config.auto_install_tools)
      tools.ensure_tool("yamllint", "sudo apt-get install -y yamllint", config.auto_install_tools)
      tools.ensure_tool("yaml-language-server", "npm install -g yaml-language-server", config.auto_install_tools)
    end
  end
  
  -- Load the YAML schema module
  local schemas_ok, yaml_schemas = pcall(require, "user.yaml_schemas")
  if not schemas_ok then
    vim.notify("YAML schema module not found. Using basic schema configuration.", vim.log.levels.WARN)
  end
  
  -- Load the YAML LSP module
  local yaml_lsp_ok, yaml_lsp = pcall(require, "user.yaml_lsp")
  if not yaml_lsp_ok then
    vim.notify("YAML LSP module not found. Using basic LSP configuration.", vim.log.levels.WARN)
  else
    -- Configure the YAML LSP module
    yaml_lsp.setup({
      auto_format_on_save = config.auto_format_on_save,
      use_schemas = config.use_schemas,
      configured_lsp_servers = config.configured_lsp_servers
    })
    
    -- Get schemas for YAML files
    local schemas = {}
    if schemas_ok then
      schemas = yaml_schemas.get_base_schemas()
    else
      -- Fallback schemas if yaml_schemas module not available
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = {
          ".github/workflows/*.{yml,yaml}"
        },
        ["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = {
          "docker-compose.yml", "docker-compose.yaml"
        }
      }
    end
    
    -- Set up the YAML language server with our schemas
    yaml_lsp.setup_yaml_ls(schemas)
    
    -- Set up YAML filetypes
    yaml_lsp.setup_yaml_filetypes({"yaml", "yml"})
  end
  
  -- Configure YAML specific commands
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"yaml", "yml"},
    callback = function()
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