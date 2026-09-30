-- Format in-memory content, never the stale copy on disk.
local M = {}

function M.buffer(command, label, options)
  local view = vim.fn.winsaveview()
  local input = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '\n'
  local ok, result = pcall(function()
    return vim.system(command, vim.tbl_extend('force', options or {}, {
      stdin = input, text = true,
    })):wait()
  end)
  if not ok then
    vim.notify(label .. ' failed: ' .. tostring(result), vim.log.levels.ERROR)
    return false
  end
  if result.code ~= 0 then
    vim.notify(label .. ' failed: ' .. (result.stderr or result.stdout or ''), vim.log.levels.ERROR)
    return false
  end
  local output = result.stdout or ''
  if output == '' and input:find('%S') then
    vim.notify(label .. ' returned no formatted content', vim.log.levels.ERROR)
    return false
  end

  local lines = vim.split(output, '\n')
  if lines[#lines] == '' then
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.fn.winrestview(view)
  if result.stderr and result.stderr ~= '' then
    vim.notify(label .. ': ' .. result.stderr, vim.log.levels.INFO)
  end
  return true
end

return M
