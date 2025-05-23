-- Telescope configuration
-- Migrated and simplified from user/telescope.lua

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local telescope = safe_require('telescope')
  
  if not telescope then
    return
  end

  telescope.setup({
    defaults = {
      prompt_prefix = "🔍 ",
      selection_caret = "➤ ",
      mappings = {
        i = {
          ["<C-n>"] = "move_selection_next",
          ["<C-p>"] = "move_selection_previous",
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
        n = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
      },
    },
    pickers = {
      find_files = {
        theme = "dropdown",
        previewer = false,
        hidden = true,
      },
      live_grep = {
        theme = "ivy",
      },
      buffers = {
        theme = "dropdown",
        previewer = false,
      },
    },
  })

  -- Load fzf extension if available
  pcall(telescope.load_extension, 'fzf')
end

return M 