#!/bin/bash
# Simple check for Neovim plugins installed with Packer

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Checking Neovim Packer Plugins${RESET}"
echo -e "${BLUE}=========================================${RESET}"

# Create temporary Lua script for checking plugins
TEMP_SCRIPT="/tmp/check_plugins.lua"

# Create the Lua script
cat > "$TEMP_SCRIPT" << 'EOF'
local function check_plugin_exists(plugin_name)
  -- Check in Packer start directory
  local packer_start = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. plugin_name
  if vim.fn.isdirectory(packer_start) == 1 then
    return true, "start"
  end
  
  -- Check in Packer opt directory
  local packer_opt = vim.fn.stdpath("data") .. "/site/pack/packer/opt/" .. plugin_name
  if vim.fn.isdirectory(packer_opt) == 1 then
    return true, "opt"
  end
  
  -- Check vim-plug directory (legacy)
  local plugged = vim.fn.stdpath("data") .. "/plugged/" .. plugin_name
  if vim.fn.isdirectory(plugged) == 1 then
    return true, "vim-plug"
  end
  
  return false, nil
end

-- List of essential plugins to check
local plugins = {
  "packer.nvim", 
  "nvim-lspconfig",
  "nvim-cmp",
  "LuaSnip",
  "nvim-treesitter",
  "nvim-dap",
  "nvim-dap-ui",
  "nvim-nio",
  "go.nvim",
  "vim-go", -- Optional
  "plenary.nvim",
  "telescope.nvim",
  "cmp-nvim-lsp",
  "cmp-buffer",
  "cmp-path",
  "cmp_luasnip",
  "solarized.nvim"
}

-- Check and report results
print("## Plugin Status Report ##")
print("")

local missing = 0
local installed = 0
local legacy = 0

for _, plugin in ipairs(plugins) do
  local exists, location = check_plugin_exists(plugin)
  
  if exists then
    if location == "vim-plug" then
      print("⚠️  " .. plugin .. " is installed (via vim-plug)")
      legacy = legacy + 1
    else
      print("✅ " .. plugin .. " is installed (via Packer/" .. location .. ")")
      installed = installed + 1
    end
  else
    print("❌ " .. plugin .. " is missing")
    missing = missing + 1
  end
end

print("")
print("Summary:")
print("- " .. installed .. " plugins installed via Packer")
print("- " .. legacy .. " plugins using legacy vim-plug")
print("- " .. missing .. " plugins missing")

if missing > 0 then
  print("")
  print("Run :PackerSync to install missing plugins")
end

if legacy > 0 then
  print("")
  print("Some plugins are still using vim-plug. Complete the migration to Packer.")
end
EOF

# Run the script in Neovim and capture output
echo -e "${YELLOW}Running plugin check...${RESET}\n"
nvim --headless -l "$TEMP_SCRIPT" -c "quit" | grep -v "^$" | \
  sed "s/✅/${GREEN}✅${RESET}/g" | \
  sed "s/⚠️/${YELLOW}⚠️${RESET}/g" | \
  sed "s/❌/${RED}❌${RESET}/g"

# Clean up
rm -f "$TEMP_SCRIPT"

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${GREEN}Plugin check complete${RESET}"
echo -e "${BLUE}=========================================${RESET}"
echo -e "\n${YELLOW}To run a full health check, open Neovim and run:${RESET}"
echo -e "  :checkhealth user"

exit 0 