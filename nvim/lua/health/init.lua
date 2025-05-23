-- Main health check module for the reorganized Neovim configuration
-- This module coordinates all health checks for the new structure

local M = {}

-- Define health check module (compatible with both old and new APIs)
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Safe require function
local function safe_require(module)
  local success, result = pcall(require, module)
  return success and result or nil
end

-- Check if a health module is available
local function has_health_module(module_name)
  return safe_require("health." .. module_name) ~= nil
end

-- Run a health check module safely
local function run_health_check(module_name, description)
  local health_module = safe_require("health." .. module_name)
  if health_module and health_module.check then
    local success, err = pcall(health_module.check)
    if not success then
      start(description .. " (Error)")
      error("Health check failed: " .. tostring(err))
    end
  else
    start(description .. " (Unavailable)")
    warn("Health check module '" .. module_name .. "' is not available")
  end
end

-- Main comprehensive health check
function M.check()
  start("🚀 Neovim Configuration Health Check")
  info("Checking the reorganized Neovim configuration structure...")
  info("=" .. string.rep("=", 60))
  
  -- Check which health modules are available
  local health_modules = {
    { name = "structure", desc = "📁 Structure & Architecture", priority = 1 },
    { name = "core", desc = "⚙️  Core Modules", priority = 1 },
    { name = "plugins", desc = "🔌 Plugin System", priority = 1 },
    { name = "user_system", desc = "👤 User Override System", priority = 2 },
    { name = "user", desc = "🔧 User Configuration (Legacy)", priority = 3 },
  }
  
  -- Sort by priority
  table.sort(health_modules, function(a, b) return a.priority < b.priority end)
  
  local available_modules = {}
  local unavailable_modules = {}
  
  for _, module in ipairs(health_modules) do
    if has_health_module(module.name) then
      table.insert(available_modules, module)
    else
      table.insert(unavailable_modules, module)
    end
  end
  
  if #available_modules > 0 then
    ok("Found " .. #available_modules .. " health check modules")
  else
    error("No health check modules are available")
    return
  end
  
  if #unavailable_modules > 0 then
    info("Unavailable modules: " .. #unavailable_modules)
  end
  
  -- Run available health checks
  info("Running comprehensive health checks...")
  info("")
  
  for _, module in ipairs(available_modules) do
    run_health_check(module.name, module.desc)
  end
  
  -- Run legacy user health check if available and no new user_system
  if not has_health_module("user_system") and has_health_module("user") then
    info("")
    info("Running legacy user health check...")
    run_health_check("user", "🔧 User Configuration (Legacy)")
  end
  
  -- Summary
  start("📊 Health Check Summary")
  
  info("Configuration Type: Reorganized Structure")
  info("Health Modules Checked: " .. #available_modules)
  
  if #unavailable_modules > 0 then
    warn("Some health modules are not available:")
    for _, module in ipairs(unavailable_modules) do
      warn("  - " .. module.desc .. " (" .. module.name .. ")")
    end
  end
  
  -- Performance overview
  local startup_stats = ""
  local lazy = safe_require("lazy")
  if lazy and lazy.stats then
    local stats = lazy.stats()
    if stats and stats.startuptime then
      startup_stats = " (Startup: " .. string.format("%.2f", stats.startuptime) .. "ms)"
    end
  end
  
  ok("Health check completed" .. startup_stats)
  
  -- Quick help
  info("")
  info("💡 Quick Help:")
  info("  :checkhealth structure  - Check overall structure")
  info("  :checkhealth core       - Check core modules")
  info("  :checkhealth plugins    - Check plugin system")
  info("  :checkhealth user_system - Check user overrides")
  info("  :checkhealth user       - Check legacy user config")
  info("")
  info("For detailed documentation, see:")
  info("  - nvim/docs/README.md")
  info("  - nvim/docs/modules/")
  info("  - nvim/lua/user/README.md")
end

-- Quick check function for essential systems only
function M.quick_check()
  start("⚡ Quick Health Check")
  info("Running essential health checks only...")
  
  -- Check core essentials
  local core = safe_require("core")
  if core then
    ok("Core system is loaded")
  else
    error("Core system failed to load")
  end
  
  -- Check plugin manager
  local lazy = safe_require("lazy")
  if lazy then
    ok("Plugin manager is loaded")
    
    if lazy.stats then
      local stats = lazy.stats()
      if stats then
        info("Plugins: " .. (stats.count or 0) .. " total, " .. (stats.loaded or 0) .. " loaded")
      end
    end
  else
    error("Plugin manager failed to load")
  end
  
  -- Check user system if available
  local user = safe_require("user")
  if user then
    ok("User system is loaded")
  else
    info("User system is not configured (optional)")
  end
  
  ok("Quick check completed")
end

-- Setup function to register health checks and commands
function M.setup()
  -- Create user commands for different health check types
  vim.api.nvim_create_user_command('HealthCheck', function()
    vim.cmd('checkhealth')
  end, { desc = 'Run comprehensive health check' })
  
  vim.api.nvim_create_user_command('HealthQuick', function()
    M.quick_check()
  end, { desc = 'Run quick health check' })
  
  vim.api.nvim_create_user_command('HealthStructure', function()
    vim.cmd('checkhealth structure')
  end, { desc = 'Check configuration structure' })
  
  vim.api.nvim_create_user_command('HealthCore', function()
    vim.cmd('checkhealth core')
  end, { desc = 'Check core modules' })
  
  vim.api.nvim_create_user_command('HealthPlugins', function()
    vim.cmd('checkhealth plugins')
  end, { desc = 'Check plugin system' })
  
  vim.api.nvim_create_user_command('HealthUser', function()
    vim.cmd('checkhealth user_system')
  end, { desc = 'Check user override system' })
  
  -- Set up autocommand to run health check on certain events (optional)
  local health_group = vim.api.nvim_create_augroup("HealthCheck", { clear = true })
  
  -- Optionally run a quick health check after configuration reload
  vim.api.nvim_create_autocmd("User", {
    group = health_group,
    pattern = "ConfigReloaded",
    callback = function()
      vim.defer_fn(function()
        M.quick_check()
      end, 1000)  -- Delay to let everything settle
    end,
    desc = "Run health check after config reload"
  })
  
  -- Show health status in a global variable for other modules to check
  _G.nvim_health_available = true
  _G.nvim_health = M
end

return M 