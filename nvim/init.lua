-- New Neovim Configuration Entry Point
-- Reorganized with better separation of concerns

-- Track startup time for performance monitoring
local start_time = vim.loop.hrtime()

-- Check if we're running in Neovim
if vim.fn.has('nvim') == 0 then
  return
end

-- Check Neovim version (require 0.8+)
local nvim_version = vim.version()
if nvim_version.major == 0 and nvim_version.minor < 8 then
  local version_str = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)
  local error_msg = "This configuration requires Neovim 0.8 or higher. Current version: " .. version_str
  
  -- Use vim.notify if available, otherwise fallback to print
  if vim.notify then
    vim.notify(error_msg, vim.log.levels.ERROR)
  else
    print("ERROR: " .. error_msg)
  end
  return
end

-- Set up global safe_require function for error handling
_G.safe_require = function(module)
  local ok, result = pcall(require, module)
  if not ok then
    local error_msg = "Failed to load module: " .. module .. "\nError: " .. result
    
    -- Use vim.notify if available, otherwise fallback to print
    if vim.notify then
      vim.notify(error_msg, vim.log.levels.ERROR)
    else
      print("ERROR: " .. error_msg)
    end
    return nil
  end
  return result
end

-- Set up debug mode (can be enabled via environment variable)
local debug_mode = os.getenv("NVIM_DEBUG") == "1"
if debug_mode then
  vim.notify("Debug mode enabled", vim.log.levels.INFO)
end

-- Validate configuration structure
local config_path = vim.fn.stdpath("config")
local required_dirs = { "lua/core", "lua/plugins" }

for _, dir in ipairs(required_dirs) do
  local full_path = config_path .. "/" .. dir
  if vim.fn.isdirectory(full_path) == 0 then
    vim.notify("Missing required directory: " .. dir, vim.log.levels.ERROR)
    return
  end
end

if debug_mode then
  vim.notify("Configuration structure validated", vim.log.levels.INFO)
end

-- Load core functionality first
if debug_mode then
  vim.notify("Loading core configuration...", vim.log.levels.INFO)
end

local ok, err = pcall(function()
  require('core').setup()
end)

if not ok then
  vim.notify("Failed to load core configuration: " .. err, vim.log.levels.ERROR)
  return
end

if debug_mode then
  vim.notify("Core configuration loaded successfully", vim.log.levels.INFO)
end

-- Load plugin management
if debug_mode then
  vim.notify("Loading plugin management...", vim.log.levels.INFO)
end

local ok, err = pcall(function()
  require('plugins').setup()
end)

if not ok then
  vim.notify("Failed to load plugins: " .. err, vim.log.levels.ERROR)
  -- Continue without plugins rather than failing completely
elseif debug_mode then
  vim.notify("Plugin management loaded successfully", vim.log.levels.INFO)
end

-- Report startup time and final status
local end_time = vim.loop.hrtime()
local startup_time = (end_time - start_time) / 1e6 -- Convert to milliseconds

if debug_mode then
  vim.notify(string.format("Neovim startup completed in %.2f ms", startup_time), vim.log.levels.INFO)
  vim.notify("Configuration loaded successfully", vim.log.levels.INFO)
elseif startup_time > 250 then
  vim.notify(string.format("Neovim startup completed in %.2f ms (consider optimizing)", startup_time), vim.log.levels.WARN)
end

-- Set a global flag to indicate successful initialization
_G.nvim_config_loaded = true
