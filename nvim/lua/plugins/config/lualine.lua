-- Lualine statusline configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local lualine = safe_require('lualine')
  
  if not lualine then
    return
  end

  lualine.setup({
    options = {
      theme = 'auto', -- Set to 'auto' to match current colorscheme
      icons_enabled = true,
      component_separators = { left = '', right = ''},
      section_separators = { left = '', right = ''},
    },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff'},
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
end

return M