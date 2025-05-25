-- Ecosystem tool installer for Neovim configuration
-- Installs language-specific tools and system utilities

local utils = require('core.utils')
local M = {}

-- Language ecosystem tools (not core runtimes - those are asdf-managed)
M.tools = {
  go_tools = {
    goimports = { cmd = 'go install golang.org/x/tools/cmd/goimports@latest' },
    gofumpt = { cmd = 'go install mvdan.cc/gofumpt@latest' },
    golangci_lint = { cmd = 'go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest' },
    gomodifytags = { cmd = 'go install github.com/fatih/gomodifytags@latest' },
    gotests = { cmd = 'go install github.com/cweill/gotests/gotests@latest' },
    dlv = { cmd = 'go install github.com/go-delve/delve/cmd/dlv@latest' },
    impl = { cmd = 'go install github.com/josharian/impl@latest' },
    gorename = { cmd = 'go install golang.org/x/tools/cmd/gorename@latest' }
  },
  rust_tools = {
    -- Most Rust tools managed by asdf/rustup, minimal additional tools needed
  },
  node_tools = {
    typescript_language_server = { cmd = 'npm install -g typescript-language-server typescript' },
    prettier = { cmd = 'npm install -g prettier' },
    eslint = { cmd = 'npm install -g eslint' }
  },
  python_tools = {
    black = { cmd = 'pip install black' },
    ruff = { cmd = 'pip install ruff' },
    pyright = { cmd = 'pip install pyright' }
  },
  system_tools = {
    ripgrep = { homebrew = 'ripgrep', apt = 'ripgrep', dnf = 'ripgrep', pacman = 'ripgrep' },
    fd = { homebrew = 'fd', apt = 'fd-find', dnf = 'fd-find', pacman = 'fd' },
    fzf = { homebrew = 'fzf', apt = 'fzf', dnf = 'fzf', pacman = 'fzf' }
  }
}

-- Execute command and return success status
function M.execute_command(cmd)
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0, result
end

-- Install a single tool
function M.install_tool(tool_name, spec)
  if spec.cmd then
    vim.notify('Installing ' .. tool_name .. '...', vim.log.levels.INFO)
    local success, output = M.execute_command(spec.cmd)
    if success then
      vim.notify(tool_name .. ' installed successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to install ' .. tool_name .. ': ' .. output, vim.log.levels.ERROR)
    end
    return success
  end
  return false
end

-- Install via package manager
function M.install_via_package_manager(pm, package_spec)
  local cmd_map = {
    homebrew = 'brew install ' .. package_spec,
    apt = 'sudo apt install -y ' .. package_spec,
    dnf = 'sudo dnf install -y ' .. package_spec,
    pacman = 'sudo pacman -S --noconfirm ' .. package_spec,
    zypper = 'sudo zypper install -y ' .. package_spec
  }
  
  local cmd = cmd_map[pm]
  if cmd then
    vim.notify('Installing ' .. package_spec .. ' via ' .. pm .. '...', vim.log.levels.INFO)
    local success, output = M.execute_command(cmd)
    if success then
      vim.notify(package_spec .. ' installed successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to install ' .. package_spec .. ': ' .. output, vim.log.levels.ERROR)
    end
    return success
  end
  return false
end

-- Install language-specific tools
function M.install_language_tools(lang)
  local tools = M.tools[lang .. '_tools']
  if not tools then
    vim.notify('No tools defined for ' .. lang, vim.log.levels.WARN)
    return false
  end
  
  -- Check if language runtime is available (asdf-managed)
  if not utils.platform.command_available(lang) then
    vim.notify(lang .. ' runtime not found. Install via asdf first.', vim.log.levels.ERROR)
    return false
  end
  
  local success_count = 0
  local total_count = 0
  
  for tool_name, spec in pairs(tools) do
    total_count = total_count + 1
    if M.install_tool(tool_name, spec) then
      success_count = success_count + 1
    end
  end
  
  vim.notify(string.format('Installed %d/%d %s tools', success_count, total_count, lang), vim.log.levels.INFO)
  return success_count == total_count
end

-- Install system tools
function M.install_system_tools()
  local pm = utils.platform.get_package_manager()
  if pm == 'none' then
    vim.notify('No package manager detected', vim.log.levels.ERROR)
    return false
  end
  
  local success_count = 0
  local total_count = 0
  
  for tool_name, spec in pairs(M.tools.system_tools) do
    total_count = total_count + 1
    if spec[pm] then
      if M.install_via_package_manager(pm, spec[pm]) then
        success_count = success_count + 1
      end
    else
      vim.notify(tool_name .. ' not available for ' .. pm, vim.log.levels.WARN)
    end
  end
  
  vim.notify(string.format('Installed %d/%d system tools', success_count, total_count), vim.log.levels.INFO)
  return success_count == total_count
end

-- Install all tools for a language
function M.install_all_for_language(lang)
  return M.install_language_tools(lang)
end

-- Get available tools for a language
function M.get_available_tools(lang)
  local tools = M.tools[lang .. '_tools']
  if not tools then
    return {}
  end
  
  local available = {}
  for tool_name, _ in pairs(tools) do
    table.insert(available, tool_name)
  end
  return available
end

-- Check if tool is installed
function M.is_tool_installed(tool_name)
  -- Handle tools with different binary names
  local binary_name = tool_name
  if tool_name == "golangci_lint" then
    binary_name = "golangci-lint"
  elseif tool_name == "typescript_language_server" then
    binary_name = "typescript-language-server"
  end
  
  return utils.platform.command_available(binary_name)
end

-- Create user commands for easy installation
function M.setup_commands()
  -- Install Go tools
  vim.api.nvim_create_user_command('InstallGoTools', function()
    M.install_language_tools('go')
  end, { desc = 'Install Go development tools' })
  
  -- Install Node tools
  vim.api.nvim_create_user_command('InstallNodeTools', function()
    M.install_language_tools('node')
  end, { desc = 'Install Node.js development tools' })
  
  -- Install Python tools
  vim.api.nvim_create_user_command('InstallPythonTools', function()
    M.install_language_tools('python')
  end, { desc = 'Install Python development tools' })
  
  -- Install system tools
  vim.api.nvim_create_user_command('InstallSystemTools', function()
    M.install_system_tools()
  end, { desc = 'Install system utilities (ripgrep, fd, fzf)' })
  
  -- Install all tools
  vim.api.nvim_create_user_command('InstallAllTools', function()
    M.install_system_tools()
    M.install_language_tools('go')
    M.install_language_tools('node')
    M.install_language_tools('python')
  end, { desc = 'Install all development tools' })
end

return M