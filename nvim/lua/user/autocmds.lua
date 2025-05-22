local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd

  -- Return to last edit position when opening files (except git commit messages)
  local last_edit = augroup("LastEdit", { clear = true })
  autocmd("BufReadPost", {
    group = last_edit,
    callback = function()
      local line = vim.fn.line("'\"")
      if line > 0 and line <= vim.fn.line("$") and not vim.bo.filetype:match("git.*commit") then
        vim.cmd("normal! g`\"")
      end
    end,
  })

  -- JSON settings
  local json_settings = augroup("JSONSettings", { clear = true })
  autocmd("FileType", {
    group = json_settings,
    pattern = "json",
    command = "setlocal shiftwidth=2 tabstop=2",
  })

  -- Set Packerfile as JSON
  local packerfile = augroup("Packerfile", { clear = true })
  autocmd({"BufNewFile", "BufRead"}, {
    group = packerfile,
    pattern = "Packerfile",
    command = "set filetype=json",
  })

  -- TOML filetype detection
  local toml_ft = augroup("TOMLFiletype", { clear = true })
  autocmd({"BufNewFile", "BufRead"}, {
    group = toml_ft,
    pattern = "*.toml",
    command = "set filetype=toml",
  })

  -- Dockerfile filetype detection
  local dockerfile_ft = augroup("DockerfileFiletype", { clear = true })
  autocmd({"BufNewFile", "BufRead"}, {
    group = dockerfile_ft,
    pattern = {"Dockerfile", "*.dockerfile", "*.Dockerfile"},
    command = "set filetype=dockerfile",
  })

  -- Jsonnet filetype detection
  local jsonnet_ft = augroup("JsonnetFiletype", { clear = true })
  autocmd({"BufNewFile", "BufRead"}, {
    group = jsonnet_ft,
    pattern = {"*.jsonnet", "*.libsonnet"},
    command = "set filetype=jsonnet",
  })

  -- Go settings
  local go_settings = augroup("GoSettings", { clear = true })
  autocmd("FileType", {
    group = go_settings,
    pattern = "go",
    callback = function()
      -- Show by default 4 spaces for a tab
      vim.bo.expandtab = false
      vim.bo.tabstop = 4
      vim.bo.shiftwidth = 4
      
      -- Load Go-specific keymaps
      local keymaps = require("user.keymaps")
      keymaps.setup_go_keymaps()
      
      -- Setup Go commands
      vim.api.nvim_buf_create_user_command(0, "A", "lua require('user.go').go_alternate_edit()", {})
      vim.api.nvim_buf_create_user_command(0, "AV", "lua require('user.go').go_alternate_vertical()", {})
      vim.api.nvim_buf_create_user_command(0, "AS", "lua require('user.go').go_alternate_split()", {})
      vim.api.nvim_buf_create_user_command(0, "AT", "lua require('user.go').go_alternate_tab()", {})
    end,
  })

  -- Terraform settings
  local terraform_settings = augroup("TerraformSettings", { clear = true })
  autocmd("FileType", {
    group = terraform_settings,
    pattern = "terraform",
    command = "setlocal commentstring=#%s",
  })
  
  autocmd({"BufNewFile", "BufRead"}, {
    group = terraform_settings,
    pattern = "*.hcl",
    command = "set filetype=terraform",
  })
end

return M 