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
  -- Check in Packer paths
  local packer_start = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. plugin_name
  local packer_opt = vim.fn.stdpath("data") .. "/site/pack/packer/opt/" .. plugin_name
  
  if vim.fn.isdirectory(packer_start) == 1 then
    return true, "Packer/start"
  elseif vim.fn.isdirectory(packer_opt) == 1 then
    return true, "Packer/opt"
  end
  
  return false, nil
end

-- Check if executable exists in path
local function has_executable(cmd)
  return vim.fn.executable(cmd) == 1
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
  
  -- Check vim-go
  local has_vimgo, vimgo_location = has_plugin("vim-go")
  if has_vimgo then
    ok("vim-go is installed via " .. vimgo_location)
  else
    error("vim-go is missing. Install with :PackerSync")
  end
  
  -- Check Go tools
  if has_executable("go") then
    ok("Go is installed and in PATH")
    
    -- Check Go version
    local go_version = vim.fn.trim(vim.fn.system("go version"))
    info("Go version: " .. go_version)
    
    -- Check essential Go tools
    local go_tools = {
      "goimports", "gofumpt", "golangci-lint", "gomodifytags",
      "gotests", "impl", "dlv", "gorename"
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
      error("nvim-treesitter is installed but cannot be loaded")
    end
  else
    error("nvim-treesitter is missing, install with :PackerSync")
  end
  
  -- Check TreeSitter module
  local user_ts_ok, _ = pcall(require, "user.treesitter")
  if user_ts_ok then
    ok("Treesitter module is loaded correctly")
  else
    error("Treesitter module could not be loaded")
  end
  
  -- Check some basic treesitter parsers
  local parsers_to_check = {
    "lua", "vim", "go", "json", "markdown"
  }
  
  -- Use pcall to protect against any treesitter errors
  local parser_installed = function(lang)
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not ok then return false end
    
    -- Prefer using the newer treesitter API if available
    if parsers.has_parser then
      return parsers.has_parser(lang)
    else
      -- Fallback to older method
      local ok2, configs = pcall(require, "nvim-treesitter.configs")
      if not ok2 then return false end
      
      return vim.fn.executable(
        vim.fn.stdpath("data") .. "/site/pack/packer/start/nvim-treesitter/parser/" .. 
        lang .. ".so"
      ) == 1
    end
  end
  
  for _, lang in ipairs(parsers_to_check) do
    if parser_installed(lang) then
      ok(lang .. " parser is installed")
    else
      warn(lang .. " parser is not installed")
    end
  end
end

-- Check completion plugin configuration
local function check_completion()
  start("Completion Engine Configuration")
  
  -- Check nvim-cmp
  local has_cmp, cmp_location = has_plugin("nvim-cmp")
  if has_cmp then
    local cmp_ok, _ = pcall(require, "cmp")
    if cmp_ok then
      ok("nvim-cmp is installed via " .. cmp_location .. " and loaded correctly")
    else
      error("nvim-cmp is installed but cannot be loaded")
    end
  else
    error("nvim-cmp is missing, install with :PackerSync")
  end
  
  -- Check common sources
  local required_sources = {
    "cmp-buffer", "cmp-path", "cmp-cmdline"
  }
  
  for _, source in ipairs(required_sources) do
    local has_source, source_location = has_plugin(source)
    if has_source then
      ok(source .. " is installed via " .. source_location)
    else
      warn(source .. " is missing, install with :PackerSync for better completion")
    end
  end
end

-- Register the health check with Neovim's built-in health check system
function M.check()
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