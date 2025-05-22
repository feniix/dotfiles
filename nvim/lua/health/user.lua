-- Health module for user configuration
-- This file is automatically detected by Neovim's :checkhealth command

-- Define a local module
local M = {}

-- Expose check function that will be called by Neovim
function M.check()
  -- Just call our user health module
  local ok, health = pcall(require, "user.health")
  if ok then
    health.check()
  else
    local health = vim.health or require("health")
    local error = health.error or health.report_error
    local start = health.start or health.report_start
    
    start("User Configuration")
    error("Could not load user.health module: " .. (health or "unknown error"))
  end
end

return M 