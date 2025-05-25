-- Core Neovim autocommands
-- Migrated from user/autocmds.lua for better organization

local M = {}

function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd
  
  -- Get platform utilities
  local utils = require('core.utils')
  local capabilities = utils.platform.get_capabilities()

  -- Create autogroup
  local setup_group = augroup("dotfileSetup", { clear = true })

  -- Highlight yanked text
  autocmd("TextYankPost", {
    group = setup_group,
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
    end,
  })

  -- Go filetype customizations
  autocmd("FileType", {
    group = setup_group,
    pattern = "go",
    callback = function()
      -- Go keymaps are set up in the GoSettings autocmd below
    end,
  })
  
  -- Focus events (capability-aware)
  if capabilities.focus_events then
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
  
  -- Enhanced clipboard handling (platform-aware)
  if capabilities.clipboard and (utils.platform.is_iterm2() or capabilities.focus_events) then
    autocmd("TextYankPost", {
      group = augroup("TerminalClipboard", { clear = true }),
      callback = function()
        -- Platform-specific clipboard delay
        local delay = utils.platform.is_mac() and 10 or 20
        vim.defer_fn(function()
          -- Trigger clipboard sync
        end, delay)
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

  -- Go settings (platform-aware)
  local go_settings = augroup("GoSettings", { clear = true })
  autocmd("FileType", {
    group = go_settings,
    pattern = "go",
    callback = function()
      -- Platform-specific Go settings
      vim.bo.expandtab = false
      vim.bo.tabstop = 4
      vim.bo.shiftwidth = 4
      
      -- Platform-specific formatting on save
      if utils.platform.command_available("gofumpt") then
        vim.bo.formatprg = "gofumpt"
      elseif utils.platform.command_available("gofmt") then
        vim.bo.formatprg = "gofmt"
      end
      
      -- Load Go-specific keymaps
      local keymaps = utils.safe_require("core.keymaps")
      if keymaps and keymaps.setup_go_keymaps then
        keymaps.setup_go_keymaps()
      end
      
      -- Setup which-key for Go-specific commands
      local which_key_setup = utils.safe_require("plugins.config.which-key")
      if which_key_setup and which_key_setup.setup_go_mappings then
        which_key_setup.setup_go_mappings()
      end
      
      -- Go-specific commands (only if Go tools available)
      if utils.platform.command_available("go") then
        vim.api.nvim_buf_create_user_command(0, "GoAlternate", "lua require('plugins.config.lang.go').go_alternate_edit()", { desc = "Go to alternate Go file" })
        vim.api.nvim_buf_create_user_command(0, "GoAlternateV", "lua require('plugins.config.lang.go').go_alternate_vertical()", { desc = "Go to alternate Go file in vertical split" })
        vim.api.nvim_buf_create_user_command(0, "GoAlternateS", "lua require('plugins.config.lang.go').go_alternate_split()", { desc = "Go to alternate Go file in split" })
        vim.api.nvim_buf_create_user_command(0, "GoAlternateT", "lua require('plugins.config.lang.go').go_alternate_tab()", { desc = "Go to alternate Go file in new tab" })
      end
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
  
  -- NvimTree directory handling (platform-aware)
  local nvim_tree_group = augroup("NvimTreeDirectoryHandling", { clear = true })
  autocmd("VimEnter", {
    group = nvim_tree_group,
    callback = function()
      -- Check if nvim was opened with a directory argument
      local args = vim.fn.argv()
      if #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
        -- Platform-specific delay (faster on macOS)
        local delay = utils.platform.is_mac() and 50 or 100
        vim.defer_fn(function()
          -- Check if nvim-tree is available
          local ok, nvim_tree = pcall(require, "nvim-tree.api")
          if ok then
            -- Change to the directory and open nvim-tree
            vim.cmd("cd " .. vim.fn.fnameescape(args[1]))
            nvim_tree.tree.open()
          else
            -- Fallback to netrw if nvim-tree not available
            vim.cmd("edit " .. vim.fn.fnameescape(args[1]))
          end
        end, delay)
      end
    end,
  })

  -- Luacheck integration
  local luacheck_group = augroup("LuacheckLinting", { clear = true })
  if utils.platform.command_available('luacheck') then
    autocmd("BufWritePost", {
      group = luacheck_group,
      pattern = "*.lua",
      callback = function()
        local file = vim.fn.expand('%')
        if file:match('^lua/') then
          vim.cmd('silent !luacheck ' .. file)
        end
      end,
    })
  end

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