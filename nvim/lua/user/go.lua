-- Go configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true -- Set to false to disable automatic installation
}

-- Function to get the Go binary directory
local function get_go_bin_path()
  local gopath = vim.fn.trim(vim.fn.system("go env GOPATH"))
  if gopath == "" then
    -- If GOPATH is not set, use default
    gopath = vim.fn.expand("$HOME/go")
  end
  return gopath .. "/bin"
end

-- Cache the bin path
local go_bin_path = get_go_bin_path()

-- Function to check if a tool is installed and install it if needed
local function ensure_go_tool(tool, package, version)
  if not config.auto_install_tools then
    return
  end

  -- Check if tool exists in go bin path
  local tool_path = go_bin_path .. "/" .. tool
  if vim.fn.filereadable(tool_path) == 1 then
    -- Tool is already installed
    return
  end
  
  -- Also check if it's in PATH
  if vim.fn.executable(tool) == 1 then
    -- Tool is available in PATH
    return
  end
  
  local install_path = package
  if version then
    install_path = install_path .. "@" .. version
  end
  
  vim.notify(tool .. " not found, installing...", vim.log.levels.INFO)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system("go install " .. install_path)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install " .. tool .. ": " .. install_result, vim.log.levels.ERROR)
  else
    vim.notify(tool .. " installed successfully", vim.log.levels.INFO)
  end
end

-- Function to install all required Go tools
local function ensure_go_tools()
  -- Essential tools
  ensure_go_tool("gopls", "golang.org/x/tools/gopls", "latest")
  ensure_go_tool("goimports", "golang.org/x/tools/cmd/goimports", "latest")
  ensure_go_tool("golangci-lint", "github.com/golangci/golangci-lint/cmd/golangci-lint", "latest")
  ensure_go_tool("gomodifytags", "github.com/fatih/gomodifytags", "latest")
  ensure_go_tool("gotests", "github.com/cweill/gotests/...", "latest")
  ensure_go_tool("impl", "github.com/josharian/impl", "latest")
  ensure_go_tool("gofumpt", "mvdan.cc/gofumpt", "latest")
end

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Ensure Go tools are installed
  ensure_go_tools()
  
  -- Set up go.nvim
  local go_ok, go = pcall(require, "go")
  if go_ok then
    go.setup({
      -- Configure go.nvim
      go = 'go', -- Go command
      goimports = 'gopls', -- Use gopls for imports (fix for deprecated goimport)
      gofmt = 'gofumpt', -- Use gofumpt for formatting
      lsp_cfg = true, -- Enable LSP configuration in go.nvim
      lsp_gofumpt = true,
      lsp_on_attach = true,
      dap_debug = false, -- Disable debugger for now
      test_runner = 'go', -- Use standard go test
      verbose_tests = true,
      run_in_floaterm = false, -- Use built-in terminal
    })
  else
    vim.notify("go.nvim not found", vim.log.levels.WARN)
  end

  -- Set up goimpl
  local goimpl_ok, goimpl = pcall(require, "telescope")
  if goimpl_ok then
    -- Setup the goimpl extension if telescope is available
    pcall(function()
      require("telescope").load_extension("goimpl")
    end)
  end
end

return M 