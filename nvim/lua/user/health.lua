-- Health check module for Neovim configuration
local M = {}

-- Define health check module
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Check if plugin exists in any of the possible locations
local function has_plugin(plugin_name)
  -- Check in Packer paths (preferred)
  local packer_start = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. plugin_name
  local packer_opt = vim.fn.stdpath("data") .. "/site/pack/packer/opt/" .. plugin_name
  
  if vim.fn.isdirectory(packer_start) == 1 then
    return true, "Packer/start"
  elseif vim.fn.isdirectory(packer_opt) == 1 then
    return true, "Packer/opt"
  end
  
  -- Legacy path check for vim-plug (for backward compatibility)
  local vimplug_path = vim.fn.stdpath("data") .. "/plugged/" .. plugin_name
  if vim.fn.isdirectory(vimplug_path) == 1 then
    return true, "vim-plug"
  end
  
  return false, nil
end

-- Check if executable exists in path
local function has_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Check language servers
local function check_lsp()
  start("LSP Configuration")
  
  -- Check LSP modules
  local lsp_ok, _ = pcall(require, "user.lsp")
  if lsp_ok then
    ok("LSP module is loaded correctly")
  else
    error("LSP module could not be loaded")
  end
  
  local lsp_common_ok, _ = pcall(require, "user.lsp_common")
  if lsp_common_ok then
    ok("LSP common module is loaded correctly")
  else
    error("LSP common module could not be loaded")
  end
  
  -- Check lspconfig plugin
  local has_lspconfig, location = has_plugin("nvim-lspconfig")
  if has_lspconfig then
    ok("nvim-lspconfig is installed via " .. location)
  else
    error("nvim-lspconfig is missing, install with :PackerSync")
  end
  
  -- Check language servers
  -- Go - gopls
  if has_executable("gopls") then
    ok("gopls (Go language server) is installed")
  else
    warn("gopls is not found in PATH. Go language support may not work correctly")
    
    -- Check if gopls is installed in Go bin path
    local go_bin = vim.fn.trim(vim.fn.system("go env GOPATH")) .. "/bin"
    if vim.fn.isdirectory(go_bin) == 1 and vim.fn.filereadable(go_bin .. "/gopls") == 1 then
      info("gopls is installed in Go bin path (" .. go_bin .. "), but not in PATH")
    end
  end
  
  -- TypeScript - typescript-tools
  local has_ts_tools, location = has_plugin("typescript-tools.nvim") 
  if has_ts_tools then
    ok("typescript-tools.nvim is installed via " .. location)
  else
    warn("typescript-tools.nvim is missing, TypeScript support may be limited")
  end
  
  -- YAML - yamlls
  if has_executable("yaml-language-server") then
    ok("yaml-language-server is installed")
  else
    info("yaml-language-server not found. YAML support may be limited")
  end
  
  -- Check Lua - lua_ls
  if has_executable("lua-language-server") then
    ok("lua-language-server is installed")
  else
    info("lua-language-server not found. Lua LSP support may be limited")
  end
end

-- Check debugger configuration
local function check_dap()
  start("Debugging Configuration")
  
  -- Check DAP module
  local dap_ok, _ = pcall(require, "dap")
  if dap_ok then
    ok("DAP module is loaded correctly")
  else
    error("DAP module could not be loaded")
  end
  
  -- Check DAP UI
  local has_dapui, dapui_location = has_plugin("nvim-dap-ui")
  if has_dapui then
    local dapui_ok, _ = pcall(require, "dapui")
    if dapui_ok then
      ok("nvim-dap-ui is installed via " .. dapui_location .. " and loaded correctly")
    else
      warn("nvim-dap-ui is installed but cannot be loaded")
    end
  else
    warn("nvim-dap-ui is missing, install with :PackerSync")
  end
  
  -- Check nvim-nio dependency
  local has_nio, nio_location = has_plugin("nvim-nio")
  if has_nio then
    ok("nvim-nio is installed via " .. nio_location .. " (required by nvim-dap-ui)")
  else
    error("nvim-nio is missing, but is required by nvim-dap-ui. Install with :PackerSync")
  end
  
  -- Check virtual text 
  local has_vt, vt_location = has_plugin("nvim-dap-virtual-text")
  if has_vt then
    local vt_ok, _ = pcall(require, "nvim-dap-virtual-text")
    if vt_ok then
      ok("nvim-dap-virtual-text is installed via " .. vt_location .. " and loaded correctly")
    else
      warn("nvim-dap-virtual-text is installed but cannot be loaded")
    end
  else
    info("nvim-dap-virtual-text is missing, install for enhanced debugging experience")
  end
  
  -- Check language-specific debugger support
  -- Go - delve
  if has_executable("dlv") then
    ok("dlv (Delve) debugger for Go is installed")
  else
    warn("dlv debugger is not found in PATH. Go debugging may not work correctly")
  end
end

-- Check Go configuration
local function check_go()
  start("Go Development Environment")
  
  -- Check Go module
  local go_ok, _ = pcall(require, "user.go")
  if go_ok then
    ok("Go module is loaded correctly")
  else
    error("Go module could not be loaded")
  end
  
  -- Check go.nvim
  local has_gonvim, gonvim_location = has_plugin("go.nvim")
  if has_gonvim then
    local gonvim_ok, gonvim = pcall(require, "go")
    if gonvim_ok then
      ok("go.nvim is installed via " .. gonvim_location .. " and loaded correctly")
      
      -- Check lsp_cfg settings
      if gonvim.lsp_cfg == true then
        ok("go.nvim lsp_cfg is enabled, handling gopls configuration")
      else
        warn("go.nvim lsp_cfg is disabled, gopls is managed by lspconfig")
      end
    else
      warn("go.nvim is installed but cannot be loaded")
    end
  else
    warn("go.nvim is missing, install with :PackerSync")
  end
  
  -- Check vim-go
  local has_vimgo, vimgo_location = has_plugin("vim-go")
  if has_vimgo then
    ok("vim-go is installed via " .. vimgo_location)
  else
    info("vim-go is missing. Basic Go functionality may still work with go.nvim")
  end
  
  -- Check Go tools
  if has_executable("go") then
    ok("Go is installed and in PATH")
    
    -- Check Go version
    local go_version = vim.fn.trim(vim.fn.system("go version"))
    info("Go version: " .. go_version)
    
    -- Check essential Go tools
    local go_tools = {
      "gopls", "goimports", "gofumpt", "golangci-lint", "gomodifytags",
      "gotests", "impl", "dlv"
    }
    
    for _, tool in ipairs(go_tools) do
      if has_executable(tool) then
        ok(tool .. " is installed")
      else
        warn(tool .. " is not found in PATH")
      end
    end
  else
    error("Go is not installed or not in PATH")
  end
end

-- Check treesitter setup
local function check_treesitter()
  start("Treesitter Configuration")
  
  local has_ts, ts_location = has_plugin("nvim-treesitter")
  if has_ts then
    local ts_ok, _ = pcall(require, "nvim-treesitter")
    if ts_ok then
      ok("nvim-treesitter is installed via " .. ts_location .. " and loaded correctly")
    else
      warn("nvim-treesitter is installed but cannot be loaded")
    end
    
    -- Check treesitter module
    local tsmod_ok, _ = pcall(require, "user.treesitter")
    if tsmod_ok then
      ok("User treesitter module is loaded correctly")
    else
      warn("User treesitter module could not be loaded")
    end
    
    -- Check installed parsers
    local parsers_ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if parsers_ok then
      local installed_parsers = {}
      for name, _ in pairs(parsers.get_parser_configs()) do
        if parsers.has_parser(name) then
          table.insert(installed_parsers, name)
        end
      end
      
      if #installed_parsers > 0 then
        ok("Installed parsers: " .. table.concat(installed_parsers, ", "))
      else
        warn("No treesitter parsers installed. Run :TSInstall for your languages")
      end
    else
      warn("Could not check installed parsers")
    end
  else
    error("nvim-treesitter is missing, install with :PackerSync")
  end
end

-- Check completion setup
local function check_completion()
  start("Completion Configuration")
  
  -- Check nvim-cmp
  local has_cmp, cmp_location = has_plugin("nvim-cmp")
  if has_cmp then
    local cmp_ok, _ = pcall(require, "cmp")
    if cmp_ok then
      ok("nvim-cmp is installed via " .. cmp_location .. " and loaded correctly")
    else
      warn("nvim-cmp is installed but cannot be loaded")
    end
  else
    error("nvim-cmp is missing, install with :PackerSync")
  end
  
  -- Check snippet engine
  local has_luasnip, luasnip_location = has_plugin("LuaSnip")
  if has_luasnip then
    local ls_ok, _ = pcall(require, "luasnip")
    if ls_ok then
      ok("LuaSnip is installed via " .. luasnip_location .. " and loaded correctly")
    else
      warn("LuaSnip is installed but cannot be loaded")
    end
  else
    warn("LuaSnip is missing, install with :PackerSync")
  end
  
  -- Check sources
  local sources = {
    "cmp-nvim-lsp", "cmp-buffer", "cmp-path", 
    "cmp-cmdline", "cmp_luasnip"
  }
  
  for _, source in ipairs(sources) do
    local has_source, location = has_plugin(source)
    if has_source then
      ok(source .. " is installed via " .. location)
    else
      info(source .. " is missing, install for enhanced completion")
    end
  end
end

-- Register the health check with Neovim's built-in health check system
function M.check()
  check_lsp()
  check_dap()
  check_go()
  check_treesitter()
  check_completion()
end

-- Setup function that creates user command and hooks into Neovim's health check
function M.setup()
  -- Create a user command for direct access
  vim.api.nvim_create_user_command('UserConfig', function()
    vim.cmd('checkhealth user')
  end, { desc = 'Check your Neovim configuration health' })
end

return M 