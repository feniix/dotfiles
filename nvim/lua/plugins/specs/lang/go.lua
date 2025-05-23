-- Go language support plugins
-- Contains Go-specific development tools and plugins

return {
  -- Go development support
  {
    "fatih/vim-go",
    ft = "go",
    build = ":GoUpdateBinaries",
    config = function()
      require("plugins.config.lang.go").setup()
    end,
  },
} 