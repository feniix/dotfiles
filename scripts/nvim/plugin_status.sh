#!/bin/bash
# Simple check for Neovim plugins installed with lazy.nvim

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=========================================${RESET}"
echo -e "${BLUE}Checking Neovim lazy.nvim Plugins${RESET}"
echo -e "${BLUE}=========================================${RESET}"

# Create temporary Lua script for checking plugins
TEMP_SCRIPT="/tmp/check_plugins.lua"

# Create the Lua script
cat > "$TEMP_SCRIPT" << 'EOF'
local function check_plugin_exists(plugin_name)
  -- Check in lazy.nvim directory
  local lazy_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name
  if vim.fn.isdirectory(lazy_path) == 1 then
    return true, "lazy.nvim"
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
  "lazy.nvim", 
  "nvim-cmp",
  "nvim-treesitter",
  "nvim-dap",
  "nvim-dap-ui",
  "nvim-nio",
  "vim-go",
  "plenary.nvim",
  "telescope.nvim",
  "cmp-buffer",
  "cmp-path",
  "cmp-cmdline",
  "neosolarized.nvim",
  "colorbuddy.nvim",
  "gitsigns.nvim",
  "which-key.nvim",
  "lualine.nvim",
  "diffview.nvim"
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
      print("✅ " .. plugin .. " is installed (via " .. location .. ")")
      installed = installed + 1
    end
  else
    print("❌ " .. plugin .. " is missing")
    missing = missing + 1
  end
end

print("")
print("Summary:")
print("- " .. installed .. " plugins installed via lazy.nvim")
print("- " .. legacy .. " plugins using legacy vim-plug")
print("- " .. missing .. " plugins missing")

if missing > 0 then
  print("")
  print("Run :Lazy sync to install missing plugins")
end

if legacy > 0 then
  print("")
  print("Some plugins are still using vim-plug. Complete the migration to lazy.nvim.")
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