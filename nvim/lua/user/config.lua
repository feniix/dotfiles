-- User configuration file for Neovim
-- This file allows you to override and customize any aspect of the configuration
-- Copy and modify from config.lua.example for more extensive customization
--
-- Keys read by lua/user/init.lua: options, keymaps, autocmds, plugins.specs,
-- plugins.config, lazy_config, modules, post_setup. Leave a key out (or
-- commented) to keep the defaults; an empty table still counts as set.

local M = {}

-- Core vim option overrides (optional)
-- M.options = {
--   number = true,
--   relativenumber = true,
--   tabstop = 4,  -- Override to 4 spaces instead of 2
-- }

-- Custom keymaps (optional): { mode, lhs, rhs, opts }
-- M.keymaps = {
--   { "n", "<leader>xx", ":echo 'Hello from user config!'<CR>", { desc = "Test user keymap" } },
-- }

-- Custom autocommands (optional)
-- M.autocmds = {
--   {
--     event = "BufWritePre",
--     pattern = "*.lua",
--     callback = function()
--       print("Saving a Lua file!")
--     end
--   },
-- }

-- M.plugins = {
--   -- Additional plugin specifications, grouped by category
--   specs = {
--     editor = {
--       {
--         "folke/zen-mode.nvim",
--         cmd = "ZenMode",
--         config = function()
--           require("zen-mode").setup()
--         end
--       },
--     },
--   },
--
--   -- Plugin configuration overrides, applied by
--   -- lua/user/overrides/plugins/<name>.lua
--   config = {
--     telescope = {
--       defaults = {
--         prompt_prefix = "🚀 ",  -- Change the prompt
--       }
--     },
--     ["which-key"] = {
--       preset = "helix",  -- Change which-key preset
--     },
--   },
-- }

-- Lazy.nvim configuration overrides (optional)
-- M.lazy_config = {
--   defaults = {
--     lazy = false,  -- Make all plugins load on startup
--   },
-- }

-- Modules to load from lua/user/modules/ (optional)
-- M.modules = {
--   "my_custom_module",
-- }

-- Function to run after everything is set up (optional)
-- function M.post_setup()
--   print("User configuration loaded successfully!")
-- end

-- Quick test function
function M.test()
  return {
    config_loaded = true,
    timestamp = os.date(),
    message = "User configuration is working! ✅"
  }
end

return M
