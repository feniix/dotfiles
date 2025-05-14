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

-- Function to check if a tool is installed and install it if needed
local function ensure_k8s_tool(tool, install_cmd)
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

-- Function to install all required Kubernetes tools
local function ensure_k8s_tools()
  if vim.fn.has("mac") == 1 then
    -- macOS installation via Homebrew - only what's needed for editing and validation
    ensure_k8s_tool("yq", "brew install yq") -- YAML processing
    -- Language server for K8s
    ensure_k8s_tool("yaml-language-server", "npm install -g yaml-language-server")
  elseif vim.fn.has("unix") == 1 then
    -- Linux installation - only what's needed for editing and validation
    ensure_k8s_tool("yq", "sudo apt-get install -y yq")
    -- Language server
    ensure_k8s_tool("yaml-language-server", "npm install -g yaml-language-server")
  end
end

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Ensure Kubernetes tools are installed
  ensure_k8s_tools()
  
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
  
  -- Configure YAML language server specifically for Kubernetes
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok and lspconfig.yamlls then
    -- Register specific Kubernetes schemas
    local schemas = {
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
      
      -- Chaos Mesh Operator schemas
      -- PodChaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_podchaos.yaml"] = {
        "*podchaos*.yaml", "*podchaos*.yml", "*pod-chaos*.yaml", "*pod-chaos*.yml", 
        "*chaos*pod*.yaml", "*chaos*pod*.yml"
      },
      
      -- NetworkChaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_networkchaos.yaml"] = {
        "*networkchaos*.yaml", "*networkchaos*.yml", "*network-chaos*.yaml", "*network-chaos*.yml",
        "*chaos*network*.yaml", "*chaos*network*.yml"
      },
      
      -- IOChaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_iochaos.yaml"] = {
        "*iochaos*.yaml", "*iochaos*.yml", "*io-chaos*.yaml", "*io-chaos*.yml",
        "*chaos*io*.yaml", "*chaos*io*.yml"
      },
      
      -- TimeChaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_timechaos.yaml"] = {
        "*timechaos*.yaml", "*timechaos*.yml", "*time-chaos*.yaml", "*time-chaos*.yml",
        "*chaos*time*.yaml", "*chaos*time*.yml"
      },
      
      -- StressChaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_stresschaos.yaml"] = {
        "*stresschaos*.yaml", "*stresschaos*.yml", "*stress-chaos*.yaml", "*stress-chaos*.yml",
        "*chaos*stress*.yaml", "*chaos*stress*.yml"
      },
      
      -- Schedule for chaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_schedule.yaml"] = {
        "*chaos*schedule*.yaml", "*chaos*schedule*.yml", "*schedule*chaos*.yaml", "*schedule*chaos*.yml"
      },
      
      -- Workflow for chaos experiments
      ["https://raw.githubusercontent.com/chaos-mesh/chaos-mesh/master/config/crd/bases/chaos-mesh.org_workflow.yaml"] = {
        "*chaos*workflow*.yaml", "*chaos*workflow*.yml", "*workflow*chaos*.yaml", "*workflow*chaos*.yml"
      }
    }
    
    -- Add operator schemas if enabled
    if config.operator_schemas then
      -- Argo CD Operator schemas
      schemas["https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml"] = {
        "*application*.yaml", "*application*.yml", "*argocd*application*.yaml", "*argocd*application*.yml"
      }
      schemas["https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml"] = {
        "*appproject*.yaml", "*appproject*.yml", "*argocd*project*.yaml", "*argocd*project*.yml"
      }
      
      -- Argo Workflows Operator schemas
      schemas["https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start/base/workflow-crd.yaml"] = {
        "*workflow*.yaml", "*workflow*.yml", "*argo*workflow*.yaml", "*argo*workflow*.yml"
      }
      schemas["https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start/base/cronworkflow-crd.yaml"] = {
        "*cronworkflow*.yaml", "*cronworkflow*.yml", "*argo*cron*.yaml", "*argo*cron*.yml"
      }
      
      -- Cert Manager Operator schemas
      schemas["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-certificate.yaml"] = {
        "*certificate*.yaml", "*certificate*.yml", "*cert-manager*cert*.yaml", "*cert-manager*cert*.yml"
      }
      schemas["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-issuer.yaml"] = {
        "*issuer*.yaml", "*issuer*.yml", "*cert-manager*issuer*.yaml", "*cert-manager*issuer*.yml"
      }
      schemas["https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/crds/crd-clusterissuer.yaml"] = {
        "*clusterissuer*.yaml", "*clusterissuer*.yml", "*cert-manager*cluster*.yaml", "*cert-manager*cluster*.yml"
      }
      
      -- Prometheus Operator schemas
      schemas["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"] = {
        "*servicemonitor*.yaml", "*servicemonitor*.yml", "*prometheus*monitor*.yaml", "*prometheus*monitor*.yml"
      }
      schemas["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"] = {
        "*prometheus*.yaml", "*prometheus*.yml", "*prometheus*instance*.yaml", "*prometheus*instance*.yml"
      }
      schemas["https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"] = {
        "*alertmanager*.yaml", "*alertmanager*.yml", "*prometheus*alert*.yaml", "*prometheus*alert*.yml"
      }
      
      -- Istio schemas
      schemas["https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/crds/crd-all.gen.yaml"] = {
        "*virtualservice*.yaml", "*virtualservice*.yml", 
        "*gateway*.yaml", "*gateway*.yml", 
        "*destinationrule*.yaml", "*destinationrule*.yml",
        "*serviceentry*.yaml", "*serviceentry*.yml",
        "*sidecar*.yaml", "*sidecar*.yml",
        "*istio*.yaml", "*istio*.yml"
      }
      
      -- Tekton Pipelines schemas
      schemas["https://raw.githubusercontent.com/tektoncd/pipeline/main/config/300-pipeline.yaml"] = {
        "*pipeline*.yaml", "*pipeline*.yml", "*tekton*pipeline*.yaml", "*tekton*pipeline*.yml"
      }
      schemas["https://raw.githubusercontent.com/tektoncd/pipeline/main/config/300-task.yaml"] = {
        "*task*.yaml", "*task*.yml", "*tekton*task*.yaml", "*tekton*task*.yml"
      }
    end
    
    -- Add user-defined schemas
    if config.custom_schemas then
      for schema_url, patterns in pairs(config.custom_schemas) do
        schemas[schema_url] = patterns
      end
    end
    
    -- Check if YAML LSP is already configured
    if config.configured_lsp_servers and config.configured_lsp_servers.yamlls then
      -- YAML LSP is already configured by another module (likely yaml.lua)
      -- Register our event handlers without reconfiguring the server
      
      -- Get current server configuration
      local current_config = vim.lsp.get_active_clients({ name = "yamlls" })[1]
      
      -- Register our custom filetypes with the existing server
      vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"yaml.kubernetes", "yaml.helm", "yaml.kustomize"},
        callback = function()
          -- Set YAML-specific options
          vim.opt_local.tabstop = 2
          vim.opt_local.shiftwidth = 2
          vim.opt_local.expandtab = true
          
          -- Attach the server to this buffer if it's not already attached
          if current_config then
            vim.lsp.buf_attach_client(0, current_config.id)
          end
        end
      })
      
      -- Add Kubernetes schemas to the YAML LSP schemas registry
      -- Note: This is a bit of a hack, as we can't directly modify the server's settings
      -- So we're setting a global variable that can be accessed by the YAML LSP
      -- This assumes the YAML LSP references this variable in its configuration
      vim.g.kubernetes_schemas = schemas
      
      vim.notify("Kubernetes module: YAML LSP already configured, adding schemas and handlers", vim.log.levels.INFO)
    else
      -- YAML LSP is not configured yet, so we can configure it ourselves
      lspconfig.yamlls.setup({
        on_attach = function(client, bufnr)
          -- Call the base LSP on_attach if available
          local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
          if lsp_common_ok and lsp_common.create_on_attach then
            lsp_common.create_on_attach()(client, bufnr)
          end
          
          -- Format YAML on save if enabled
          if config.auto_format_on_save then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = vim.api.nvim_create_augroup("K8sFormat", { clear = true }),
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
        settings = {
          yaml = {
            schemas = schemas,
            validate = true,
            hover = true,
            completion = true,
            format = {
              enable = true,
              singleQuote = false,
              bracketSpacing = true,
              proseWrap = "preserve",
              printWidth = 120,
            },
            customTags = {
              "!include scalar",
              "!vault scalar",
              "!reference scalar",
              -- Helm template tags
              "!include-template scalar",
              "!template scalar",
            }
          }
        }
      })
      
      -- Mark the YAML LSP as configured
      if config.configured_lsp_servers then
        config.configured_lsp_servers.yamlls = true
      end
    end
  end
  
  -- Configure YAML specific settings for Kubernetes/Helm files
  vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"yaml.kubernetes", "yaml.helm", "yaml.kustomize"},
    callback = function()
      -- Set YAML-specific options
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
    end
  })
end

return M 