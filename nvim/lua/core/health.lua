-- :checkhealth core
-- Neovim discovers health checks at lua/<name>/health.lua; the checks
-- themselves live in lua/health/core.lua.

local M = {}

function M.check()
  require("health.core").check()
end

return M
