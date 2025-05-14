-- UI Configuration
local M = {}

M.setup = function()
  -- Setup solarized colorscheme if available
  local solarized_ok, solarized = pcall(require, 'solarized')
  if solarized_ok then
    pcall(function()
      solarized.setup({
        theme = 'neo', -- or 'default'
        transparent = false,
        colors = {},  -- Override specific color values
        highlights = {}, -- Override specific highlight groups
        enable_italics = true,
      })
    end)
  else
    vim.notify("Solarized colorscheme not found. Using default.", vim.log.levels.INFO)
  end

  -- Setup lualine (replacement for vim-airline)
  local lualine_ok, lualine = pcall(require, 'lualine')
  if lualine_ok then
    lualine.setup({
      options = {
        theme = 'solarized',
        icons_enabled = true,
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      tabline = {
        lualine_a = {'buffers'},
        lualine_z = {'tabs'}
      },
      extensions = {'fugitive'}
    })
  else
    vim.notify("Lualine not found. Status line may be limited.", vim.log.levels.WARN)
  end

  -- Setup rainbow-delimiters (replacement for rainbow)
  local rainbow_delimiters_ok, rainbow_delimiters = pcall(require, 'rainbow-delimiters')
  if rainbow_delimiters_ok then
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = rainbow_delimiters.strategy['global'],
      },
      query = {
        [''] = 'rainbow-delimiters',
      },
    }
  end

  -- Setup gitsigns (replacement for vim-gitgutter)
  local gitsigns_ok, gitsigns = pcall(require, 'gitsigns')
  if gitsigns_ok then 
    gitsigns.setup({
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
      },
    })
  end

  -- Setup retrail (replacement for vim-better-whitespace)
  local retrail_ok, retrail = pcall(require, 'retrail')
  if retrail_ok then 
    retrail.setup({
      trim = {
        auto = true,
        whitespace = true,
        blanklines = false,
      }
    })
  end
  
  -- Setup todo-comments
  local todo_comments_ok, todo_comments = pcall(require, "todo-comments")
  if todo_comments_ok then
    todo_comments.setup {
      signs = true,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } }
      }
    }
  end
end

return M 