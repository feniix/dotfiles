-- Terraform language support plugins
-- Contains Terraform-specific development tools and plugins

return {
  -- Terraform syntax and commands
  {
    "hashivim/vim-terraform",
    ft = { "terraform", "hcl" },
    config = function()
      require("plugins.config.lang.terraform").setup()
    end,
  },
} 