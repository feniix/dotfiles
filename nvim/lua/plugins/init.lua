-- Plugin management using lazy.nvim
-- Entry point for all plugin specifications and configurations

local M = {}

-- Setup lazy.nvim and load all plugin specifications
function M.setup()
  -- Bootstrap lazy.nvim
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.runtimepath:prepend(lazypath)

  -- Load all plugin specifications
  local plugin_specs = {}
  
  -- Core UI and editor plugins
  vim.list_extend(plugin_specs, require("plugins.specs.ui"))
  vim.list_extend(plugin_specs, require("plugins.specs.editor"))
  
  -- Language support
  vim.list_extend(plugin_specs, require("plugins.specs.lsp"))
  vim.list_extend(plugin_specs, require("plugins.specs.lang.go"))
  vim.list_extend(plugin_specs, require("plugins.specs.lang.terraform"))
  vim.list_extend(plugin_specs, require("plugins.specs.lang.puppet"))
  
  -- Development tools
  vim.list_extend(plugin_specs, require("plugins.specs.tools"))

  -- Setup lazy.nvim with all specifications
  require("lazy").setup(plugin_specs, {
    -- Lazy.nvim configuration
    defaults = {
      lazy = true, -- Make plugins lazy by default
    },
    install = {
      colorscheme = { "neosolarized" }, -- Try to load this colorscheme when installing
    },
    checker = {
      enabled = true,
      notify = false, -- Don't notify about updates
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })
end

return M 