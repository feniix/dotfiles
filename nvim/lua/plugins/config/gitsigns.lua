-- Gitsigns configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local gitsigns = safe_require('gitsigns')
  
  if not gitsigns then
    return
  end

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

return M
