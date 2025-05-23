-- Python language support plugins
-- Contains Python-specific development tools and plugins

return {
  -- Python indentation and syntax (built-in vim support is usually sufficient)
  -- But we can add enhanced syntax if needed
  {
    "vim-python/python-syntax",
    ft = "python",
    config = function()
      -- Enhanced Python syntax highlighting
      vim.g.python_highlight_all = 1
      require("plugins.config.lang.python").setup()
    end,
  },

  -- Python docstring support
  {
    "heavenshell/vim-pydocstring",
    ft = "python",
    build = "make install",
    cmd = { "Pydocstring" },
  },

  -- Python text objects
  {
    "jeetsukumaran/vim-pythonsense",
    ft = "python",
  },
} 