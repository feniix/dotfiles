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

-- Base YAML schemas for common file types
M.get_base_schemas = function()
  return {
    -- Common YAML file types
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
    ["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = {
      "docker-compose.yml", "docker-compose.yaml"
    },
  }
end

-- Kubernetes specific schemas
M.get_kubernetes_schemas = function()
  return {
    kubernetes = {
      "*.k8s.yaml",
      "*.k8s.yml",
      "kubeconfig*",
      "kube/**/*.yaml",
      "kube/**/*.yml",
      "kubernetes/**/*.yaml",
      "kubernetes/**/*.yml",
      "**/templates/**/*.yaml",
      "**/templates/**/*.yml",
      "**.yaml.kubernetes", -- Our custom filetype
      "**.yml.kubernetes"   -- Our custom filetype
    },
    ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = {
      "**/templates/**/*.yaml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = {
      "*.k8s.yaml",
      "*.k8s.yml",
      "kubernetes/**/*.yaml",
      "kubernetes/**/*.yml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/deployment-apps-v1.json"] = {
      "*deployment*.yaml",
      "*deployment*.yml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/service-v1.json"] = {
      "*service*.yaml",
      "*service*.yml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/ingress-extensions-v1beta1.json"] = {
      "*ingress*.yaml",
      "*ingress*.yml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/configmap-v1.json"] = {
      "*configmap*.yaml",
      "*configmap*.yml",
    },
    ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/secret-v1.json"] = {
      "*secret*.yaml",
      "*secret*.yml",
    },
    ["https://json.schemastore.org/kustomization"] = {
      "kustomization.yaml",
      "kustomization.yml",
      "**.yaml.kustomize", -- Our custom filetype
    },
    ["https://json.schemastore.org/helmfile"] = {
      "helmfile.yaml",
      "helmfile.yml",
    },
    
    -- Helm chart schema validation
    ["https://json.schemastore.org/chart.json"] = {
      "Chart.yaml",
    },
    ["https://json.schemastore.org/helm-values.json"] = {
      "values.yaml",
      "**/templates/values.yaml",
    },
    
    -- Knative schemas
    ["https://raw.githubusercontent.com/knative/serving/main/config/core/resources/service.yaml"] = {
      "*knative*service*.yaml", "*knative*service*.yml", "*kservice*.yaml", "*kservice*.yml"
    },
  }
end

-- Kubernetes operator schemas
M.get_operator_schemas = function()
  return {
    -- Chaos Mesh Operator schemas
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_podchaos.yaml"] = {
      "*podchaos*.yaml", "*podchaos*.yml", "*pod-chaos*.yaml", "*pod-chaos*.yml", 
      "*chaos*pod*.yaml", "*chaos*pod*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_networkchaos.yaml"] = {
      "*networkchaos*.yaml", "*networkchaos*.yml", "*network-chaos*.yaml", "*network-chaos*.yml",
      "*chaos*network*.yaml", "*chaos*network*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_iochaos.yaml"] = {
      "*iochaos*.yaml", "*iochaos*.yml", "*io-chaos*.yaml", "*io-chaos*.yml",
      "*chaos*io*.yaml", "*chaos*io*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_timechaos.yaml"] = {
      "*timechaos*.yaml", "*timechaos*.yml", "*time-chaos*.yaml", "*time-chaos*.yml",
      "*chaos*time*.yaml", "*chaos*time*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_stresschaos.yaml"] = {
      "*stresschaos*.yaml", "*stresschaos*.yml", "*stress-chaos*.yaml", "*stress-chaos*.yml",
      "*chaos*stress*.yaml", "*chaos*stress*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_schedule.yaml"] = {
      "*chaos*schedule*.yaml", "*chaos*schedule*.yml", "*schedule*chaos*.yaml", "*schedule*chaos*.yml"
    },
    ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_workflow.yaml"] = {
      "*chaos*workflow*.yaml", "*chaos*workflow*.yml", "*workflow*chaos*.yaml", "*workflow*chaos*.yml"
    },
    
    -- Argo CD Operator schemas
    ["https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml"] = {
      "*application*.yaml", "*application*.yml", "*argocd*application*.yaml", "*argocd*application*.yml"
    },
    ["https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml"] = {
      "*appproject*.yaml", "*appproject*.yml", "*argocd*project*.yaml", "*argocd*project*.yml"
    },
    
    -- Argo Workflows Operator schemas
    ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start/base/workflow-crd.yaml"] = {
      "*workflow*.yaml", "*workflow*.yml", "*argo*workflow*.yaml", "*argo*workflow*.yml"
    },
    ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start/base/cronworkflow-crd.yaml"] = {
      "*cronworkflow*.yaml", "*cronworkflow*.yml", "*argo*cron*.yaml", "*argo*cron*.yml"
    },
    
    -- Cert Manager Operator schemas
    ["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-certificate.yaml"] = {
      "*certificate*.yaml", "*certificate*.yml", "*cert-manager*cert*.yaml", "*cert-manager*cert*.yml"
    },
    ["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-issuer.yaml"] = {
      "*issuer*.yaml", "*issuer*.yml", "*cert-manager*issuer*.yaml", "*cert-manager*issuer*.yml"
    },
    ["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-clusterissuer.yaml"] = {
      "*clusterissuer*.yaml", "*clusterissuer*.yml", "*cert-manager*cluster*.yaml", "*cert-manager*cluster*.yml"
    },
    
    -- Prometheus Operator schemas
    ["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"] = {
      "*servicemonitor*.yaml", "*servicemonitor*.yml", "*prometheus*monitor*.yaml", "*prometheus*monitor*.yml"
    },
    ["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"] = {
      "*prometheus*.yaml", "*prometheus*.yml", "*prometheus*instance*.yaml", "*prometheus*instance*.yml"
    },
    ["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"] = {
      "*alertmanager*.yaml", "*alertmanager*.yml", "*prometheus*alert*.yaml", "*prometheus*alert*.yml"
    },
    
    -- Istio schemas
    ["https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/crds/crd-all.gen.yaml"] = {
      "*virtualservice*.yaml", "*virtualservice*.yml", 
      "*gateway*.yaml", "*gateway*.yml", 
      "*destinationrule*.yaml", "*destinationrule*.yml",
      "*serviceentry*.yaml", "*serviceentry*.yml",
      "*sidecar*.yaml", "*sidecar*.yml",
      "*istio*.yaml", "*istio*.yml"
    },
    
    -- Tekton Pipelines schemas
    ["https://raw.githubusercontent.com/tektoncd/pipeline/main/config/300-pipeline.yaml"] = {
      "*pipeline*.yaml", "*pipeline*.yml", "*tekton*pipeline*.yaml", "*tekton*pipeline*.yml"
    },
    ["https://raw.githubusercontent.com/tektoncd/pipeline/main/config/300-task.yaml"] = {
      "*task*.yaml", "*task*.yml", "*tekton*task*.yaml", "*tekton*task*.yml"
    },
  }
end

-- Get all schemas combined
M.get_all_schemas = function(include_operators)
  local schemas = vim.tbl_deep_extend("force", {}, M.get_base_schemas(), M.get_kubernetes_schemas())
  
  if include_operators then
    schemas = vim.tbl_deep_extend("force", schemas, M.get_operator_schemas())
  end
  
  return schemas
end

-- Add custom schemas to an existing schema table
M.add_custom_schemas = function(schemas, custom_schemas)
  if custom_schemas then
    for schema_url, patterns in pairs(custom_schemas) do
      schemas[schema_url] = patterns
    end
  end
  return schemas
end

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