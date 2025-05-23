-- Go development configuration
-- Simple implementation without LSP
local M = {}

-- Helper function to jump between Go files (test/implementation)
local function open_alternate(command)
  local file = vim.fn.expand("%")
  if file == "" then
    vim.notify("No file in the current buffer", vim.log.levels.ERROR)
    return
  end
  
  -- Determine if this is a test file
  local is_test = vim.fn.match(file, "_test\\.go$") ~= -1
  local alternate
  
  if is_test then
    -- If it's a test file, get the implementation file
    alternate = file:gsub("_test%.go$", ".go")
  else
    -- If it's an implementation file, get the test file
    alternate = file:gsub("%.go$", "_test.go")
  end
  
  -- Check if the alternate file exists
  if vim.fn.filereadable(alternate) == 0 then
    vim.notify("Alternate file doesn't exist: " .. alternate, vim.log.levels.WARN)
  end
  
  -- Open the alternate file with the specified command
  vim.cmd(command .. " " .. alternate)
end

-- Functions to open alternate file in different ways
function M.go_alternate_edit()
  open_alternate("e")
end

function M.go_alternate_split()
  open_alternate("sp")
end

function M.go_alternate_vertical()
  open_alternate("vsp")
end

function M.go_alternate_tab()
  open_alternate("tabe")
end

-- Build Go files (implementation of the reference in init.lua)
function M.build_go_files()
  local file = vim.fn.expand('%')
  if file:match('_test%.go$') then
    vim.cmd('GoTest')
  elseif file:match('%.go$') then
    vim.cmd('GoBuild')
  end
end

-- Module setup function
function M.setup()
  vim.notify("Using vim-go for Go development (LSP disabled)", vim.log.levels.INFO)
end

return M 