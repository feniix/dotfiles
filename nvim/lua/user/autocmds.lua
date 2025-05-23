local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd

  -- Create autogroup
  local setup_group = augroup("dotfileSetup", { clear = true })

  -- Highlight yanked text
  autocmd("TextYankPost", {
    group = setup_group,
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
    end,
  })

  -- Auto compile plugins.lua after changes
  autocmd("BufWritePost", {
    group = setup_group,
    pattern = "plugins.lua",
    command = "source <afile> | PackerCompile",
  })

  -- Trim trailing whitespace on save
  -- (Now handled by retrail.nvim)

  -- Go filetype customizations
  autocmd("FileType", {
    group = setup_group,
    pattern = "go",
    callback = function()
      -- Load Go keymaps
      local km_ok, keymaps = pcall(require, "user.keymaps")
      if km_ok then
        keymaps.setup_go_keymaps()
      end
    end,
  })
  
  -- Terraform file formatting
  autocmd("BufWritePre", {
    group = setup_group,
    pattern = { "*.tf", "*.tfvars" },
    callback = function()
      -- Using vim-terraform's formatting instead of LSP
      vim.cmd("TerraformFmt")
    end,
  })
  
  -- iTerm2 specific integrations
  if vim.env.TERM_PROGRAM == "iTerm.app" or string.match(vim.env.TERM or "", "^iterm") or vim.env.LC_TERMINAL == "iTerm2" then
    -- Enable focus events
    autocmd({"FocusGained", "FocusLost"}, {
      group = augroup("iTerm2Focus", { clear = true }),
      callback = function(ev)
        if ev.event == "FocusGained" then
          -- Refresh file when Neovim gets focus
          vim.cmd("checktime")
        end
      end,
    })
    
    -- Fix mouse paste in iTerm2
    autocmd("TextYankPost", {
      group = augroup("iTerm2MousePaste", { clear = true }),
      callback = function()
        -- Delay the clipboard update slightly to ensure it's ready for paste
        vim.defer_fn(function()
          -- This is empty on purpose, just triggering the event loop
        end, 10)
      end,
    })
  end

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
  
  -- Git commit message settings
  local git_commit = augroup("GitCommitSettings", { clear = true })
  
  -- Position cursor at the beginning of git commit messages
  autocmd("FileType", {
    group = git_commit,
    pattern = { "gitcommit", "gitrebase" },
    callback = function()
      -- Go to beginning of file and enter insert mode
      vim.cmd("normal! gg")
      
      -- If it's a standard git commit (not interactive rebase, etc.)
      if vim.bo.filetype == "gitcommit" then
        -- For git commit, insert mode is often desirable
        vim.cmd("startinsert")
      end
    end,
  })
  
  -- Make sure to enforce cursor position even if the file has viminfo data
  autocmd("BufReadPost", {
    group = git_commit,
    pattern = { "COMMIT_EDITMSG", "MERGE_MSG", "git-rebase-todo" },
    callback = function()
      vim.cmd("normal! gg")
    end,
  })
  
  -- Disable the "jump to last position" behavior for git files
  autocmd("BufReadPost", {
    group = git_commit,
    pattern = { "COMMIT_EDITMSG", "MERGE_MSG", "git-rebase-todo" },
    callback = function()
      -- Disable the last position marker
      vim.opt_local.viminfo:append("!")
    end,
  })
end

return M 