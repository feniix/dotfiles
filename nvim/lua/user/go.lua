-- Go configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true -- Set to false to disable automatic installation
}

-- Add setup guard to prevent recursion
local setup_in_progress = false

-- Function to get the Go binary directory
local function get_go_bin_path()
  local gopath = vim.fn.trim(vim.fn.system("go env GOPATH"))
  if gopath == "" then
    -- If GOPATH is not set, use XDG default
    gopath = vim.fn.expand("$HOME/.local/share/go")
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
  
  -- Set GOBIN to our target directory and install the tool
  local cmd = string.format("GOBIN=%s go install %s", go_bin_path, install_path)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system(cmd)
  
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
  
  -- Try direct installation if the first method failed
  if vim.fn.executable("gopls") ~= 1 and vim.fn.filereadable(go_bin_path .. "/gopls") ~= 1 then
    vim.notify("Trying alternative method to install gopls...", vim.log.levels.INFO)
    local cmd = "go install golang.org/x/tools/gopls@latest"
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to install gopls: " .. result, vim.log.levels.ERROR)
    else
      vim.notify("gopls installed successfully", vim.log.levels.INFO)
    end
  end
  
  ensure_go_tool("goimports", "golang.org/x/tools/cmd/goimports", "latest")
  ensure_go_tool("golangci-lint", "github.com/golangci/golangci-lint/cmd/golangci-lint", "latest") -- Always use latest stable version
  ensure_go_tool("gomodifytags", "github.com/fatih/gomodifytags", "latest")
  ensure_go_tool("gotests", "github.com/cweill/gotests/...", "latest")
  ensure_go_tool("impl", "github.com/josharian/impl", "latest")
  ensure_go_tool("gofumpt", "mvdan.cc/gofumpt", "latest")
  
  -- Additional tools from checkhealth
  ensure_go_tool("iferr", "github.com/koron/iferr", "latest")
  ensure_go_tool("callgraph", "golang.org/x/tools/cmd/callgraph", "latest")
  ensure_go_tool("golines", "github.com/segmentio/golines", "latest")
  ensure_go_tool("mockgen", "go.uber.org/mock/mockgen", "latest")
  ensure_go_tool("fillswitch", "github.com/davidrjenni/reftools/cmd/fillswitch", "latest")
  ensure_go_tool("ginkgo", "github.com/onsi/ginkgo/v2/ginkgo", "latest")
  ensure_go_tool("gotestsum", "gotest.tools/gotestsum", "latest")
  ensure_go_tool("json-to-struct", "github.com/tmc/json-to-struct", "latest")
  ensure_go_tool("gomvp", "github.com/abenz1267/gomvp", "latest")
  ensure_go_tool("gojsonstruct", "github.com/twpayne/go-jsonstruct/cmd/gojsonstruct", "latest")
  ensure_go_tool("govulncheck", "golang.org/x/vuln/cmd/govulncheck", "latest")
  ensure_go_tool("go-enum", "github.com/abice/go-enum", "latest")
  ensure_go_tool("gonew", "golang.org/x/tools/cmd/gonew", "latest")
  ensure_go_tool("dlv", "github.com/go-delve/delve/cmd/dlv", "latest")
  ensure_go_tool("richgo", "github.com/kyoh86/richgo", "latest")
end

-- Setup function with options
function M.setup(opts)
  -- Check for recursion
  if setup_in_progress then
    return
  end
  setup_in_progress = true

  -- Merge user options with defaults
  if opts then
    config = vim.tbl_extend("force", config, opts)
  end

  -- Ensure Go tools are installed
  ensure_go_tools()
  
  -- Set up go.nvim
  local go_ok, go = pcall(require, "go")
  if go_ok then
    -- Protect against unexpected errors in go.nvim
    local ok, err = pcall(function()
      go.setup({
        -- Configure go.nvim
        go = 'go', -- Go command
        goimports = 'gopls', -- Use gopls for imports (fix for deprecated goimport)
        gofmt = 'gofumpt', -- Use gofumpt for formatting
        lsp_cfg = true, -- Enable LSP configuration in go.nvim
        lsp_on_attach = function(client, bufnr)
          -- Call our custom LSP on_attach function
          local lsp_common_ok, lsp_common = pcall(require, 'user.lsp_common')
          if lsp_common_ok then
            local on_attach = lsp_common.create_on_attach()
            on_attach(client, bufnr)
          end
          
          -- Add specific Go keybindings
          local opts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set('n', '<leader>gtj', vim.lsp.buf.type_definition, opts)
          
          -- Safely setup the goimpl keybinding only if telescope is available and not disabled
          if vim.g.skip_telescope ~= true then
            pcall(function()
              vim.keymap.set('n', '<leader>gim', '<cmd>lua require("telescope").extensions.goimpl.goimpl()<CR>', opts)
            end)
          end
          
          -- Auto-format on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("GoFormat", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end,
        lsp_gofumpt = true,
        dap_debug = true, -- Enable debugging support
        test_runner = 'go', -- Use standard go test
        verbose_tests = true,
        run_in_floaterm = false, -- Use built-in terminal
      })
    end)
    
    if not ok then
      vim.notify("Error setting up go.nvim: " .. tostring(err), vim.log.levels.ERROR)
    end
  else
    vim.notify("go.nvim not found", vim.log.levels.WARN)
  end

  -- Set up goimpl with telescope only if telescope is not disabled
  if vim.g.skip_telescope ~= true then
    local telescope_ok = pcall(require, "telescope")
    if telescope_ok then
      -- Setup the goimpl extension if telescope is available
      pcall(function()
        require("telescope").load_extension("goimpl")
      end)
    end
  end
  
  -- Create a command to manually reinstall gopls
  vim.api.nvim_create_user_command('GoplsInstall', function()
    vim.notify("Reinstalling gopls...", vim.log.levels.INFO)
    -- Clear any existing gopls
    vim.fn.system("rm -f " .. go_bin_path .. "/gopls")
    -- Install gopls directly
    local cmd = "go install golang.org/x/tools/gopls@latest"
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to install gopls: " .. result, vim.log.levels.ERROR)
    else
      vim.notify("gopls installed successfully. Please restart Neovim.", vim.log.levels.INFO)
    end
  end, { desc = 'Manually reinstall gopls' })

  -- Reset the recursion guard
  setup_in_progress = false
end

-- Helper function for Go files - replaces the VimScript function s:build_go_files()
function M.build_go_files()
  local file = vim.fn.expand('%')
  if file:match('_test%.go$') then
    vim.cmd('GoTest')
  elseif file:match('%.go$') then
    vim.cmd('GoBuild')
  end
end

-- Go alternate file functions
function M.go_alternate_edit()
  vim.cmd('call go#alternate#Switch(0, "edit")')
end

function M.go_alternate_vertical()
  vim.cmd('call go#alternate#Switch(0, "vsplit")')
end

function M.go_alternate_split()
  vim.cmd('call go#alternate#Switch(0, "split")')
end

function M.go_alternate_tab()
  vim.cmd('call go#alternate#Switch(0, "tabe")')
end

return M 