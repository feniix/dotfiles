-- Format in-memory content, never the stale copy on disk.
local M = {}

function M.buffer(command, label)
  local view = vim.fn.winsaveview()
  local input = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '\n'
  local output = vim.fn.system(command, input)
  if vim.v.shell_error ~= 0 then
    vim.notify(label .. ' failed: ' .. output, vim.log.levels.ERROR)
    return false
  end

  local lines = vim.split(output, '\n')
  if lines[#lines] == '' then
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.fn.winrestview(view)
  return true
end

return M
