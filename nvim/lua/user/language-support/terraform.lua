-- Terraform configuration module
local M = {}

-- Configuration
local config = {
  auto_install_tools = true, -- Set to false to disable automatic installation
  auto_format_on_save = true -- Enable formatting on save
}

-- Function to get the home directory
local function get_home_path()
  return vim.fn.expand("$HOME")
end

-- Cache the home path
local home_path = get_home_path()

-- Function to check if a tool is installed and install it if needed
local function ensure_terraform_tool(tool, install_cmd)
  if not config.auto_install_tools then
    return
  end

  -- Check if tool is already installed
  if vim.fn.executable(tool) == 1 then
    -- Tool is already installed and available
    return
  end
  
  vim.notify(tool .. " not found, installing...", vim.log.levels.INFO)
  
  -- Use vim's system function to install the tool
  local install_result = vim.fn.system(install_cmd)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install " .. tool .. ": " .. install_result, vim.log.levels.ERROR)
  else
    vim.notify(tool .. " installed successfully", vim.log.levels.INFO)
  end
end

-- Function to install all required Terraform tools
local function ensure_terraform_tools()
  if vim.fn.has("mac") == 1 then
    -- macOS installation via Homebrew
    ensure_terraform_tool("terraform", "brew install terraform")
    ensure_terraform_tool("terraform-ls", "brew install hashicorp/tap/terraform-ls")
    ensure_terraform_tool("tflint", "brew install tflint")
  elseif vim.fn.has("unix") == 1 then
    -- Linux - use TF_INSTALL_DIR if we can't install globally
    local install_dir = home_path .. "/.local/bin"
    
    -- Create directory if it doesn't exist
    if vim.fn.isdirectory(install_dir) == 0 then
      vim.fn.mkdir(install_dir, "p")
    end
    
    -- Install terraform and terraform-ls using their recommended methods
    -- These are simplified and might need to be adapted for specific Linux distros
    ensure_terraform_tool("terraform", 
      "curl -fsSL https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_" .. 
      vim.fn.system("uname -m") .. ".zip -o /tmp/terraform.zip && " ..
      "unzip -o /tmp/terraform.zip -d " .. install_dir .. " && " ..
      "chmod +x " .. install_dir .. "/terraform")
      
    ensure_terraform_tool("terraform-ls",
      "curl -fsSL https://releases.hashicorp.com/terraform-ls/0.31.4/terraform-ls_0.31.4_" .. 
      vim.fn.system("uname -m") .. ".zip -o /tmp/terraform-ls.zip && " ..
      "unzip -o /tmp/terraform-ls.zip -d " .. install_dir .. " && " ..
      "chmod +x " .. install_dir .. "/terraform-ls")
      
    ensure_terraform_tool("tflint",
      "curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash")
  end
end

-- Setup function with options
M.setup = function(opts)
  -- Merge user options with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  -- Ensure Terraform tools are installed
  ensure_terraform_tools()
  
  -- Configure LSP for Terraform if nvim-lspconfig is available
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok and lspconfig.terraformls then
    -- Set up terraform-ls with enhanced settings
    lspconfig.terraformls.setup({
      on_attach = function(client, bufnr)
        -- Call the base LSP on_attach if available
        local lsp_common_ok, lsp_common = pcall(require, "user.lsp_common")
        if lsp_common_ok and lsp_common.create_on_attach then
          lsp_common.create_on_attach()(client, bufnr)
        end
        
        -- Set up formatting on save
        if config.auto_format_on_save then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("TerraformFormat", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
        
        -- Add additional keymaps for Terraform
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<leader>ti', '<cmd>!terraform init<CR>', opts)
        vim.keymap.set('n', '<leader>tv', '<cmd>!terraform validate<CR>', opts)
        vim.keymap.set('n', '<leader>tp', '<cmd>!terraform plan<CR>', opts)
        vim.keymap.set('n', '<leader>ta', '<cmd>!terraform apply<CR>', opts)
      end,
      settings = {
        terraform = {
          path = "terraform",
          telemetry = { enable = false },
          experimentalFeatures = {
            validateOnSave = true,
            prefillRequiredFields = true,
          },
        },
      },
    })
  end
  
  -- Set up tflint if available
  if vim.fn.executable("tflint") == 1 then
    -- Create autocmd for tflint integration
    vim.api.nvim_create_autocmd({"BufWritePost"}, {
      pattern = {"*.tf", "*.tfvars"},
      group = vim.api.nvim_create_augroup("TFLint", { clear = true }),
      callback = function()
        if config.auto_install_tools then
          local output = vim.fn.system("tflint --format compact")
          if output ~= "" then
            -- Show tflint output in a split window
            vim.cmd("split")
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))
            vim.api.nvim_win_set_buf(0, buf)
            vim.api.nvim_buf_set_option(buf, "filetype", "tflint")
            vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
            vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
            vim.api.nvim_win_set_height(0, 10)
          end
        end
      end
    })
  end
end

return M 