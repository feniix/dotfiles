-- Central repository for YAML schemas
local M = {}

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

return M 