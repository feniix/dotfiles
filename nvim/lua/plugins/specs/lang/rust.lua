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
        -- crates.nvim calls on_attach in each Cargo.toml buffer. Register
        -- its nvim-cmp source by hand (the old src.cmp key no longer works
        -- and completion.cmp.enabled is deprecated) and add it to that
        -- buffer's completion sources.
        on_attach = function()
          local ok, cmp = pcall(require, 'cmp')
          if not ok then
            return
          end
          require('crates.completion.cmp').setup()
          cmp.setup.buffer({
            sources = cmp.config.sources(
              { { name = 'crates' } },
              { { name = 'buffer' }, { name = 'path' } }
            ),
          })
        end,
      })
    end,
  },
} 