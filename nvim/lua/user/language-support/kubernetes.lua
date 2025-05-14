-- Kubernetes configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true, -- Enable formatting on save
  use_schemas = true, -- Enable K8s schema validation
  custom_schemas = {}, -- User-provided schema paths for CRDs
  operator_schemas = true, -- Enable built-in operator schemas
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
      tools.ensure_tool("yaml-language-server", "npm install -g yaml-language-server", config.auto_install_tools)
    elseif vim.fn.has("unix") == 1 then
      tools.ensure_tool("yq", "sudo apt-get install -y yq", config.auto_install_tools)
      tools.ensure_tool("yaml-language-server", "npm install -g yaml-language-server", config.auto_install_tools)
    end
  end
  
  -- Register Kubernetes filetype detection
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.yaml", "*.yml" },
    callback = function()
      local content = vim.api.nvim_buf_get_lines(0, 0, 30, false)
      local content_str = table.concat(content, "\n")
      
      -- Check if file is a Kubernetes manifest
      if content_str:match("apiVersion:") and 
         (content_str:match("kind:") and 
         (content_str:match("metadata:") or content_str:match("spec:"))) then
        -- Set filetype to kubernetes yaml
        vim.bo.filetype = "yaml.kubernetes"
        
        -- Check if it's a Custom Resource
        local api_version = ""
        local kind = ""
        
        for _, line in ipairs(content) do
          local api_match = line:match("^apiVersion:%s*(.+)$")
          if api_match then
            api_version = api_match
          end
          
          local kind_match = line:match("^kind:%s*(.+)$")
          if kind_match then
            kind = kind_match
          end
          
          if api_version ~= "" and kind ~= "" then
            break
          end
        end
        
        -- If not in core k8s api groups, it's likely a custom resource
        if api_version:match("/") and not (
           api_version:match("^v1$") or 
           api_version:match("^apps/") or 
           api_version:match("^batch/") or 
           api_version:match("^extensions/") or
           api_version:match("^networking.k8s.io/") or
           api_version:match("^rbac.authorization.k8s.io/") or
           api_version:match("^storage.k8s.io/") or
           api_version:match("^autoscaling/")) then
          -- Mark as a custom resource
          vim.b.is_k8s_custom_resource = true
          vim.b.k8s_api_version = api_version
          vim.b.k8s_kind = kind
          
          -- Check for specific operators
          if api_version:match("chaos%-mesh%.org") then
            vim.b.is_chaos_mesh = true
          end
        end
      end
    end
  })
  
  -- Check for Helm Chart.yaml files
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "Chart.yaml" },
    callback = function()
      vim.bo.filetype = "yaml.helm"
    end
  })
  
  -- Check for Kustomization files
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "kustomization.yaml", "kustomization.yml" },
    callback = function()
      vim.bo.filetype = "yaml.kustomize"
    end
  })
  
  -- Determine if file is in a Helm chart directory structure
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*/templates/*.yaml", "*/templates/*.yml", "*/templates/*.tpl" },
    callback = function()
      local path = vim.fn.expand("%:p:h")
      if vim.fn.filereadable(path .. "/../Chart.yaml") == 1 then
        vim.bo.filetype = "yaml.helm"
      end
    end
  })
  
  -- Determine if file is in a Kustomize structure
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*/base/*.yaml", "*/base/*.yml", "*/overlays/*/*.yaml", "*/overlays/*/*.yml" },
    callback = function()
      local path = vim.fn.expand("%:p:h")
      -- Check if there's a kustomization file in this directory
      if vim.fn.filereadable(path .. "/kustomization.yaml") == 1 or 
         vim.fn.filereadable(path .. "/kustomization.yml") == 1 then
        vim.bo.filetype = "yaml.kubernetes"
        -- This is part of a kustomization
        vim.b.is_kustomized = true
      end
    end
  })
  
  -- Load the yaml schemas module
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
    
    -- Get all schemas for Kubernetes
    local schemas = {}
    if schemas_ok then
      schemas = yaml_schemas.get_kubernetes_schemas()
      
      -- Add operator schemas if enabled
      if config.operator_schemas then
        schemas = vim.tbl_deep_extend("force", schemas, yaml_schemas.get_operator_schemas())
      end
      
      -- Add custom schemas if provided
      if config.custom_schemas then
        schemas = yaml_schemas.add_custom_schemas(schemas, config.custom_schemas)
      end
    end
    
    -- If YAML LSP is already configured, just register our custom filetypes
    if config.configured_lsp_servers and config.configured_lsp_servers.yamlls then
      yaml_lsp.register_custom_filetypes({"yaml.kubernetes", "yaml.helm", "yaml.kustomize"})
      
      -- Add Kubernetes schemas to the global registry
      vim.g.kubernetes_schemas = schemas
      
      vim.notify("Kubernetes module: YAML LSP already configured, adding schemas and handlers", vim.log.levels.INFO)
    else
      -- Set up the YAML language server with our schemas
      yaml_lsp.setup_yaml_ls(schemas)
      
      -- Set up Kubernetes-specific YAML filetypes
      yaml_lsp.setup_yaml_filetypes({"yaml.kubernetes", "yaml.helm", "yaml.kustomize"})
    end
  end
end

return M 