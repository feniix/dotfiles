# Plugin System Documentation

The plugin system is built around [lazy.nvim](https://github.com/folke/lazy.nvim) and follows a clear separation between plugin specifications (what to install) and plugin configurations (how to configure).

## Architecture Overview

```
plugins/
├── init.lua           # Plugin loader and lazy.nvim setup
├── specs/             # Plugin specifications (what to install)
│   ├── ui.lua         # UI-related plugins
│   ├── editor.lua     # Editor enhancement plugins
│   ├── lsp.lua        # LSP and completion plugins
│   ├── tools.lua      # Development tools
│   └── lang/          # Language-specific plugins
└── config/            # Plugin configurations (how to configure)
    ├── telescope.lua  # File finder configuration
    ├── treesitter.lua # Syntax highlighting configuration
    ├── cmp.lua        # Completion configuration
    ├── lualine.lua    # Status line configuration
    └── lang/          # Language-specific configurations
```

## Design Principles

### 1. Separation of Concerns
- **Specifications** define what plugins to install, dependencies, and lazy loading conditions
- **Configurations** define how plugins should be set up and behave
- This allows easy plugin management without affecting configurations

### 2. Lazy Loading Strategy
- Plugins load only when needed (events, commands, file types)
- Optimized startup time through intelligent dependency management
- Event-driven loading for better performance

### 3. Modular Organization
- Plugins grouped by functionality (UI, editor, LSP, tools, languages)
- Language-specific plugins and configs are isolated
- Easy to enable/disable entire categories

## Plugin Specifications (`specs/`)

Plugin specifications define what plugins to install and when to load them.

### ui.lua - UI Related Plugins

**Core UI Plugins**:
- **catppuccin/nvim** - Color scheme
- **lualine.nvim** - Status line
- **which-key.nvim** - Keymap help
- **indent-blankline.nvim** - Indentation guides
- **nvim-web-devicons** - File icons
- **rainbow-delimiters.nvim** - Rainbow parentheses
- **todo-comments.nvim** - TODO highlighting
- **nvim-notify** - Enhanced notifications

**Example Specification**:
```lua
{
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
    })
    vim.cmd.colorscheme "catppuccin"
  end,
}
```

### editor.lua - Editor Enhancement Plugins

**Editor Features**:
- **telescope.nvim** - Fuzzy finder
- **nvim-treesitter** - Syntax highlighting
- **comment.nvim** - Smart commenting
- **nvim-autopairs** - Auto-closing brackets
- **gitsigns.nvim** - Git integration
- **nvim-surround** - Surround text objects
- **retrail.nvim** - Whitespace management
- **splitjoin.vim** - Split/join code constructs
- **editorconfig-vim** - EditorConfig support
- **nvim-ts-context-commentstring** - Context-aware commenting

**Example with Event-based Loading**:
```lua
{
  "nvim-telescope/telescope.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("plugins.config.telescope")
  end,
}
```

### lsp.lua - LSP and Completion

**LSP Ecosystem**:
- **nvim-lspconfig** - LSP configuration
- **nvim-cmp** - Completion engine
- **mason.nvim** - LSP installer
- **nvim-dap** - Debug Adapter Protocol
- **nvim-dap-ui** - Debug UI
- **nvim-dap-virtual-text** - Debug virtual text

### tools.lua - Development Tools

**Development Tools**:
- **vim-fugitive** - Git interface
- **diffview.nvim** - Git diff viewer
- **vim-surround** - Surround text objects
- **lazy.nvim** - Plugin management

### lang/ - Language-Specific Plugins

Each language has its own specification file:

#### go.lua
```lua
return {
  {
    "fatih/vim-go",
    ft = "go",
    config = function()
      require("plugins.config.lang.go")
    end,
  },
}
```

#### terraform.lua
```lua
return {
  {
    "hashivim/vim-terraform",
    ft = "terraform",
    config = function()
      require("plugins.config.lang.terraform")
    end,
  },
}
```

## Plugin Configurations (`config/`)

Plugin configurations define how each plugin should behave and are loaded only when the plugin is activated.

### Major Plugin Configurations

#### telescope.lua - File Finder and Search

**Key Features**:
- File finding with smart ignore patterns
- Live grep with advanced options
- LSP integration (definitions, references, symbols)
- Git integration (commits, branches, status)
- Command-line safety checks

**Configuration Highlights**:
```lua
require("telescope").setup({
  defaults = {
    mappings = {
      i = {
        ["<C-n>"] = actions.move_selection_next,
        ["<C-p>"] = actions.move_selection_previous,
        ["<esc>"] = actions.close,
      },
    },
    file_ignore_patterns = {
      "node_modules/.*",
      "%.git/.*",
      "%.DS_Store",
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
    },
  },
})
```

#### treesitter.lua - Syntax Highlighting and Text Objects

**Advanced Features**:
- Comprehensive text objects (functions, classes, parameters, etc.)
- Text object swapping and movement
- LSP interop for enhanced navigation
- Context display for current scope

**Text Objects Configuration**:
```lua
textobjects = {
  select = {
    enable = true,
    lookahead = true,
    keymaps = {
      ["af"] = "@function.outer",
      ["if"] = "@function.inner",
      ["ac"] = "@class.outer",
      ["ic"] = "@class.inner",
      ["aa"] = "@parameter.outer",
      ["ia"] = "@parameter.inner",
    },
  },
  swap = {
    enable = true,
    swap_next = {
      ["<leader>a"] = "@parameter.inner",
    },
    swap_previous = {
      ["<leader>A"] = "@parameter.inner",
    },
  },
}
```

#### cmp.lua - Auto-completion

**Multi-source Completion**:
- Buffer text completion
- LSP completion
- Path completion
- Command-line completion

**Smart Keymap Handling**:
```lua
mapping = cmp.mapping.preset.insert({
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<CR>'] = cmp.mapping.confirm({ 
    behavior = cmp.ConfirmBehavior.Replace,
    select = false 
  }),
  ['<Tab>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    else
      fallback()
    end
  end, { "i", "s" }),
})
```

#### which-key.lua - Keymap Management

**Comprehensive Key Groups**:
- Leader key mappings with descriptions
- Plugin-specific keymap documentation
- Buffer-local mappings for languages
- Overlap prevention and conflict resolution

**Key Group Organization**:

##### 📁 **Buffer Operations** (`<leader>b`)
```lua
wk.add({
  { "<leader>b", group = "Buffer" },
  { "<leader>bn", "<cmd>bnext<cr>", desc = "Next buffer" },
  { "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous buffer" },
  { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
  { "<leader>bl", "<cmd>Telescope buffers<cr>", desc = "List buffers" },
})
```

##### 🔍 **Find/File Operations** (`<leader>f`)
```lua
wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
  { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
  { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
  { "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "Colorschemes" },
  { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep Word" },
  { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
})
```

##### 🌱 **Git Operations** (`<leader>g`)
```lua
wk.add({
  { "<leader>g", group = "Git" },
  { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
  { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
  { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
  { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git Diff View" },
  { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File History" },
  { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Current File History" },
  { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diff View" },
  { "<leader>gm", "<cmd>DiffviewOpen origin/main<cr>", desc = "Diff vs Main" },
  { "<leader>gM", "<cmd>DiffviewOpen origin/master<cr>", desc = "Diff vs Master" },
  { "<leader>gS", "<cmd>DiffviewOpen --staged<cr>", desc = "Staged Changes" },
})
```

**TreeSitter Text Object Integration**:
```lua
-- Movement objects documentation
wk.add({
  { "]", group = "Next" },
  { "]m", desc = "Next function start" },
  { "]M", desc = "Next function end" },
  { "]]", desc = "Next class start" },
  { "][", desc = "Next class end" },
  
  { "[", group = "Previous" },
  { "[m", desc = "Previous function start" },
  { "[M", desc = "Previous function end" },
  { "[[", desc = "Previous class start" },
  { "[]", desc = "Previous class end" },
})

-- Text objects documentation
wk.add({
  { "a", group = "Around", mode = { "o", "x" } },
  { "af", desc = "Function" },
  { "ac", desc = "Class" },
  { "ab", desc = "Block" },
  { "aa", desc = "Argument" },
  
  { "i", group = "Inside", mode = { "o", "x" } },
  { "if", desc = "Function" },
  { "ic", desc = "Class" },
  { "ib", desc = "Block" },
  { "ia", desc = "Argument" },
})
```

**Plugin Overlap Handling**:
The configuration properly handles intentional overlapping keymaps that are hierarchical:

```lua
-- These overlaps are expected and functional:
-- vim-surround: ys + motion vs yss (complete)
-- Comment.nvim: gc + motion vs gcc (complete) 
-- These appear as warnings in :checkhealth which-key but work correctly
```

**Usage Tips**:
- Wait for the popup to see all available options
- Use `<C-d>`/`<C-u>` to scroll through long lists
- Press `<Esc>` to cancel a key sequence
- Use `:checkhealth which-key` to verify configuration

**For Complete Keymap Reference**:
See the [Which-Key User Guide](../guides/which-key.md) for comprehensive keymap discovery and daily usage patterns.

#### dap.lua - Debug Adapter Protocol

**Complete Debugging Setup**:
- Go debugging with Delve
- DAP UI with automatic session management
- Virtual text for variable inspection
- Comprehensive debugging keymaps

**Debugging Keymaps**:
```lua
-- Function keys for debugging
map('n', '<F5>', dap.continue, 'Debug: Continue')
map('n', '<F10>', dap.step_over, 'Debug: Step Over')
map('n', '<F11>', dap.step_into, 'Debug: Step Into')
map('n', '<F12>', dap.step_out, 'Debug: Step Out')

-- Leader key debugging
map('n', '<leader>db', dap.toggle_breakpoint, 'Debug: Toggle Breakpoint')
map('n', '<leader>dr', dap.repl.open, 'Debug: Open REPL')
```

#### diffview.lua - Git Diff and History

**Advanced Git Workflows**:
- File diff view with custom layouts
- Git history exploration
- Staged changes review
- Custom commands for common workflows

**Core Commands and Keybindings**:

##### **Basic Operations**
```lua
-- Quick access keybindings (configured in which-key)
map('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', 'Git Diff View')
map('n', '<leader>gh', '<cmd>DiffviewFileHistory<cr>', 'File History')
map('n', '<leader>gH', '<cmd>DiffviewFileHistory %<cr>', 'Current File History')
map('n', '<leader>gq', '<cmd>DiffviewClose<cr>', 'Close Diff View')
map('n', '<leader>gS', '<cmd>DiffviewOpen --staged<cr>', 'Staged Changes')
```

##### **Branch Comparison**
```lua
-- Custom commands for common workflows
vim.api.nvim_create_user_command('DiffviewOpenMain', function()
  vim.cmd('DiffviewOpen origin/main')
end, { desc = 'Compare to origin/main' })

vim.api.nvim_create_user_command('DiffviewOpenMaster', function()
  vim.cmd('DiffviewOpen origin/master')
end, { desc = 'Compare to origin/master' })

-- Keybindings for quick access
map('n', '<leader>gm', '<cmd>DiffviewOpen origin/main<cr>', 'Diff vs Main')
map('n', '<leader>gM', '<cmd>DiffviewOpen origin/master<cr>', 'Diff vs Master')
```

**Interface Configuration**:

##### **File Panel Layout**
```lua
require('diffview').setup({
  diff_binaries = false,
  enhanced_diff_hl = false,
  git_cmd = { "git" },
  use_icons = true,
  
  view = {
    default = {
      layout = "diff2_horizontal",
      winbar_info = false,
    },
    merge_tool = {
      layout = "diff3_horizontal",
      disable_diagnostics = true,
    },
    file_history = {
      layout = "diff2_horizontal",
      winbar_info = false,
    },
  },
  
  file_panel = {
    listing_style = "tree",
    tree_options = {
      flatten_dirs = true,
      folder_statuses = "only_folded",
    },
    win_config = {
      position = "left",
      width = 35,
    },
  },
})
```

**Navigation Keymaps**:

##### **File Panel Navigation**
```lua
file_panel = {
  {
    "n",
    "j", "k", -- Navigation
    desc = "Navigate files"
  },
  {
    "n",
    "<cr>", "o", "l", -- Open diff
    desc = "Open file diff"
  },
  {
    "n",
    "<tab>", "<s-tab>", -- Cycle files
    desc = "Next/Previous file"
  },
  {
    "n",
    "-", -- Stage/unstage
    desc = "Stage/unstage file"
  },
  {
    "n",
    "S", "U", -- Stage/unstage all
    desc = "Stage/Unstage all"
  },
  {
    "n",
    "i", -- Toggle view
    desc = "Toggle tree/list view"
  },
}
```

##### **Merge Conflict Resolution**
```lua
diff_view = {
  {
    "n",
    "<leader>co", actions.conflict_choose("ours"),
    desc = "Choose Ours (local)"
  },
  {
    "n",
    "<leader>ct", actions.conflict_choose("theirs"),
    desc = "Choose Theirs (remote)"
  },
  {
    "n",
    "<leader>cb", actions.conflict_choose("base"),
    desc = "Choose Base (ancestor)"
  },
  {
    "n",
    "<leader>ca", actions.conflict_choose("all"),
    desc = "Choose All (both)"
  },
  {
    "n",
    "dx", actions.conflict_choose("none"),
    desc = "Delete conflict region"
  },
  {
    "n",
    "]x", actions.next_conflict,
    desc = "Next conflict"
  },
  {
    "n",
    "[x", actions.prev_conflict,
    desc = "Previous conflict"
  },
}
```

**Common Workflows**:

1. **Reviewing Changes**: `<leader>gd` → Navigate with `<Tab>` → Stage with `-`
2. **Exploring History**: `<leader>gh` → Select commit → View with `<CR>`
3. **Merge Conflicts**: `]x`/`[x` to navigate → `<leader>co`/`<leader>ct` to resolve
4. **Code Review**: `:DiffviewOpen pr-branch..main` → Review systematically

**Integration with Gitsigns**:
- Gitsigns provides inline change indicators
- Diffview provides comprehensive diff viewing
- Both use `<leader>g` keymap group for consistency
- Seamless workflow: gitsigns for quick changes, diffview for detailed review

**For Complete Usage Examples**:
See the [Diffview User Guide](../guides/diffview.md) for comprehensive workflows and daily usage patterns.

### Language-Specific Configurations (`config/lang/`)

#### terraform.lua - Infrastructure as Code

**Terraform Workflow Integration**:
```lua
-- Buffer-local keymaps for Terraform
vim.api.nvim_create_autocmd("FileType", {
  pattern = "terraform",
  callback = function()
    local map = require('core.utils').map
    map('n', '<leader>ti', ':!terraform init<CR>', 'Terraform: Init')
    map('n', '<leader>tp', ':!terraform plan<CR>', 'Terraform: Plan')
    map('n', '<leader>ta', ':!terraform apply<CR>', 'Terraform: Apply')
    map('n', '<leader>td', ':!terraform destroy<CR>', 'Terraform: Destroy')
  end,
})
```

#### python.lua - Python Development

**Complete Python Workflow**:
- Virtual environment detection
- Testing framework integration (pytest, unittest)
- Code formatting (black, isort)
- Linting (flake8, pylint)
- REPL integration

#### rust.lua - Systems Programming

**Rust Development Features**:
- Cargo integration
- Error lens and diagnostics
- Rust analyzer setup
- Testing and benchmarking support

#### puppet.lua - Configuration Management

**Puppet Development Environment**:
- Puppet-lint integration
- Syntax validation
- Catalog compilation testing
- Auto-fix capabilities

#### go.lua - Go Development

**Go Language Support**:
- File alternation (test ↔ implementation)
- vim-go integration
- Buffer-local Go commands
- Test running and debugging

## Lazy Loading Strategies

### Event-based Loading
```lua
{
  "plugin-name",
  event = "BufReadPre",  -- Load when reading a buffer
  -- or
  event = "VeryLazy",    -- Load after startup
}
```

### Command-based Loading
```lua
{
  "plugin-name",
  cmd = { "CommandName", "AnotherCommand" },
}
```

### Filetype-based Loading
```lua
{
  "plugin-name",
  ft = { "lua", "vim" },  -- Load for specific filetypes
}
```

### Key-based Loading
```lua
{
  "plugin-name",
  keys = {
    { "<leader>p", "<cmd>PluginCommand<cr>", desc = "Plugin Command" },
  },
}
```

## User Override Integration

The plugin system integrates with the user override system:

### Plugin Specification Overrides
Users can override plugin specifications in `user/overrides/plugins/`:

```lua
-- user/overrides/plugins/telescope.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "vertical",  -- Override layout
      },
    },
  },
}
```

### Plugin Configuration Overrides
Users can override entire plugin configurations:

```lua
-- user/config.lua
return {
  plugins = {
    config_overrides = {
      telescope = function()
        -- Custom telescope configuration
        require("telescope").setup({
          -- Custom settings
        })
      end,
    },
  },
}
```

## Plugin Management Commands

The system provides commands for plugin management:

### Lazy.nvim Commands
The plugin system uses lazy.nvim for plugin management:

```vim
:Lazy              " Open lazy.nvim UI
:Lazy install      " Install missing plugins
:Lazy update       " Update all plugins
:Lazy clean        " Remove unused plugins
:Lazy sync         " Install missing + update + clean
:Lazy profile      " Profile startup time
:Lazy log          " Show recent updates
:Lazy check        " Check for updates
:Lazy restore      " Restore plugins to lockfile state
```

## Performance Optimization

### Startup Time Optimization
- Plugins load only when needed
- Heavy plugins use lazy loading
- Dependencies are optimized
- Minimal impact on startup

### Runtime Performance
- Efficient event handling
- Smart dependency management
- Optimized configurations
- Memory usage monitoring

## Troubleshooting

### Common Issues

1. **Plugin Not Loading**:
   ```lua
   -- Check if plugin is installed
   :Lazy
   -- Check loading conditions
   :lua print(vim.inspect(require("lazy.core.config").plugins["plugin-name"]))
   ```

2. **Configuration Errors**:
   ```lua
   -- Check plugin configuration
   :checkhealth lazy
   -- Debug specific plugin
   :lua require("plugins.config.plugin-name")
   ```

3. **Keymap Conflicts**:
   ```lua
   -- Check keymap conflicts
   :checkhealth which-key
   -- View all keymaps
   :Telescope keymaps
   ```

### Debug Mode
Enable debug mode for troubleshooting:
```lua
-- In user/config.lua
return {
  plugins = {
    debug = true,  -- Enable plugin debug mode
  },
}
```

### Health Checks
Run health checks for plugins:
```vim
:checkhealth lazy       " Check lazy.nvim
:checkhealth telescope  " Check telescope
:checkhealth treesitter " Check treesitter
:checkhealth lsp        " Check LSP setup
```

## Best Practices

1. **Lazy Loading**: Always specify appropriate loading conditions
2. **Dependencies**: Declare dependencies explicitly
3. **Configuration**: Keep configurations in separate files
4. **User Overrides**: Use the override system instead of modifying core files
5. **Performance**: Monitor startup time with `:Lazy profile`
6. **Updates**: Regularly update plugins and check for breaking changes
7. **Testing**: Test configurations after major changes 