-- Go configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true, -- Enable formatting on save
  tools = {
    -- Default required Go tools
    gopls = "golang.org/x/tools/gopls",
    goimports = "golang.org/x/tools/cmd/goimports",
    golangci_lint = "github.com/golangci/golangci-lint/cmd/golangci-lint",
    gomodifytags = "github.com/fatih/gomodifytags",
    gotests = "github.com/cweill/gotests/...",
    impl = "github.com/josharian/impl",
    gofumpt = "mvdan.cc/gofumpt"
  }
}

-- Function to get the Go binary directory
local function get_go_bin_path()
  local gopath = vim.fn.trim(vim.fn.system("go env GOPATH"))
  if gopath == "" then
    -- If GOPATH is not set, use default
    gopath = vim.fn.expand("$HOME/go")
  end
  return gopath .. "/bin"
end

-- Cache the bin path
local go_bin_path = get_go_bin_path()

-- Function to check if a tool is installed and install it if needed
local function ensure_go_tool(tool, package, version)
  if not config.auto_install_tools then
    return
  end

  -- Check if tool exists in go bin path
  local tool_path = go_bin_path .. "/" .. tool
  if vim.fn.filereadable(tool_path) == 1 then
    -- Tool is already installed
    return
  end
  
  -- Also check if it's in PATH
  if vim.fn.executable(tool) == 1 then
    -- Tool is available in PATH
    return
  end
  
  local install_path = package
  if version then
    install_path = install_path .. "@" .. version
  end
  
  vim.notify(tool .. " not found, installing...", vim.log.levels.INFO)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system("go install " .. install_path)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install " .. tool .. ": " .. install_result, vim.log.levels.ERROR)
  else
    vim.notify(tool .. " installed successfully", vim.log.levels.INFO)
  end
end

-- Function to install all required Go tools
local function ensure_go_tools()
  -- Essential tools
  ensure_go_tool("gopls", "golang.org/x/tools/gopls", "latest")
  ensure_go_tool("goimports", "golang.org/x/tools/cmd/goimports", "latest")
  ensure_go_tool("golangci-lint", "github.com/golangci/golangci-lint/cmd/golangci-lint", "latest")
  ensure_go_tool("gomodifytags", "github.com/fatih/gomodifytags", "latest")
  ensure_go_tool("gotests", "github.com/cweill/gotests/...", "latest")
  ensure_go_tool("impl", "github.com/josharian/impl", "latest")
  ensure_go_tool("gofumpt", "mvdan.cc/gofumpt", "latest")
end

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
    -- Fallback to local installation function
    ensure_go_tools_fallback()
  else
    -- Install Go tools using the common tools module
    ensure_go_tools_with_common(tools)
  end
  
  -- Load lspconfig
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("lspconfig not found, cannot set up Go LSP", vim.log.levels.WARN)
    return
  end
  
  -- Get LSP common module
  local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
  if not lsp_common_ok then
    vim.notify("LSP common module not found, using basic Go LSP configuration", vim.log.levels.WARN)
    return
  end
  
  -- Get capabilities and create base on_attach
  local capabilities = lsp_common.get_capabilities()
  local base_on_attach = lsp_common.create_on_attach()
  
  -- Create enhanced on_attach for Go
  local go_on_attach = function(client, bufnr)
    -- First call the base LSP on_attach
    base_on_attach(client, bufnr)
    
    -- Go-specific keymaps
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', '<leader>gtj', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>gim', '<cmd>lua require("telescope").extensions.goimpl.goimpl()<CR>', opts)
    
    -- Auto-format on save if enabled
    if config.auto_format_on_save then
      -- Use the common tools module for format-on-save setup
      local tools_ok, tools = pcall(require, "user.tools")
      if tools_ok then
        tools.setup_format_on_save(bufnr, "Go")
      else
        -- Fallback implementation
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = vim.api.nvim_create_augroup("GoFormat", { clear = true }),
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end
    end
  end
  
  -- Setup gopls with enhanced settings
  lspconfig.gopls.setup({
    on_attach = go_on_attach,
    capabilities = capabilities,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
          fieldalignment = true,
          nilness = true,
          unusedwrite = true,
          useany = true,
        },
        staticcheck = true,
        gofumpt = true,
        usePlaceholders = true,
        completeUnimported = true,
        semanticTokens = true,
        codelenses = {
          gc_details = false,
          generate = true,
          regenerate_cgo = true,
          run_govulncheck = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  })
  
  -- Set up Go-specific commands
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      -- Register buffer-local commands
      vim.api.nvim_buf_create_user_command(0, "GoTest", function()
        vim.cmd("!go test ./...")
      end, {})
      
      vim.api.nvim_buf_create_user_command(0, "GoLint", function()
        if vim.fn.executable("golangci-lint") == 1 then
          vim.cmd("!golangci-lint run")
        else
          vim.notify("golangci-lint not installed. Run :PlugInstall to install missing tools.", vim.log.levels.WARN)
        end
      end, {})
      
      vim.api.nvim_buf_create_user_command(0, "GoGenerate", function()
        vim.cmd("!go generate ./...")
      end, {})
    end
  })
end

-- Install Go tools using our common tools module
function ensure_go_tools_with_common(tools_module)
  for name, path in pairs(config.tools) do
    local success = tools_module.ensure_go_tool(name, path, "latest", config.auto_install_tools)
    if not success then
      vim.notify("Failed to install " .. name .. ". Some Go functionality may be limited.", vim.log.levels.WARN)
    end
  end
end

-- Fallback function when tools module isn't available
function ensure_go_tools_fallback()
  if not config.auto_install_tools then
    return
  end

  for name, path in pairs(config.tools) do
    if vim.fn.executable(name) == 0 then
      vim.notify(name .. " not found, installing...", vim.log.levels.INFO)
      local install_cmd = "go install " .. path .. "@latest"
      local install_result = vim.fn.system(install_cmd)
      
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed to install " .. name .. ": " .. install_result, vim.log.levels.ERROR)
      else
        vim.notify(name .. " installed successfully", vim.log.levels.INFO)
      end
    end
  end
end

return M 