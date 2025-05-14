-- Common utilities for tool installation across language modules
local M = {}

-- Configuration
local config = {
  auto_install_tools = true -- Global setting to enable/disable automatic tool installation
}

-- Function to check if a tool is installed and install it if needed
function M.ensure_tool(tool, install_cmd, auto_install)
  -- Honor the specific auto_install setting or fall back to global config
  local should_install = auto_install
  if should_install == nil then
    should_install = config.auto_install_tools
  end
  
  if not should_install then
    return false
  end

  -- Check if tool is already installed
  if vim.fn.executable(tool) == 1 then
    -- Tool is already installed and available
    return true
  end
  
  vim.notify(tool .. " not found, installing...", vim.log.levels.INFO)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system(install_cmd)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install " .. tool .. ": " .. install_result, vim.log.levels.ERROR)
    return false
  else
    vim.notify(tool .. " installed successfully", vim.log.levels.INFO)
    return true
  end
end

-- Helper function to get the appropriate install command for the current OS
function M.get_install_cmd(tool, mac_cmd, linux_cmd)
  if vim.fn.has("mac") == 1 then
    return mac_cmd
  elseif vim.fn.has("unix") == 1 then
    return linux_cmd
  else
    vim.notify("Unsupported OS for automatic installation of " .. tool, vim.log.levels.WARN)
    return nil
  end
end

-- Helper for installing Go tools with the right command
function M.ensure_go_tool(tool, package, version, auto_install)
  version = version or "latest"
  
  -- Check if tool is already installed
  if vim.fn.executable(tool) == 1 then
    return true
  end
  
  -- Get proper go install command
  local install_cmd = "go install " .. package .. "@" .. version
  
  return M.ensure_tool(tool, install_cmd, auto_install)
end

-- Configure global settings
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end
end

-- Set up format-on-save for a buffer
function M.setup_format_on_save(bufnr, filetypes, group_name)
  -- Default to the current buffer if not specified
  bufnr = bufnr or 0
  
  -- Default group name to use
  group_name = group_name or "FormatOnSave"
  
  -- Create a unique augroup name if filetypes are specified
  if filetypes then
    if type(filetypes) == "string" then
      group_name = filetypes .. "Format"
    elseif type(filetypes) == "table" and #filetypes > 0 then
      group_name = filetypes[1] .. "Format"
    end
  end
  
  -- Create a format function that uses LSP formatter
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup(group_name, { clear = true }),
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ async = false })
    end,
  })
end

return M 