-- :checkhealth plugins
-- Neovim discovers health checks at lua/<name>/health.lua; the checks
-- themselves live in lua/health/plugins.lua.

local M = {}

function M.check()
  require("health.plugins").check()
end

return M
