-- Cross-platform detection and configuration module
-- This centralizes all platform-specific logic for better maintainability

local M = {}

-- Cache platform detection results
M._cache = {}

-- Detect the operating system
function M.get_os()
  if M._cache.os then
    return M._cache.os
  end
  
  local os_name = "unknown"
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    os_name = "windows"
  elseif vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    os_name = "macos"
  elseif vim.fn.has("unix") == 1 then
    -- Further distinguish Linux distributions if needed
    local uname = vim.fn.system("uname -s"):gsub("%s+", ""):lower()
    if uname:match("linux") then
      os_name = "linux"
    elseif uname:match("freebsd") then
      os_name = "freebsd"
    elseif uname:match("openbsd") then
      os_name = "openbsd"
    else
      os_name = "unix"
    end
  end
  
  M._cache.os = os_name
  return os_name
end

-- Detect terminal emulator
function M.get_terminal()
  if M._cache.terminal then
    return M._cache.terminal
  end
  
  local terminal = "unknown"
  
  -- Check environment variables for terminal detection
  if vim.env.TERM_PROGRAM then
    local term_program = vim.env.TERM_PROGRAM:lower()
    if term_program:match("iterm") then
      terminal = "iterm2"
    elseif term_program:match("apple_terminal") then
      terminal = "apple_terminal"
    elseif term_program:match("vscode") then
      terminal = "vscode"
    end
  elseif vim.env.WEZTERM_EXECUTABLE then
    terminal = "wezterm"
  elseif vim.env.ALACRITTY_SOCKET then
    terminal = "alacritty"
  elseif vim.env.KITTY_WINDOW_ID then
    terminal = "kitty"
  elseif vim.env.GNOME_TERMINAL_SCREEN then
    terminal = "gnome_terminal"
  elseif vim.env.KONSOLE_VERSION then
    terminal = "konsole"
  elseif vim.env.XTERM_VERSION then
    terminal = "xterm"
  elseif vim.env.TMUX then
    terminal = "tmux"
  elseif vim.env.TERM then
    local term = vim.env.TERM:lower()
    if term:match("screen") then
      terminal = "screen"
    elseif term:match("tmux") then
      terminal = "tmux"
    elseif term:match("xterm") then
      terminal = "xterm"
    end
  end
  
  -- Windows Terminal detection
  if M.get_os() == "windows" and vim.env.WT_SESSION then
    terminal = "windows_terminal"
  end
  
  M._cache.terminal = terminal
  return terminal
end

-- Check if we're running in a GUI environment
function M.is_gui()
  if M._cache.is_gui ~= nil then
    return M._cache.is_gui
  end
  
  local gui = vim.fn.has("gui_running") == 1 or 
             vim.g.neovide or 
             vim.env.NVIM_GUI or
             vim.env.GONEOVIM
             
  M._cache.is_gui = gui
  return gui
end

-- Get the appropriate clipboard commands for the current platform
function M.get_clipboard_config()
  if M._cache.clipboard then
    return M._cache.clipboard
  end
  
  local os_name = M.get_os()
  local config = {}
  
  if os_name == "macos" then
    config = {
      name = 'pbcopy',
      copy = {
        ['+'] = 'pbcopy',
        ['*'] = 'pbcopy',
      },
      paste = {
        ['+'] = 'pbpaste',
        ['*'] = 'pbpaste',
      },
      cache_enabled = 1,
    }
  elseif os_name == "linux" or os_name == "freebsd" or os_name == "openbsd" then
    -- Check for available clipboard utilities in order of preference
    if vim.fn.executable('wl-copy') == 1 and vim.fn.executable('wl-paste') == 1 then
      -- Wayland
      config = {
        name = 'wl-clipboard',
        copy = {
          ['+'] = 'wl-copy',
          ['*'] = 'wl-copy --primary',
        },
        paste = {
          ['+'] = 'wl-paste --no-newline',
          ['*'] = 'wl-paste --no-newline --primary',
        },
        cache_enabled = 1,
      }
    elseif vim.fn.executable('xclip') == 1 then
      -- X11 with xclip
      config = {
        name = 'xclip',
        copy = {
          ['+'] = 'xclip -selection clipboard',
          ['*'] = 'xclip -selection primary',
        },
        paste = {
          ['+'] = 'xclip -selection clipboard -o',
          ['*'] = 'xclip -selection primary -o',
        },
        cache_enabled = 1,
      }
    elseif vim.fn.executable('xsel') == 1 then
      -- X11 with xsel
      config = {
        name = 'xsel',
        copy = {
          ['+'] = 'xsel --clipboard --input',
          ['*'] = 'xsel --primary --input',
        },
        paste = {
          ['+'] = 'xsel --clipboard --output',
          ['*'] = 'xsel --primary --output',
        },
        cache_enabled = 1,
      }
    end
  elseif os_name == "windows" then
    -- Windows clipboard
    config = {
      name = 'win32yank',
      copy = {
        ['+'] = 'win32yank.exe -i --crlf',
        ['*'] = 'win32yank.exe -i --crlf',
      },
      paste = {
        ['+'] = 'win32yank.exe -o --lf',
        ['*'] = 'win32yank.exe -o --lf',
      },
      cache_enabled = 1,
    }
  end
  
  M._cache.clipboard = config
  return config
end

-- Get terminal-specific configurations
function M.get_terminal_config()
  local terminal = M.get_terminal()
  local config = {}
  
  if terminal == "iterm2" then
    config = {
      supports_true_color = true,
      supports_undercurl = true,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 3, horizontal = 6 },
      -- iTerm2-specific optimizations
      enable_smooth_scrolling = true,
      support_focus_events = true,
    }
  elseif terminal == "kitty" then
    config = {
      supports_true_color = true,
      supports_undercurl = true,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 3, horizontal = 6 },
      support_focus_events = true,
    }
  elseif terminal == "alacritty" then
    config = {
      supports_true_color = true,
      supports_undercurl = true,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 3, horizontal = 6 },
    }
  elseif terminal == "wezterm" then
    config = {
      supports_true_color = true,
      supports_undercurl = true,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 3, horizontal = 6 },
      support_focus_events = true,
    }
  elseif terminal == "windows_terminal" then
    config = {
      supports_true_color = true,
      supports_undercurl = false,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 3, horizontal = 6 },
    }
  elseif terminal == "tmux" or terminal == "screen" then
    config = {
      supports_true_color = true, -- If tmux >= 2.2
      supports_undercurl = false,
      supports_mouse = true,
      mouse_scroll_speed = { vertical = 1, horizontal = 1 },
      is_multiplexer = true,
    }
  else
    -- Conservative defaults for unknown terminals
    config = {
      supports_true_color = false,
      supports_undercurl = false,
      supports_mouse = false,
      mouse_scroll_speed = { vertical = 1, horizontal = 1 },
    }
  end
  
  return config
end

-- Get platform-specific key mappings
function M.get_platform_keymaps()
  local os_name = M.get_os()
  local keymaps = {}
  
  if os_name == "macos" then
    -- macOS-specific keymaps using option key characters
    keymaps = {
      -- Move lines up/down with Option+j/k
      { mode = "n", lhs = "∆", rhs = ":m .+1<CR>==", desc = "Move line down" },
      { mode = "n", lhs = "˚", rhs = ":m .-2<CR>==", desc = "Move line up" },
      { mode = "i", lhs = "∆", rhs = "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
      { mode = "i", lhs = "˚", rhs = "<Esc>:m .-2<CR>==gi", desc = "Move line up" },
      { mode = "v", lhs = "∆", rhs = ":m '>+1<CR>gv=gv", desc = "Move selection down" },
      { mode = "v", lhs = "˚", rhs = ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      
      -- Word jumping with Option+h/l
      { mode = "n", lhs = "˙", rhs = "b", desc = "Jump word backward" },
      { mode = "n", lhs = "¬", rhs = "w", desc = "Jump word forward" },
    }
  elseif os_name == "linux" or os_name == "freebsd" or os_name == "openbsd" then
    -- Linux/Unix keymaps using more standard combinations
    keymaps = {
      -- Move lines up/down with Alt+j/k (if terminal supports it)
      { mode = "n", lhs = "<A-j>", rhs = ":m .+1<CR>==", desc = "Move line down" },
      { mode = "n", lhs = "<A-k>", rhs = ":m .-2<CR>==", desc = "Move line up" },
      { mode = "i", lhs = "<A-j>", rhs = "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
      { mode = "i", lhs = "<A-k>", rhs = "<Esc>:m .-2<CR>==gi", desc = "Move line up" },
      { mode = "v", lhs = "<A-j>", rhs = ":m '>+1<CR>gv=gv", desc = "Move selection down" },
      { mode = "v", lhs = "<A-k>", rhs = ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      
      -- Word jumping with Alt+h/l
      { mode = "n", lhs = "<A-h>", rhs = "b", desc = "Jump word backward" },
      { mode = "n", lhs = "<A-l>", rhs = "w", desc = "Jump word forward" },
    }
  elseif os_name == "windows" then
    -- Windows keymaps
    keymaps = {
      -- Move lines up/down with Alt+j/k
      { mode = "n", lhs = "<A-j>", rhs = ":m .+1<CR>==", desc = "Move line down" },
      { mode = "n", lhs = "<A-k>", rhs = ":m .-2<CR>==", desc = "Move line up" },
      { mode = "i", lhs = "<A-j>", rhs = "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
      { mode = "i", lhs = "<A-k>", rhs = "<Esc>:m .-2<CR>==gi", desc = "Move line up" },
      { mode = "v", lhs = "<A-j>", rhs = ":m '>+1<CR>gv=gv", desc = "Move selection down" },
      { mode = "v", lhs = "<A-k>", rhs = ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      
      -- Word jumping with Ctrl+Left/Right (Windows standard)
      { mode = "n", lhs = "<C-Left>", rhs = "b", desc = "Jump word backward" },
      { mode = "n", lhs = "<C-Right>", rhs = "w", desc = "Jump word forward" },
      { mode = "i", lhs = "<C-Left>", rhs = "<C-o>b", desc = "Jump word backward" },
      { mode = "i", lhs = "<C-Right>", rhs = "<C-o>w", desc = "Jump word forward" },
    }
  end
  
  return keymaps
end

-- Check if a command is available
function M.command_available(cmd)
  if type(cmd) == "string" then
    return vim.fn.executable(cmd) == 1
  elseif type(cmd) == "table" then
    -- Check if any command in the list is available
    for _, c in ipairs(cmd) do
      if vim.fn.executable(c) == 1 then
        return true
      end
    end
    return false
  end
  return false
end

-- Get language-specific tools availability
function M.get_language_tools()
  local tools = {}
  
  -- Go tools
  tools.go = {
    goimports = M.command_available("goimports"),
    gofumpt = M.command_available("gofumpt"),
    golangci_lint = M.command_available("golangci-lint"),
    gomodifytags = M.command_available("gomodifytags"),
    gotests = M.command_available("gotests"),
    dlv = M.command_available("dlv"), -- Delve debugger
  }
  
  -- Node.js tools
  tools.node = {
    npm = M.command_available("npm"),
    yarn = M.command_available("yarn"),
    pnpm = M.command_available("pnpm"),
    node = M.command_available("node"),
  }
  
  -- Python tools
  tools.python = {
    python3 = M.command_available("python3"),
    pip = M.command_available("pip"),
    pip3 = M.command_available("pip3"),
  }
  
  -- Git
  tools.git = {
    git = M.command_available("git"),
  }
  
  return tools
end

-- Apply platform-specific configurations
function M.apply_config()
  local os_name = M.get_os()
  local terminal_config = M.get_terminal_config()
  
  -- Set true color support
  if terminal_config.supports_true_color then
    vim.opt.termguicolors = true
  end
  
  -- Set mouse support
  if terminal_config.supports_mouse then
    vim.opt.mouse = "a"
  end
  
  -- Set clipboard if available
  local clipboard_config = M.get_clipboard_config()
  if clipboard_config and next(clipboard_config) ~= nil and vim.fn.has('clipboard') == 1 then
    vim.g.clipboard = clipboard_config
  end
  
  -- Set mouse scroll speed
  if terminal_config.mouse_scroll_speed then
    local scroll_config = string.format("ver:%d,hor:%d", 
                                        terminal_config.mouse_scroll_speed.vertical,
                                        terminal_config.mouse_scroll_speed.horizontal)
    vim.opt.mousescroll = scroll_config
  end
  
  -- Platform-specific settings
  if os_name == "windows" then
    -- Windows-specific settings
    vim.opt.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
  end
end

-- Legacy compatibility functions
function M.is_iterm2()
  return M.get_terminal() == "iterm2"
end

function M.is_mac()
  return M.get_os() == "macos"
end

function M.is_windows()
  return M.get_os() == "windows"
end

function M.is_linux()
  return M.get_os() == "linux"
end

return M 