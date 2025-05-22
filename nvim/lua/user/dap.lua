local M = {}

-- Default configurations for DAP
local default_config = {
  -- Common settings
}

M.setup = function(opts)
  -- Merge user options with defaults
  local config = default_config
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Initialize DAP
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    vim.notify("nvim-dap not found. Debugging features will be disabled.", vim.log.levels.WARN)
    return
  end

  -- Set up keymappings
  local keymap_opts = { noremap = true, silent = true }
  vim.keymap.set('n', '<F5>', function() dap.continue() end, keymap_opts)
  vim.keymap.set('n', '<F10>', function() dap.step_over() end, keymap_opts)
  vim.keymap.set('n', '<F11>', function() dap.step_into() end, keymap_opts)
  vim.keymap.set('n', '<F12>', function() dap.step_out() end, keymap_opts)
  vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, keymap_opts)
  vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, keymap_opts)
  vim.keymap.set('n', '<leader>dl', function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, keymap_opts)
  vim.keymap.set('n', '<leader>dr', function() dap.repl.open() end, keymap_opts)

  -- Configure language-specific adapters
  -- Go
  dap.adapters.go = {
    type = 'server',
    port = '${port}',
    executable = {
      command = 'dlv',
      args = {'dap', '-l', '127.0.0.1:${port}'},
    }
  }

  dap.configurations.go = {
    {
      type = 'go',
      name = 'Debug',
      request = 'launch',
      program = '${file}'
    },
    {
      type = 'go',
      name = 'Debug test',
      request = 'launch',
      mode = 'test',
      program = '${file}'
    },
    {
      type = 'go',
      name = 'Debug test (go.mod)',
      request = 'launch',
      mode = 'test',
      program = './${relativeFileDirname}'
    }
  }

  -- Add configuration UI hints
  vim.api.nvim_create_user_command('DapToggleBreakpoint', function() 
    dap.toggle_breakpoint()
  end, { desc = 'Toggle breakpoint at current line' })

  vim.api.nvim_create_user_command('DapContinue', function()
    dap.continue()
  end, { desc = 'Start/continue debugging' })

  -- Setup DAP UI 
  local dapui_ok, dapui = pcall(require, "dapui")
  if dapui_ok then
    -- Configure dapui
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
      mappings = {
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25,
          position = "bottom",
        },
      },
      floating = {
        max_height = nil,
        max_width = nil,
        border = "single",
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 }
    })

    -- Add UI toggle command
    vim.api.nvim_create_user_command('DapUIToggle', function()
      dapui.toggle()
    end, { desc = 'Toggle debug UI' })

    -- Set up automatic UI open/close with debugging sessions
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  else
    vim.notify("nvim-dap-ui not found. UI features will be disabled.", vim.log.levels.WARN)
  end
  
  -- Setup DAP Virtual Text if available
  local virtual_text_ok, virtual_text = pcall(require, "nvim-dap-virtual-text")
  if virtual_text_ok then
    virtual_text.setup({
      enabled = true,                     -- Enable virtual text
      enabled_commands = true,            -- Create commands DapVirtualTextEnable, DapVirtualTextDisable, etc.
      highlight_changed_variables = true, -- Highlight changed values with NvimDapVirtualTextChanged
      highlight_new_as_changed = false,   -- Highlight new variables same as changed variables
      show_stop_reason = true,            -- Show stop reason when stopped
      commented = false,                  -- Prefix virtual text with comment string
      only_first_definition = true,       -- Only show virtual text for first definition
      all_frames = false,                 -- Show virtual text for all frames not just current
      virt_text_pos = 'eol',              -- Position of virtual text
      -- Experimental features
      all_references = false,             -- Show virtual text on all references of the variable
      clear_on_continue = false,          -- Clear virtual text on "continue"
    })
  else
    vim.notify("nvim-dap-virtual-text not found. Virtual text features will be disabled.", vim.log.levels.WARN)
  end
end

return M 