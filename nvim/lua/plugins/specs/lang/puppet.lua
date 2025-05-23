-- Puppet language support plugins
-- Contains Puppet-specific development tools and plugins

return {
  -- Puppet syntax support
  {
    "rodjek/vim-puppet",
    ft = "puppet",
    config = function()
      require("plugins.config.lang.puppet").setup()
    end,
  },
}