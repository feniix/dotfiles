-- User configuration file for Neovim
-- This file allows you to override and customize any aspect of the configuration
-- Copy and modify from config.lua.example for more extensive customization

local M = {}

-- Enable user overrides
M.enabled = true

-- Core vim option overrides (optional)
M.core_overrides = {
  -- Example: override some core options
  -- options = {
  --   number = true,
  --   relativenumber = true,
  --   tabstop = 4,  -- Override to 4 spaces instead of 2
  -- },
  
  -- Example: add custom keymaps
  -- keymaps = {
  --   { "n", "<leader>xx", ":echo 'Hello from user config!'<CR>", { desc = "Test user keymap" } },
  -- },
  
  -- Example: add custom autocommands
  -- autocmds = {
  --   {
  --     event = "BufWritePre", 
  --     pattern = "*.lua",
  --     callback = function()
  --       print("Saving a Lua file!")
  --     end
  --   },
  -- },
}

-- Plugin-specific overrides (optional)
M.plugin_overrides = {
  -- Example: override telescope configuration
  -- telescope = {
  --   defaults = {
  --     prompt_prefix = "🚀 ",  -- Change the prompt
  --   }
  -- },
  
  -- Example: override which-key configuration  
  -- ["which-key"] = {
  --   preset = "helix",  -- Change which-key preset
  -- },
}

-- Additional plugin specifications (optional)
M.additional_plugins = {
  -- Example: add a new plugin
  -- {
  --   "folke/zen-mode.nvim", 
  --   cmd = "ZenMode",
  --   config = function()
  --     require("zen-mode").setup()
  --   end
  -- },
}

-- Lazy.nvim configuration overrides (optional)
M.lazy_overrides = {
  -- Example: change lazy.nvim settings
  -- defaults = {
  --   lazy = false,  -- Make all plugins load on startup
  -- },
}

-- Custom modules to load (optional)
M.custom_modules = {
  -- Example: load a custom module
  -- "user.modules.my_custom_module",
}

-- Post-setup hooks (optional)
M.post_setup_hooks = {
  -- Example: function to run after everything is set up
  -- function()
  --   print("User configuration loaded successfully!")
  -- end,
}

-- Quick test function
function M.test()
  return {
    enabled = M.enabled,
    config_loaded = true,
    timestamp = os.date(),
    message = "User configuration is working! ✅"
  }
end

return M 