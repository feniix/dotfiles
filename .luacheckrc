-- Luacheck configuration for Neovim Lua code validation
-- This configuration is specifically designed for Neovim plugin and configuration development
-- See: https://luacheck.readthedocs.io/en/stable/config.html

std = "luajit"
cache = true

-- Neovim-specific globals and API
globals = {
  "vim",           -- Main Neovim API namespace
  "is_mac",        -- Platform detection helper (custom global)
  "is_linux",      -- Platform detection helper (custom global)
  "safe_require",  -- Safe module loading helper (custom global)
  "map",           -- Keymap helper (custom global)
  "nmap",          -- Normal mode keymap helper (custom global)
  "vmap",          -- Visual mode keymap helper (custom global)
  "imap",          -- Insert mode keymap helper (custom global)
  "tmap",          -- Terminal mode keymap helper (custom global)
}

-- Ignore specific warnings common in Neovim Lua development
ignore = {
  "212", -- Unused argument (common in callback functions)
  "213", -- Unused loop variable (common in iteration patterns)
  "631", -- Line too long (Neovim configs can have long option chains)
  "611", -- Line contains only whitespace
  "612", -- Line contains trailing whitespace
  "614", -- Trailing whitespace in comment
}

-- File-specific rules for Neovim configuration structure
files["lua/user/"] = {
  globals = { "user_config" }  -- User configuration namespace
}

files["lua/plugins/"] = {
  globals = { "require" }      -- Plugin management globals
}

-- Exclude example files and templates from validation
exclude_files = {
  "lua/user/config.lua.example",    -- User configuration template
  "lua/user/modules/*.example",     -- User module templates
} 