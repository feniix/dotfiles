-- Plugin configuration
local M = {}

M.setup = function()
  -- Configure vim-surround (or its Lua replacement)
  local surround_ok, surround = pcall(require, 'nvim-surround')
  if surround_ok then
    surround.setup{}
  end

  -- Configure autopairs
  local autopairs_ok, autopairs = pcall(require, 'nvim-autopairs')
  if autopairs_ok then
    autopairs.setup{}
  end
  
  -- Configure Comment.nvim
  local comment_ok, comment = pcall(require, 'Comment')
  if comment_ok then
    comment.setup()
  end

  -- Set up nvim-surround (replacement for vim-surround)
  local surround_ok, surround = pcall(require, 'nvim-surround')
  if surround_ok then 
    surround.setup{}
  end

  -- Terraform plugin configuration
  vim.g.terraform_align = 0
  vim.g.terraform_fmt_on_save = 0
  
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "terraform",
    callback = function()
      vim.opt_local.commentstring = "#%s"
    end
  })
  
  vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = "*.hcl",
    command = "set filetype=terraform"
  })

  -- Go plugin configuration
  vim.g.go_fmt_command = 'goimports'
  vim.g.go_list_type = 'quickfix'
  vim.g.go_test_timeout = '10s'
  
  -- Disable vim-go features that are better handled by LSP and Tree-sitter
  vim.g.go_highlight_types = 0
  vim.g.go_highlight_fields = 0
  vim.g.go_highlight_functions = 0
  vim.g.go_highlight_methods = 0
  vim.g.go_highlight_operators = 0
  vim.g.go_highlight_build_constraints = 0
  vim.g.go_highlight_function_calls = 0
  vim.g.go_highlight_extra_types = 0
  vim.g.go_highlight_generate_tags = 0
  
  -- Use gopls
  vim.g.go_def_mode = 'gopls'
  vim.g.go_info_mode = 'gopls'
  
  -- Disable vim-go features that conflict with LSP
  vim.g.go_gopls_enabled = 0              -- Disable gopls in vim-go as we use LSP
  vim.g.go_code_completion_enabled = 0    -- Disable vim-go completion as we use LSP
  vim.g.go_doc_keywordprg_enabled = 0     -- Disable K mapping as we use LSP
  vim.g.go_mod_fmt_autosave = 0           -- LSP handles formatting
  vim.g.go_fmt_autosave = 0               -- LSP handles formatting
  vim.g.go_imports_autosave = 0           -- LSP handles formatting
  vim.g.go_diagnostics_enabled = 0        -- LSP handles diagnostics
  vim.g.go_metalinter_enabled = 0         -- LSP handles linting
end

return M 