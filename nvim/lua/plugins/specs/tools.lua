-- Development tools and utilities plugin specifications
-- Contains diffview, git tools, and other development utilities

return {
  -- Enhanced diff view
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = function()
      require("plugins.config.diffview").setup()
    end,
  },
} 