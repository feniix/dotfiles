-- Terraform language configuration for Infrastructure as Code development
-- Enhanced configuration for Terraform workflow integration

local M = {}

function M.setup()
  -- Configure Terraform globals
  vim.g.terraform_align = 0
  vim.g.terraform_fmt_on_save = 0  -- We'll handle this with autocmds

  -- Set up Terraform-specific options
  vim.api.nvim_create_autocmd("FileType", {
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
  M.setup_autocmds()
  
  -- Set up custom commands
  M.setup_commands()
end

function M.setup_terraform_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = buf }
  
  -- Terraform formatting and validation
  keymap('n', '<leader>tf', ':TerraformFmt<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform format' }))
  keymap('n', '<leader>tv', ':TerraformValidate<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform validate' }))
  keymap('n', '<leader>ti', ':TerraformInit<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform init' }))
  keymap('n', '<leader>tp', ':TerraformPlan<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform plan' }))
  keymap('n', '<leader>ta', ':TerraformApply<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform apply' }))
  
  -- LSP-specific keymaps (if terraform-ls is available)
  keymap('n', '<leader>tl', ':TerraformLspToggle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle Terraform LSP' }))
  
  -- Documentation and help
  keymap('n', '<leader>th', ':TerraformDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Terraform docs' }))
end

function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("TerraformConfig", { clear = true })
  
  -- Auto-format on save (optional, controlled by global setting)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = { "*.tf", "*.tfvars", "*.hcl" },
    callback = function()
      if vim.g.terraform_fmt_on_save then
        vim.cmd("TerraformFmt")
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
  local full_cmd = string.format('cd %s && terraform %s', current_dir, cmd)
  
  -- Open terminal and run command
  vim.cmd('botright split')
  vim.cmd('resize 15')
  vim.cmd('terminal ' .. full_cmd)
  vim.cmd('startinsert')
end

-- Format current Terraform file
function M.format_terraform()
  local file = vim.fn.expand('%')
  if vim.fn.executable('terraform') == 1 then
    local result = vim.fn.system('terraform fmt -write=false ' .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      -- Apply the formatting result
      local lines = vim.split(result, '\n')
      if #lines > 1 then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.notify("Terraform file formatted", vim.log.levels.INFO)
      end
    else
      vim.notify("Terraform format failed: " .. result, vim.log.levels.ERROR)
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
function M.toggle_terraform_lsp()
  local clients = vim.lsp.get_active_clients({ name = "terraformls" })
  if #clients > 0 then
    vim.lsp.stop_client(clients)
    vim.notify("Terraform LSP stopped", vim.log.levels.INFO)
  else
    -- Try to start terraform-ls if available
    if vim.fn.executable('terraform-ls') == 1 then
      vim.cmd('LspStart terraformls')
      vim.notify("Terraform LSP started", vim.log.levels.INFO)
    else
      vim.notify("terraform-ls not found. Install it with: go install github.com/hashicorp/terraform-ls@latest", vim.log.levels.WARN)
    end
  end
end

return M
