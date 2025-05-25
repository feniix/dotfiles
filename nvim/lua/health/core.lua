-- Health check module for core Neovim configuration
-- This module validates the integrity of the core configuration modules

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

-- Check if a function exists and is callable
local function is_function(obj)
  return type(obj) == "function"
end

-- Check core.utils module
local function check_core_utils()
  start("Core Utilities Module")
  
  local utils = safe_require("core.utils")
  if not utils then
    error("core.utils module could not be loaded")
    return
  end
  
  ok("core.utils module is loaded successfully")
  
  -- Check platform detection functions
  local platform_functions = {
    "get_os", "get_terminal", "is_gui", "is_ssh", 
    "get_clipboard_config", "get_terminal_config", "get_platform_keymaps"
  }
  
  for _, func_name in ipairs(platform_functions) do
    if utils[func_name] and is_function(utils[func_name]) then
      ok("Platform function '" .. func_name .. "' is available")
    else
      warn("Platform function '" .. func_name .. "' is missing or not callable")
    end
  end
  
  -- Test platform detection
  local os_name = utils.get_os and utils.get_os()
  if os_name then
    info("Detected OS: " .. os_name)
    
    -- Validate OS detection
    local valid_os = { "macos", "linux", "freebsd", "openbsd" }
    local is_valid = false
    for _, valid in ipairs(valid_os) do
      if os_name == valid then
        is_valid = true
        break
      end
    end
    
    if is_valid then
      ok("OS detection is working correctly")
    else
      warn("OS detection returned unexpected value: " .. os_name)
    end
  else
    error("OS detection is not working")
  end
  
  -- Test terminal detection
  local terminal = utils.get_terminal and utils.get_terminal()
  if terminal then
    info("Detected terminal: " .. terminal)
    ok("Terminal detection is working")
  else
    warn("Terminal detection is not working")
  end
  
  -- Test clipboard configuration
  local clipboard_config = utils.get_clipboard_config and utils.get_clipboard_config()
  if clipboard_config then
    ok("Clipboard configuration is available")
    if clipboard_config.name then
      info("Clipboard provider: " .. clipboard_config.name)
    end
  else
    warn("Clipboard configuration is not available")
  end
  
  -- Check utility functions
  local utility_functions = {
    "map", "create_augroup", "merge_tables", "safe_require", "reload_module"
  }
  
  for _, func_name in ipairs(utility_functions) do
    if utils[func_name] and is_function(utils[func_name]) then
      ok("Utility function '" .. func_name .. "' is available")
    else
      warn("Utility function '" .. func_name .. "' is missing or not callable")
    end
  end
  
  -- Test some utilities if they exist
  if utils.safe_require and is_function(utils.safe_require) then
    local test_module = utils.safe_require("vim")
    if test_module then
      ok("safe_require utility is working correctly")
    else
      warn("safe_require utility is not working as expected")
    end
  end
end

-- Check core.options module
local function check_core_options()
  start("Core Options Module")
  
  local options = safe_require("core.options")
  if not options then
    error("core.options module could not be loaded")
    return
  end
  
  ok("core.options module is loaded successfully")
  
  -- Check if setup function exists
  if options.setup and is_function(options.setup) then
    ok("options.setup function is available")
  else
    warn("options.setup function is missing")
  end
  
  -- Validate some critical vim options are set
  local critical_options = {
    { name = "number", expected = true, desc = "Line numbers" },
    { name = "relativenumber", expected = true, desc = "Relative line numbers" },
    { name = "expandtab", expected = true, desc = "Use spaces instead of tabs" },
    { name = "smartindent", expected = true, desc = "Smart indentation" },
    { name = "wrap", expected = false, desc = "Line wrapping disabled" },
    { name = "termguicolors", expected = true, desc = "True color support" },
  }
  
  for _, opt in ipairs(critical_options) do
    local current_value = vim.opt[opt.name]:get()
    if current_value == opt.expected then
      ok(opt.desc .. " is configured correctly")
    else
      warn(opt.desc .. " may not be configured as expected (current: " .. tostring(current_value) .. ", expected: " .. tostring(opt.expected) .. ")")
    end
  end
  
  -- Check clipboard configuration
  local clipboard = vim.opt.clipboard:get()
  if vim.tbl_contains(clipboard, "unnamedplus") or vim.tbl_contains(clipboard, "unnamed") then
    ok("Clipboard integration is configured")
  else
    info("Clipboard integration is not configured (may be platform-specific)")
  end
  
  -- Check backup and swap settings
  if not vim.opt.backup:get() and not vim.opt.writebackup:get() then
    ok("Backup files are disabled")
  else
    info("Backup files are enabled")
  end
  
  if not vim.opt.swapfile:get() then
    ok("Swap files are disabled")
  else
    info("Swap files are enabled")
  end
end

-- Check core.keymaps module
local function check_core_keymaps()
  start("Core Keymaps Module")
  
  local keymaps = safe_require("core.keymaps")
  if not keymaps then
    error("core.keymaps module could not be loaded")
    return
  end
  
  ok("core.keymaps module is loaded successfully")
  
  -- Check if setup function exists
  if keymaps.setup and is_function(keymaps.setup) then
    ok("keymaps.setup function is available")
  else
    warn("keymaps.setup function is missing")
  end
  
  -- Check leader key
  local leader = vim.g.mapleader
  if leader then
    ok("Leader key is set to: '" .. leader .. "'")
  else
    warn("Leader key is not set")
  end
  
  local localleader = vim.g.maplocalleader
  if localleader then
    ok("Local leader key is set to: '" .. localleader .. "'")
  else
    info("Local leader key is not set")
  end
  
  -- Test some critical keymaps (non-invasive check)
  local critical_maps = {
    { mode = "n", lhs = "<C-h>", desc = "Navigate left window" },
    { mode = "n", lhs = "<C-j>", desc = "Navigate down window" },
    { mode = "n", lhs = "<C-k>", desc = "Navigate up window" },
    { mode = "n", lhs = "<C-l>", desc = "Navigate right window" },
  }
  
  for _, map in ipairs(critical_maps) do
    local keymaps_list = vim.api.nvim_get_keymap(map.mode)
    local found = false
    
    for _, keymap in ipairs(keymaps_list) do
      if keymap.lhs == map.lhs then
        found = true
        break
      end
    end
    
    if found then
      ok(map.desc .. " keymap is configured")
    else
      info(map.desc .. " keymap is not found (may be configured differently)")
    end
  end
end

-- Check core.autocmds module
local function check_core_autocmds()
  start("Core Autocommands Module")
  
  local autocmds = safe_require("core.autocmds")
  if not autocmds then
    error("core.autocmds module could not be loaded")
    return
  end
  
  ok("core.autocmds module is loaded successfully")
  
  -- Check if setup function exists
  if autocmds.setup and is_function(autocmds.setup) then
    ok("autocmds.setup function is available")
  else
    warn("autocmds.setup function is missing")
  end
  
  -- Check for existence of critical autogroups
  local autogroups = vim.api.nvim_get_autocmds({})
  local group_names = {}
  
  for _, autocmd in ipairs(autogroups) do
    if autocmd.group_name then
      group_names[autocmd.group_name] = true
    end
  end
  
  local expected_groups = {
    "UserConfig", "highlight_yank", "auto_resize", "checktime"
  }
  
  for _, group in ipairs(expected_groups) do
    if group_names[group] then
      ok("Autogroup '" .. group .. "' is configured")
    else
      info("Autogroup '" .. group .. "' is not found (may be named differently)")
    end
  end
  
  -- Count total autocmds
  local autocmd_count = #autogroups
  if autocmd_count > 0 then
    info("Total autocommands configured: " .. autocmd_count)
    ok("Autocommands are configured")
  else
    warn("No autocommands found")
  end
end

-- Check core module initialization
local function check_core_init()
  start("Core Module Initialization")
  
  local core = safe_require("core")
  if not core then
    error("core module could not be loaded")
    return
  end
  
  ok("core module is loaded successfully")
  
  -- Check if setup function exists
  if core.setup and is_function(core.setup) then
    ok("core.setup function is available")
  else
    warn("core.setup function is missing")
  end
  
  -- Check if all submodules are accessible through core
  local submodules = { "utils", "options", "keymaps", "autocmds" }
  
  for _, submodule in ipairs(submodules) do
    local module_path = "core." .. submodule
    local module = safe_require(module_path)
    if module then
      ok("Submodule '" .. submodule .. "' is accessible")
    else
      warn("Submodule '" .. submodule .. "' could not be loaded")
    end
  end
end

-- Main health check function
function M.check()
  check_core_init()
  check_core_utils()
  check_core_options()
  check_core_keymaps()
  check_core_autocmds()
end

return M 