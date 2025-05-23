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
  vim.list_extend(plugin_specs, require("plugins.specs.lang.python"))
  vim.list_extend(plugin_specs, require("plugins.specs.lang.rust"))
  
  -- Development tools
  vim.list_extend(plugin_specs, require("plugins.specs.tools"))

  -- Add user plugin specifications
  local ok, user = pcall(require, 'user')
  if ok then
    local user_overrides = user.get_plugin_overrides()
    for category, specs in pairs(user_overrides) do
      if type(specs) == 'table' then
        vim.list_extend(plugin_specs, specs)
      end
    end
  end

  -- Get user lazy config overrides
  local lazy_config = {
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
  }
  
  -- Apply user lazy config overrides
  if ok then
    local user_lazy_config = user.get_lazy_config_overrides()
    lazy_config = vim.tbl_deep_extend('force', lazy_config, user_lazy_config)
  end

  -- Setup lazy.nvim with all specifications
  require("lazy").setup(plugin_specs, lazy_config)
  
  -- Apply user plugin configuration overrides after plugins are loaded
  if ok then
    -- Use a timer to apply overrides after plugins are setup
    vim.defer_fn(function()
      user.setup_plugin_overrides()
      user.run_post_setup_hooks()
    end, 100)
  end
end

return M 