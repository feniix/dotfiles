-- Terraform language configuration for Infrastructure as Code development
-- Enhanced configuration for Terraform workflow integration

local M = {}

function M.setup()
  -- Configure Terraform globals
  vim.g.terraform_align = 0
  -- Keep vim-terraform's own save hook off: it formats through its
  -- buffer-local :TerraformFmt, not M.format_terraform. Our hook below reads
  -- g:terraform_format_on_save instead.
  vim.g.terraform_fmt_on_save = 0
  if vim.g.terraform_format_on_save == nil then
    vim.g.terraform_format_on_save = false
  end

  -- One group for every autocmd this module creates, cleared on each
  -- setup() so re-running it does not stack duplicates.
  local augroup = vim.api.nvim_create_augroup("TerraformConfig", { clear = true })

  -- Set up Terraform-specific options
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "terraform", "hcl" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      
      -- Set buffer options
      vim.bo[buf].tabstop = 2
      vim.bo[buf].shiftwidth = 2
      vim.bo[buf].softtabstop = 2
      vim.bo[buf].expandtab = true
      vim.bo[buf].textwidth = 120
      
      -- Set local keymaps
      M.setup_terraform_keymaps(buf)
    end,
    desc = "Terraform buffer configuration",
  })

  -- Set up autocommands for Terraform files
  M.setup_autocmds(augroup)
  
  -- Set up custom commands
  M.setup_commands()
end

function M.setup_terraform_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = buf }
  
  -- <leader>T (capital) keeps these off the global <leader>t toggle maps.
  -- Terraform formatting and validation
  -- vim-terraform's ftplugin defines a buffer-local :TerraformFmt that
  -- shadows ours, so call the formatter directly.
  keymap('n', '<leader>Tf', function() M.format_terraform() end, vim.tbl_extend('force', opts, { desc = 'Terraform format' }))
  keymap('n', '<leader>Tv', ':TerraformValidate<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform validate' }))
  keymap('n', '<leader>Ti', ':TerraformInit<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform init' }))
  keymap('n', '<leader>Tp', ':TerraformPlan<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform plan' }))
  keymap('n', '<leader>Ta', ':TerraformApply<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform apply' }))
  
  -- LSP-specific keymaps (if terraform-ls is available)
  keymap('n', '<leader>Tl', ':TerraformLspToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Terraform LSP' }))
  
  -- Documentation and help
  keymap('n', '<leader>Th', ':TerraformDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform docs' }))
end

function M.setup_autocmds(augroup)
  augroup = augroup or vim.api.nvim_create_augroup("TerraformConfig", { clear = true })
  
  -- Auto-format on save (optional, controlled by global setting)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = { "*.tf", "*.tfvars", "*.hcl" },
    callback = function()
      local enabled = vim.g.terraform_format_on_save
      if enabled == true or enabled == 1 then
        M.format_terraform()
      end
    end,
    desc = "Auto-format Terraform files on save",
  })
  
  -- Set comment string for Terraform files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "terraform", "hcl" },
    callback = function()
      vim.bo.commentstring = "# %s"
    end,
    desc = "Set comment string for Terraform files",
  })
end

function M.setup_commands()
  -- Enhanced Terraform commands
  vim.api.nvim_create_user_command('TerraformInit', function()
    M.run_terraform_command('init')
  end, { desc = 'Run terraform init' })
  
  vim.api.nvim_create_user_command('TerraformPlan', function()
    M.run_terraform_command('plan')
  end, { desc = 'Run terraform plan' })
  
  vim.api.nvim_create_user_command('TerraformApply', function()
    M.run_terraform_command('apply')
  end, { desc = 'Run terraform apply' })
  
  vim.api.nvim_create_user_command('TerraformValidate', function()
    M.run_terraform_command('validate')
  end, { desc = 'Run terraform validate' })
  
  vim.api.nvim_create_user_command('TerraformDestroy', function()
    M.run_terraform_command('destroy')
  end, { desc = 'Run terraform destroy' })
  
  vim.api.nvim_create_user_command('TerraformFmt', function()
    M.format_terraform()
  end, { desc = 'Format current Terraform file' })
  
  vim.api.nvim_create_user_command('TerraformDoc', function()
    M.open_terraform_docs()
  end, { desc = 'Open Terraform documentation' })
  
  vim.api.nvim_create_user_command('TerraformLspToggle', function()
    M.toggle_terraform_lsp()
  end, { desc = 'Toggle Terraform LSP server' })
end

-- Run terraform commands in terminal
function M.run_terraform_command(cmd)
  local current_dir = vim.fn.expand('%:p:h')
  local full_cmd = string.format('cd %s && terraform %s', vim.fn.shellescape(current_dir), cmd)
  
  -- Open terminal and run command
  vim.cmd('botright split')
  vim.cmd('resize 15')
  vim.cmd('terminal ' .. full_cmd)
  vim.cmd('startinsert')
end

-- Format current Terraform file
function M.format_terraform()
  if vim.fn.executable('terraform') == 1 then
    if require('plugins.config.format').buffer(
      { 'terraform', 'fmt', '-no-color', '-' }, 'Terraform'
    ) then
      vim.notify("Terraform file formatted", vim.log.levels.INFO)
    end
  else
    vim.notify("terraform command not found", vim.log.levels.ERROR)
  end
end

-- Open Terraform documentation
function M.open_terraform_docs()
  local url = "https://registry.terraform.io/browse/providers"
  if vim.fn.has('mac') == 1 then
    vim.fn.system('open ' .. url)
  elseif vim.fn.has('unix') == 1 then
    vim.fn.system('xdg-open ' .. url)
  else
    vim.notify("Open " .. url .. " in your browser", vim.log.levels.INFO)
  end
end

-- Toggle Terraform LSP (terraform-ls)
-- This config defines no LSP servers and does not install nvim-lspconfig, so
-- starting only works if a `terraformls` config exists (vim.lsp.config or an
-- lsp/terraformls.lua on the runtimepath). Stopping works for any client.
function M.toggle_terraform_lsp()
  local clients = vim.lsp.get_clients({ name = "terraformls" })
  if #clients > 0 then
    for _, client in ipairs(clients) do
      client:stop()
    end
    vim.notify("Terraform LSP stopped", vim.log.levels.INFO)
    return
  end

  if vim.fn.executable('terraform-ls') == 0 then
    vim.notify("terraform-ls not found. Install it with: go install github.com/hashicorp/terraform-ls@latest", vim.log.levels.WARN)
    return
  end

  local ok, config = pcall(function() return vim.lsp.config.terraformls end)
  if not ok or type(config) ~= 'table' or not config.cmd then
    vim.notify("No LSP configuration for terraformls; define one with vim.lsp.config('terraformls', ...)", vim.log.levels.WARN)
    return
  end

  vim.lsp.enable('terraformls')
  vim.notify("Terraform LSP enabled", vim.log.levels.INFO)
end

return M
