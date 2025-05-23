-- New Neovim Configuration Entry Point
-- Reorganized with better separation of concerns

-- Check if we're running in Neovim
if vim.fn.has('nvim') == 0 then
  return
end

-- Load core functionality first
require('core').setup()

-- Load plugin management
require('plugins').setup()

-- Additional post-plugin setup
-- Configure Go globals
vim.g.go_fmt_command = 'goimports'
vim.g.go_list_type = 'quickfix'
vim.g.go_test_timeout = '10s'
vim.g.go_highlight_types = 1
vim.g.go_highlight_fields = 1
vim.g.go_highlight_functions = 1
vim.g.go_highlight_methods = 1
vim.g.go_highlight_operators = 1
vim.g.go_highlight_build_constraints = 1
vim.g.go_highlight_function_calls = 1
vim.g.go_highlight_extra_types = 1
vim.g.go_highlight_generate_tags = 1
vim.g.go_gopls_enabled = 1
vim.g.go_code_completion_enabled = 1
vim.g.go_doc_keywordprg_enabled = 1
vim.g.go_mod_fmt_autosave = 1
vim.g.go_fmt_autosave = 1
vim.g.go_imports_autosave = 1
vim.g.go_diagnostics_enabled = 1
vim.g.go_metalinter_enabled = 1 