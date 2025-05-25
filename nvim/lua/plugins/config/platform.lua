-- Platform-specific plugin configurations
-- Provides platform-aware settings for plugins

local utils = require('core.utils')
local M = {}

-- Get platform-specific telescope configuration
function M.get_telescope_config()
  local config = {
    defaults = {
      file_ignore_patterns = { "%.git/", "node_modules/", "%.cache/" },
      layout_strategy = "horizontal",
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
          results_width = 0.8,
        },
        vertical = {
          mirror = false,
        },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120,
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  }
  
  -- Platform-specific optimizations
  if utils.platform.is_mac() then
    -- macOS optimizations
    config.defaults.vimgrep_arguments = {
      "rg", "--color=never", "--no-heading", "--with-filename",
      "--line-number", "--column", "--smart-case", "--hidden"
    }
  else
    -- Linux optimizations
    config.defaults.vimgrep_arguments = {
      "rg", "--color=never", "--no-heading", "--with-filename",
      "--line-number", "--column", "--smart-case"
    }
  end
  
  return config
end

-- Get platform-specific LSP configuration
function M.get_lsp_config()
  local config = {}
  
  -- Platform-specific LSP server paths
  if utils.platform.is_mac() then
    config.server_paths = {
      lua_ls = "/opt/homebrew/bin/lua-language-server",
      gopls = vim.fn.expand("~/go/bin/gopls"),
    }
  else
    config.server_paths = {
      lua_ls = "/usr/bin/lua-language-server",
      gopls = vim.fn.expand("~/go/bin/gopls"),
    }
  end
  
  return config
end

-- Get platform-specific terminal configuration
function M.get_terminal_config()
  local config = {
    shell = vim.o.shell,
    direction = "horizontal",
    size = 20,
  }
  
  -- Platform-specific shell and terminal settings
  if utils.platform.is_mac() then
    config.shell = "/bin/zsh"
    if utils.platform.is_iterm2() then
      config.float_opts = {
        border = "curved",
        width = 120,
        height = 30,
      }
    end
  else
    config.shell = "/bin/bash"
    config.float_opts = {
      border = "single",
      width = 100,
      height = 25,
    }
  end
  
  return config
end

-- Get platform-specific completion configuration
function M.get_completion_config()
  local config = {
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    mapping = {
      ['<C-b>'] = require('cmp').mapping.scroll_docs(-4),
      ['<C-f>'] = require('cmp').mapping.scroll_docs(4),
      ['<C-Space>'] = require('cmp').mapping.complete(),
      ['<C-e>'] = require('cmp').mapping.abort(),
      ['<CR>'] = require('cmp').mapping.confirm({ select = true }),
    },
  }
  
  -- Platform-specific key mappings
  if utils.platform.is_mac() then
    -- Use Cmd key on macOS
    config.mapping['<D-Space>'] = require('cmp').mapping.complete()
  end
  
  return config
end

-- Get platform-specific file tree configuration
function M.get_filetree_config()
  local config = {
    disable_netrw = true,
    hijack_netrw = true,
    open_on_tab = false,
    hijack_cursor = false,
    update_cwd = true,
    hijack_directories = {
      enable = true,
      auto_open = true,
    },
    diagnostics = {
      enable = true,
      icons = {
        hint = "",
        info = "",
        warning = "",
        error = "",
      }
    },
    update_focused_file = {
      enable = true,
      update_cwd = true,
      ignore_list = {}
    },
    view = {
      width = 30,
      side = 'left',
    },
  }
  
  -- Platform-specific optimizations
  if utils.platform.is_mac() then
    config.system_open = {
      cmd = "open",
    }
  else
    config.system_open = {
      cmd = "xdg-open",
    }
  end
  
  return config
end

-- Get platform-specific clipboard configuration
function M.get_clipboard_config()
  local config = {}
  
  if utils.platform.is_mac() then
    config.providers = {
      require('vim.ui.clipboard.osc52'),
      'pbcopy',
      'pbpaste',
    }
  else
    config.providers = {
      require('vim.ui.clipboard.osc52'),
      'wl-clipboard',
      'xclip',
      'xsel',
    }
  end
  
  return config
end

return M 