-- Rust language support plugins
-- Contains Rust-specific development tools and plugins

return {
  -- Rust language support
  {
    "rust-lang/rust.vim",
    ft = "rust",
    config = function()
      -- Configure rust.vim
      vim.g.rustfmt_autosave = 0  -- We handle this in our config
      vim.g.rust_clip_command = 'pbcopy'  -- macOS clipboard
      require("plugins.config.lang.rust").setup()
    end,
  },

  -- Advanced Rust features (crates.io integration, etc.)
  {
    "saecki/crates.nvim",
    ft = { "rust", "toml" },
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('crates').setup({
        src = {
          cmp = {
            enabled = true,
          },
        },
      })
    end,
  },
} 