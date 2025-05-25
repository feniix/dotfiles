-- Health module for user configuration
-- This file is automatically detected by Neovim's :checkhealth command

-- Define a local module
local M = {}

-- Expose check function that will be called by Neovim
function M.check()
  -- Just call our user health module
  local ok, user_health = pcall(require, "user.health")
  if ok then
    user_health.check()
  else
    local health = vim.health or require("health")
    local health_error = health.error or health.report_error
    local start = health.start or health.report_start
    
    start("User Configuration")
    health_error("Could not load user.health module: " .. (user_health or "unknown error"))
  end
end

return M 