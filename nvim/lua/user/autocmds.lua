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
      -- Go keymaps are set up in the GoSettings autocmd below
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
  
  -- Terminal-specific integrations
  local platform = _G.platform or safe_require('user.platform')
  if platform then
    local terminal_config = platform.get_terminal_config()
    
    -- Enable focus events for terminals that support them
    if terminal_config.support_focus_events then
      autocmd({"FocusGained", "FocusLost"}, {
        group = augroup("TerminalFocus", { clear = true }),
        callback = function(ev)
          if ev.event == "FocusGained" then
            -- Refresh file when Neovim gets focus
            vim.cmd("checktime")
          end
        end,
      })
    end
    
    -- Enhanced clipboard handling for supported terminals
    if platform.get_terminal() == "iterm2" or terminal_config.support_focus_events then
      autocmd("TextYankPost", {
        group = augroup("TerminalClipboard", { clear = true }),
        callback = function()
          -- Delay the clipboard update slightly to ensure it's ready for paste
          vim.defer_fn(function()
            -- This is empty on purpose, just triggering the event loop
          end, 10)
        end,
      })
    end
  else
    -- Fallback for iTerm2 if platform detection fails
    if _G.is_iterm2 and _G.is_iterm2() then
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
      local keymaps = safe_require("user.keymaps")
      if keymaps then
        keymaps.setup_go_keymaps()
      end
      
      -- Setup Go commands (renamed to avoid conflicts with standard :A command)
      vim.api.nvim_buf_create_user_command(0, "GoAlternate", "lua require('user.go').go_alternate_edit()", { desc = "Go to alternate Go file" })
      vim.api.nvim_buf_create_user_command(0, "GoAlternateV", "lua require('user.go').go_alternate_vertical()", { desc = "Go to alternate Go file in vertical split" })
      vim.api.nvim_buf_create_user_command(0, "GoAlternateS", "lua require('user.go').go_alternate_split()", { desc = "Go to alternate Go file in split" })
      vim.api.nvim_buf_create_user_command(0, "GoAlternateT", "lua require('user.go').go_alternate_tab()", { desc = "Go to alternate Go file in new tab" })
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