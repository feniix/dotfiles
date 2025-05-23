-- Which-key configuration for keymap discovery and organization
local M = {}

function M.setup()
  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    vim.notify("which-key not available. Run :PackerSync to install.", vim.log.levels.WARN)
    return
  end

  -- Configure which-key with new v3 API
  which_key.setup({
    preset = "classic",
    -- Delay before showing the popup
    delay = function(ctx)
      return ctx.plugin and 0 or 200
    end,
    -- Disable overlap notifications - these warnings are mostly false positives
    -- from legitimate plugin hierarchical mappings (surround, comment, etc.)
    notify = false,
    plugins = {
      marks = true, -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      spelling = {
        enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions = 20, -- how many suggestions should be shown in the list?
      },
      presets = {
        operators = true, -- adds help for operators like d, y, ...
        motions = true, -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = true, -- default bindings on <c-w>
        nav = true, -- misc bindings to work with windows
        z = true, -- bindings for folds, spelling and others prefixed with z
        g = true, -- bindings for prefixed with g
      },
    },
    win = {
      border = "rounded",
      padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
      title = true,
      title_pos = "center",
    },
    layout = {
      width = { min = 20 },
      spacing = 3,
    },
    keys = {
      scroll_down = "<c-d>",
      scroll_up = "<c-u>",
    },
    sort = { "local", "order", "group", "alphanum", "mod" },
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
      mappings = true,
      keys = {
        Up = " ",
        Down = " ",
        Left = " ",
        Right = " ",
        C = "󰘴 ",
        M = "󰘵 ",
        S = "󰘶 ",
        CR = "󰌑 ",
        Esc = "󱊷 ",
        Space = "󱁐 ",
        Tab = "󰌒 ",
      },
    },
    show_help = true,
    show_keys = true,
  })

  -- Set up leader key mappings using new add() API
  M.setup_leader_mappings()
  
  -- Set up other key groups
  M.setup_other_mappings()
  
  -- Document expected plugin overlaps to avoid warnings
  M.setup_plugin_overlaps()
end

function M.setup_leader_mappings()
  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    return
  end
  
  -- Define leader key groups and mappings using new v3 API
  which_key.add({
    -- Buffer operations
    { "<leader>b", group = "Buffer" },
    { "<leader>bn", desc = "Next buffer" },
    { "<leader>bp", desc = "Previous buffer" },
    { "<leader>bd", desc = "Delete buffer" },
    { "<leader>bl", desc = "List buffers" },
    
    -- File operations (Telescope)
    { "<leader>f", group = "Find/File" },
    { "<leader>ff", desc = "Find files" },
    { "<leader>fg", desc = "Live grep" },
    { "<leader>fb", desc = "Buffers" },
    { "<leader>fh", desc = "Help tags" },
    { "<leader>fr", desc = "Recent files" },
    { "<leader>fc", desc = "Colorschemes" },
    { "<leader>fw", desc = "Grep word under cursor" },
    { "<leader>fs", desc = "Grep search" },
    { "<leader>fk", desc = "Keymaps" },
    { "<leader>fm", desc = "Marks" },
    { "<leader>fo", desc = "Vim options" },
    { "<leader>ft", desc = "Filetypes" },
    
    -- Git operations (Telescope + Git commands)
    { "<leader>g", group = "Git" },
    { "<leader>gc", desc = "Git commits" },
    { "<leader>gb", desc = "Git branches" },
    { "<leader>gs", desc = "Git status" },
    { "<leader>gl", desc = "Go metalinter" }, -- Go-specific, but grouped here
    
    -- LSP operations (when LSP is set up)
    { "<leader>l", group = "LSP/Language" },
    { "<leader>lr", desc = "LSP references" },
    { "<leader>ld", desc = "LSP definitions" },
    { "<leader>li", desc = "LSP implementations" },
    { "<leader>ls", desc = "LSP document symbols" },
    { "<leader>lw", desc = "LSP workspace symbols" },
    { "<leader>ll", desc = "Toggle list characters" },
    
    -- Debug operations (DAP)
    { "<leader>d", group = "Debug" },
    { "<leader>db", desc = "Toggle breakpoint" },
    { "<leader>df", desc = "Peek function definition" },
    { "<leader>dF", desc = "Peek class definition" },
    
    -- Text object swapping (TreeSitter)
    { "<leader>s", group = "Swap" },
    { "<leader>sn", group = "Next" },
    { "<leader>sna", desc = "Swap next argument" },
    { "<leader>snm", desc = "Swap next method" },
    { "<leader>sp", group = "Previous" },
    { "<leader>spa", desc = "Swap previous argument" },
    { "<leader>spm", desc = "Swap previous method" },
    
    -- Toggle operations
    { "<leader>t", group = "Toggle" },
    { "<leader>tn", desc = "Toggle relative line numbers" },
    { "<leader>tw", desc = "Toggle wrap" },
    { "<leader>ts", desc = "Toggle spell check" },
    { "<leader>ti", desc = "Toggle indent guides" },
    { "<leader>tI", desc = "Toggle indent scope" },
    
    -- Other single-key leader mappings
    { "<leader>q", desc = "Clear search highlight" },
  })
end

function M.setup_other_mappings()
  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    return
  end
  
  -- Window navigation
  which_key.add({
    { "<C-h>", desc = "Window left" },
    { "<C-j>", desc = "Window down" },
    { "<C-k>", desc = "Window up" },
    { "<C-l>", desc = "Window right" },
  })
  
  -- File operations
  which_key.add({
    { "<C-s>", desc = "Save file" },
    { "<C-a>", desc = "Select all" },
    { "<C-z>", desc = "Undo" },
    { "<C-y>", desc = "Redo" },
    { "<C-p>", desc = "Find files (Telescope)" },
    { "<C-f>", desc = "Live grep (Telescope)" },
  })
  
  -- Terminal mode
  which_key.add({
    { "<Esc>", desc = "Exit terminal mode", mode = "t" },
  })
  
  -- TreeSitter text object movements
  which_key.add({
    { "]", group = "Next" },
    { "]m", desc = "Next function start" },
    { "]M", desc = "Next function end" },
    { "]]", desc = "Next class start" },
    { "]}", desc = "Next class end" },
    { "]o", desc = "Next loop start" },
    { "]O", desc = "Next loop end" },
    { "]d", desc = "Next conditional" },
    { "]s", desc = "Next scope" },
    { "]z", desc = "Next fold" },
  })
  
  which_key.add({
    { "[", group = "Previous" }, 
    { "[m", desc = "Previous function start" },
    { "[M", desc = "Previous function end" },
    { "[[", desc = "Previous class start" },
    { "[{", desc = "Previous class end" },
    { "[o", desc = "Previous loop start" },
    { "[O", desc = "Previous loop end" },
    { "[d", desc = "Previous conditional" },
    { "[s", desc = "Previous scope" },
    { "[z", desc = "Previous fold" },
  })
  
  -- Visual mode text objects help
  which_key.add({
    { "a", group = "Around textobj", mode = "v" },
    { "af", desc = "Function", mode = "v" },
    { "ac", desc = "Class", mode = "v" },
    { "ab", desc = "Block", mode = "v" },
    { "aa", desc = "Argument", mode = "v" },
    { "ai", desc = "Conditional", mode = "v" },
    { "al", desc = "Loop", mode = "v" },
    { "aC", desc = "Call", mode = "v" },
    { "aM", desc = "Comment", mode = "v" },
    { "a=", desc = "Assignment", mode = "v" },
    { "aN", desc = "Number", mode = "v" },
    { "aR", desc = "Return", mode = "v" },
    
    { "i", group = "Inside textobj", mode = "v" },
    { "if", desc = "Function", mode = "v" },
    { "ic", desc = "Class", mode = "v" },
    { "ib", desc = "Block", mode = "v" },
    { "ia", desc = "Argument", mode = "v" },
    { "ii", desc = "Conditional", mode = "v" },
    { "il", desc = "Loop", mode = "v" },
    { "iC", desc = "Call", mode = "v" },
    { "iM", desc = "Comment", mode = "v" },
    { "i=", desc = "Assignment", mode = "v" },
    { "iN", desc = "Number", mode = "v" },
    { "iR", desc = "Return", mode = "v" },
  })
  
  -- Also register for operator-pending mode
  which_key.add({
    { "a", group = "Around textobj", mode = "o" },
    { "af", desc = "Function", mode = "o" },
    { "ac", desc = "Class", mode = "o" },
    { "ab", desc = "Block", mode = "o" },
    { "aa", desc = "Argument", mode = "o" },
    { "ai", desc = "Conditional", mode = "o" },
    { "al", desc = "Loop", mode = "o" },
    { "aC", desc = "Call", mode = "o" },
    { "aM", desc = "Comment", mode = "o" },
    { "a=", desc = "Assignment", mode = "o" },
    { "aN", desc = "Number", mode = "o" },
    { "aR", desc = "Return", mode = "o" },
    
    { "i", group = "Inside textobj", mode = "o" },
    { "if", desc = "Function", mode = "o" },
    { "ic", desc = "Class", mode = "o" },
    { "ib", desc = "Block", mode = "o" },
    { "ia", desc = "Argument", mode = "o" },
    { "ii", desc = "Conditional", mode = "o" },
    { "il", desc = "Loop", mode = "o" },
    { "iC", desc = "Call", mode = "o" },
    { "iM", desc = "Comment", mode = "o" },
    { "i=", desc = "Assignment", mode = "o" },
    { "iN", desc = "Number", mode = "o" },
    { "iR", desc = "Return", mode = "o" },
  })
end

-- Function to set up Go-specific which-key mappings
function M.setup_go_mappings()
  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    return
  end
  
  -- Go-specific leader mappings (buffer-local to avoid conflicts)
  which_key.add({
    { "<leader>G", group = "Go", buffer = 0 },
    { "<leader>Gb", desc = "Build Go files", buffer = 0 },
    { "<leader>Gt", desc = "Go test", buffer = 0 },
    { "<leader>Gr", desc = "Go run", buffer = 0 },
    { "<leader>Gd", desc = "Go doc", buffer = 0 },
    { "<leader>Gc", desc = "Go coverage toggle", buffer = 0 },
    { "<leader>Gi", desc = "Go info", buffer = 0 },
    { "<leader>Gv", desc = "Go def vertical split", buffer = 0 },
    { "<leader>Gs", desc = "Go def horizontal split", buffer = 0 },
    { "<leader>Gl", desc = "Go metalinter", buffer = 0 },
  })
end

-- Function to document expected plugin overlaps (reduces health check warnings)
function M.setup_plugin_overlaps()
  local which_key_ok, which_key = pcall(require, 'which-key')
  if not which_key_ok then
    return
  end
  
  -- Document vim-surround keymaps to avoid overlap warnings
  -- These are intentional hierarchical mappings where the shorter key waits for motion
  which_key.add({
    { "ys", group = "Surround motion" },
    { "yss", desc = "Surround current line" },
    { "yS", group = "Surround motion (new lines)" },
    { "ySS", desc = "Surround current line (new lines)" },
  })
  
  -- Document Comment.nvim keymaps to avoid overlap warnings  
  -- These are intentional hierarchical mappings for different comment operations
  which_key.add({
    { "gc", group = "Comment linewise" },
    { "gcc", desc = "Comment current line" },
    { "gcA", desc = "Comment at end of line" },
    { "gco", desc = "Comment line below" },
    { "gcO", desc = "Comment line above" },
    { "gb", group = "Comment blockwise" },
    { "gbc", desc = "Comment current block" },
  })
end

return M 