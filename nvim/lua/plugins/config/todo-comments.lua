-- todo-comments configuration

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local todo_comments = safe_require('todo-comments')
  
  if not todo_comments then
    return
  end

  todo_comments.setup({
    signs = true,
    keywords = {
      FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      NOTE = { icon = " ", color = "hint", alt = { "INFO" } }
    }
  })
end

return M
