# Language Support Documentation

The Neovim configuration provides comprehensive support for multiple programming languages through dedicated plugins and configurations. Each language has its own specification and configuration files, ensuring optimal development experience.

## Architecture Overview

```
plugins/
├── specs/lang/          # Language plugin specifications
│   ├── go.lua          # Go plugins
│   ├── python.lua      # Python plugins
│   ├── rust.lua        # Rust plugins
│   ├── terraform.lua   # Terraform plugins
│   └── puppet.lua      # Puppet plugins
└── config/lang/         # Language configurations
    ├── go.lua          # Go development setup
    ├── python.lua      # Python development setup
    ├── rust.lua        # Rust development setup
    ├── terraform.lua   # Infrastructure as Code
    └── puppet.lua      # Configuration management
```

## Supported Languages

| Language | LSP | Linting | Formatting | Testing | Debugging | Build Tools |
|----------|-----|---------|------------|---------|-----------|-------------|
| **Go** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Python** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Rust** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Terraform** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Puppet** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |

## Go Development Environment

### Plugin Specification (`specs/lang/go.lua`)

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

### Configuration (`config/lang/go.lua`)

**Key Features**:
- File alternation between test and implementation files
- vim-go integration with enhanced features
- Buffer-local keymaps for Go operations
- Automatic Go commands setup

**Buffer-Local Keymaps**:
```lua
-- Activated when entering Go files
map('n', '<leader>gat', ':GoAlternateTest<CR>', 'Go: Alternate to test file')
map('n', '<leader>gas', ':GoAlternateSource<CR>', 'Go: Alternate to source file')
map('n', '<leader>gr', ':GoRun<CR>', 'Go: Run')
map('n', '<leader>gt', ':GoTest<CR>', 'Go: Test')
map('n', '<leader>gb', ':GoBuild<CR>', 'Go: Build')
map('n', '<leader>gc', ':GoCoverageToggle<CR>', 'Go: Toggle coverage')
```

**Vim-Go Configuration**:
```lua
-- Enhanced Go development features
vim.g.go_fmt_command = "goimports"           -- Auto-import on save
vim.g.go_auto_type_info = 1                  -- Show type info
vim.g.go_highlight_types = 1                 -- Syntax highlighting
vim.g.go_highlight_fields = 1
vim.g.go_highlight_functions = 1
vim.g.go_highlight_function_calls = 1
vim.g.go_highlight_operators = 1
vim.g.go_highlight_extra_types = 1
```

**Debugging Integration**:
- Delve debugger support through DAP
- Breakpoint management
- Variable inspection
- Step-through debugging

## Python Development Environment

### Plugin Specification (`specs/lang/python.lua`)

```lua
return {
  {
    "psf/black",
    ft = "python",
    build = ":BlackUpgrade",
  },
  -- Additional Python plugins...
}
```

### Configuration (`config/lang/python.lua`)

**Complete Python Workflow**:
- Virtual environment detection and management
- Multiple testing frameworks (pytest, unittest, nose2)
- Code formatting (black, autopep8, yapf)
- Import sorting (isort)
- Linting (flake8, pylint, mypy)
- REPL integration (ipython, python)

**Key Features**:

#### Virtual Environment Detection
```lua
-- Automatically detect and activate virtual environments
local function detect_venv()
  local venv_paths = {
    vim.fn.getcwd() .. "/venv",
    vim.fn.getcwd() .. "/.venv",
    vim.fn.getcwd() .. "/env",
    os.getenv("VIRTUAL_ENV"),
  }
  
  for _, path in ipairs(venv_paths) do
    if path and vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return nil
end
```

#### Testing Framework Integration
```lua
-- Buffer-local keymaps for Python testing
map('n', '<leader>pt', function()
  -- Intelligent test runner selection
  if vim.fn.filereadable('pytest.ini') == 1 or vim.fn.filereadable('pyproject.toml') == 1 then
    vim.cmd('!python -m pytest ' .. vim.fn.expand('%'))
  else
    vim.cmd('!python -m unittest ' .. vim.fn.expand('%:r'))
  end
end, 'Python: Run tests')

map('n', '<leader>pT', ':!python -m pytest<CR>', 'Python: Run all tests')
map('n', '<leader>pc', ':!python -m pytest --cov<CR>', 'Python: Run with coverage')
```

#### Code Formatting
```lua
-- Multiple formatter support
map('n', '<leader>pf', function()
  local formatters = { 'black', 'autopep8', 'yapf' }
  for _, formatter in ipairs(formatters) do
    if vim.fn.executable(formatter) == 1 then
      vim.cmd('!' .. formatter .. ' ' .. vim.fn.expand('%'))
      vim.cmd('edit')  -- Reload file
      break
    end
  end
end, 'Python: Format file')

map('n', '<leader>pi', ':!isort %<CR>', 'Python: Sort imports')
```

#### REPL Integration
```lua
-- Enhanced Python REPL
map('n', '<leader>pr', function()
  local repl = vim.fn.executable('ipython') == 1 and 'ipython' or 'python'
  vim.cmd('split | terminal ' .. repl)
end, 'Python: Open REPL')

map('v', '<leader>ps', function()
  -- Send selection to REPL
  local selected_text = require('core.utils').get_visual_selection()
  -- Send to terminal...
end, 'Python: Send selection to REPL')
```

## Rust Development Environment

### Plugin Specification (`specs/lang/rust.lua`)

```lua
return {
  {
    "rust-lang/rust.vim",
    ft = "rust",
    config = function()
      require("plugins.config.lang.rust")
    end,
  },
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
```

### Configuration (`config/lang/rust.lua`)

**Rust Development Features**:
- Cargo integration for build, test, and run
- Rust analyzer LSP with enhanced features
- Error lens and advanced diagnostics
- Crate management and documentation
- Clippy integration for linting

**Key Features**:

#### Cargo Integration
```lua
-- Comprehensive Cargo commands
map('n', '<leader>rr', ':!cargo run<CR>', 'Rust: Run')
map('n', '<leader>rb', ':!cargo build<CR>', 'Rust: Build')
map('n', '<leader>rt', ':!cargo test<CR>', 'Rust: Test')
map('n', '<leader>rc', ':!cargo check<CR>', 'Rust: Check')
map('n', '<leader>rC', ':!cargo clippy<CR>', 'Rust: Clippy')
map('n', '<leader>rd', ':!cargo doc --open<CR>', 'Rust: Open docs')
map('n', '<leader>ru', ':!cargo update<CR>', 'Rust: Update dependencies')
```

#### Advanced LSP Features
```lua
-- Rust-specific LSP enhancements
require('rust-tools').setup({
  server = {
    on_attach = function(client, bufnr)
      -- Enhanced LSP keymaps for Rust
      map('n', '<leader>rh', require('rust-tools').hover_actions.hover_actions, 'Rust: Hover actions')
      map('n', '<leader>ra', require('rust-tools').code_action_group.code_action_group, 'Rust: Code actions')
    end,
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        procMacro = {
          enable = true,
        },
        diagnostics = {
          enable = true,
          enableExperimental = true,
        },
      },
    },
  },
  tools = {
    autoSetHints = true,
    inlay_hints = {
      show_parameter_hints = true,
      parameter_hints_prefix = "<- ",
      other_hints_prefix = "=> ",
    },
  },
})
```

#### Crate Management
```lua
-- Crate.io integration for dependency management
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "Cargo.toml",
  callback = function()
    map('n', '<leader>rca', ':!cargo add ', 'Rust: Add crate')
    map('n', '<leader>rcr', ':!cargo remove ', 'Rust: Remove crate')
    map('n', '<leader>rcs', ':!cargo search ', 'Rust: Search crates')
  end,
})
```

## Terraform - Infrastructure as Code

### Plugin Specification (`specs/lang/terraform.lua`)

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

### Configuration (`config/lang/terraform.lua`)

**Terraform Workflow Integration**:
- Complete Terraform lifecycle management
- HCL syntax highlighting and validation
- Terraform LSP integration
- Plan visualization and validation
- State management commands

**Key Features**:

#### Terraform Lifecycle Commands
```lua
-- Complete Terraform workflow
map('n', '<leader>ti', ':!terraform init<CR>', 'Terraform: Init')
map('n', '<leader>tp', ':!terraform plan<CR>', 'Terraform: Plan')
map('n', '<leader>ta', ':!terraform apply<CR>', 'Terraform: Apply')
map('n', '<leader>td', ':!terraform destroy<CR>', 'Terraform: Destroy')
map('n', '<leader>tf', ':!terraform fmt<CR>', 'Terraform: Format')
map('n', '<leader>tv', ':!terraform validate<CR>', 'Terraform: Validate')
```

#### Advanced Terraform Operations
```lua
-- State management and planning
map('n', '<leader>tpl', ':!terraform plan -out=tfplan<CR>', 'Terraform: Plan with output')
map('n', '<leader>tsh', ':!terraform show<CR>', 'Terraform: Show current state')
map('n', '<leader>tst', ':!terraform state list<CR>', 'Terraform: List state')
map('n', '<leader>tout', ':!terraform output<CR>', 'Terraform: Show outputs')

-- Workspace management
map('n', '<leader>tws', ':!terraform workspace show<CR>', 'Terraform: Show workspace')
map('n', '<leader>twl', ':!terraform workspace list<CR>', 'Terraform: List workspaces')
map('n', '<leader>twn', ':!terraform workspace new ', 'Terraform: New workspace')
```

#### Validation and Linting
```lua
-- Automatic validation and formatting
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.tf",
  callback = function()
    -- Auto-format on save (configurable)
    if vim.g.terraform_fmt_on_save then
      vim.cmd("silent! !terraform fmt %")
      vim.cmd("edit")
    end
  end,
})

-- Validation on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.tf",
  callback = function()
    vim.cmd("!terraform validate")
  end,
})
```

## Puppet - Configuration Management

### Plugin Specification (`specs/lang/puppet.lua`)

```lua
return {
  {
    "rodjek/vim-puppet",
    ft = "puppet",
    config = function()
      require("plugins.config.lang.puppet")
    end,
  },
}
```

### Configuration (`config/lang/puppet.lua`)

**Puppet Development Environment**:
- Puppet-lint integration with quickfix
- Syntax validation with puppet parser
- Catalog compilation testing
- Auto-fix capabilities for common issues

**Key Features**:

#### Puppet-Lint Integration
```lua
-- Comprehensive Puppet linting
map('n', '<leader>pl', function()
  -- Run puppet-lint with quickfix integration
  vim.cmd('compiler puppet-lint')
  vim.cmd('make ' .. vim.fn.expand('%'))
  vim.cmd('copen')
end, 'Puppet: Lint current file')

map('n', '<leader>pf', ':!puppet-lint --fix %<CR>', 'Puppet: Auto-fix lint issues')
map('n', '<leader>pla', ':!puppet-lint .<CR>', 'Puppet: Lint all files')
```

#### Syntax Validation
```lua
-- Puppet parser validation
map('n', '<leader>pv', function()
  local file = vim.fn.expand('%')
  local result = vim.fn.system('puppet parser validate ' .. file)
  if vim.v.shell_error == 0 then
    print('✓ Puppet syntax valid')
  else
    print('✗ Puppet syntax error: ' .. result)
  end
end, 'Puppet: Validate syntax')
```

#### Catalog Testing
```lua
-- Puppet catalog compilation and testing
map('n', '<leader>pc', function()
  local manifest = vim.fn.expand('%:p')
  vim.cmd('!puppet apply --noop --verbose ' .. manifest)
end, 'Puppet: Compile catalog (dry-run)')

map('n', '<leader>pa', function()
  local manifest = vim.fn.expand('%:p')
  vim.cmd('!puppet apply ' .. manifest)
end, 'Puppet: Apply manifest')
```

#### Enhanced Puppet Features
```lua
-- Puppet-specific autocommands
vim.api.nvim_create_autocmd("FileType", {
  pattern = "puppet",
  callback = function()
    -- Puppet-specific settings
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
    
    -- Enhanced syntax highlighting for Puppet keywords
    vim.cmd([[
      syntax keyword puppetKeyword ensure present absent file directory service package
      syntax keyword puppetKeyword notify require before subscribe
      syntax keyword puppetFunction template inline_template
      highlight link puppetKeyword Keyword
      highlight link puppetFunction Function
    ]])
  end,
})
```

## Language Server Protocol (LSP) Integration

### Universal LSP Setup

All supported languages integrate with Neovim's built-in LSP:

```lua
-- Common LSP configuration for all languages
local lsp_config = {
  on_attach = function(client, bufnr)
    -- Universal LSP keymaps
    local map = require('core.utils').map
    
    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gr', vim.lsp.buf.references, 'Show references')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('n', 'K', vim.lsp.buf.hover, 'Show hover info')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
    map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code actions')
    map('n', '<leader>f', vim.lsp.buf.format, 'Format buffer')
  end,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
}
```

### Language-Specific LSP Servers

| Language | LSP Server | Installation | Configuration |
|----------|------------|--------------|---------------|
| **Go** | gopls | `go install golang.org/x/tools/gopls@latest` | Auto-configured |
| **Python** | pylsp/pyright | `pip install python-lsp-server` | Virtual env aware |
| **Rust** | rust-analyzer | `rustup component add rust-analyzer` | Cargo integration |
| **Terraform** | terraform-ls | `terraform-ls` binary | HCL support |
| **Puppet** | puppet-editor-services | Puppet extension | Manifest validation |

## Testing Integration

### Framework Support by Language

#### Go Testing
```lua
-- Go test integration
map('n', '<leader>gt', ':GoTest<CR>', 'Run Go tests')
map('n', '<leader>gT', ':GoTestFunc<CR>', 'Run test under cursor')
map('n', '<leader>gc', ':GoCoverageToggle<CR>', 'Toggle test coverage')
map('n', '<leader>gb', ':GoBench<CR>', 'Run benchmarks')
```

#### Python Testing
```lua
-- Multi-framework Python testing
map('n', '<leader>pt', function()
  if vim.fn.filereadable('pytest.ini') == 1 then
    vim.cmd('!python -m pytest ' .. vim.fn.expand('%'))
  elseif vim.fn.filereadable('setup.cfg') == 1 then
    vim.cmd('!python -m unittest discover')
  else
    vim.cmd('!python -m unittest ' .. vim.fn.expand('%:r'))
  end
end, 'Run Python tests')
```

#### Rust Testing
```lua
-- Cargo test integration
map('n', '<leader>rt', ':!cargo test<CR>', 'Run Rust tests')
map('n', '<leader>rT', function()
  local word = vim.fn.expand('<cword>')
  vim.cmd('!cargo test ' .. word)
end, 'Run specific test')
```

## Debugging Support

### Debug Adapter Protocol (DAP) Integration

Debugging support is provided through the DAP system:

#### Go Debugging (Delve)
```lua
-- Go debugging with Delve
require('dap-go').setup()

-- Go-specific debug keymaps
map('n', '<leader>gd', function()
  require('dap').continue()
end, 'Start/Continue Go debugging')
```

#### Python Debugging
```lua
-- Python debugging setup
require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')

-- Python-specific debug configurations
require('dap').configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = "Launch file",
    program = "${file}",
    pythonPath = function()
      return '/usr/bin/python3'
    end,
  },
}
```

## Performance Optimization

### Language-Specific Optimizations

#### Lazy Loading by File Type
```lua
-- Plugins load only for specific file types
{
  "rust-lang/rust.vim",
  ft = "rust",  -- Only load for Rust files
}
```

#### Conditional LSP Loading
```lua
-- LSP servers start only when needed
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.lsp.start({
      name = "rust-analyzer",
      cmd = { "rust-analyzer" },
      root_dir = vim.fs.dirname(vim.fs.find({"Cargo.toml"}, { upward = true })[1]),
    })
  end,
})
```

## User Customization

### Language-Specific Overrides

Users can customize language support through the user override system:

```lua
-- user/config.lua
return {
  plugins = {
    config_overrides = {
      ["lang/python"] = function()
        -- Custom Python configuration
        vim.g.python_formatter = "yapf"  -- Use yapf instead of black
        vim.g.python_linter = "pylint"   -- Use pylint instead of flake8
      end,
    },
  },
  
  core = {
    autocmds = {
      {
        event = "FileType",
        pattern = "go",
        callback = function()
          -- Custom Go settings
          vim.opt_local.tabstop = 8  -- Go standard tab width
          vim.opt_local.expandtab = false
        end,
      },
    },
  },
}
```

### Adding New Languages

To add support for a new language:

1. **Create Plugin Specification** (`plugins/specs/lang/newlang.lua`):
```lua
return {
  {
    "author/newlang-plugin",
    ft = "newlang",
    config = function()
      require("plugins.config.lang.newlang")
    end,
  },
}
```

2. **Create Configuration** (`plugins/config/lang/newlang.lua`):
```lua
-- New language configuration
local M = {}

function M.setup()
  -- Language-specific settings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "newlang",
    callback = function()
      -- File type settings
      vim.opt_local.shiftwidth = 4
      
      -- Language-specific keymaps
      local map = require('core.utils').map
      map('n', '<leader>nr', ':!newlang run %<CR>', 'NewLang: Run')
      map('n', '<leader>nt', ':!newlang test<CR>', 'NewLang: Test')
    end,
  })
end

M.setup()
return M
```

3. **Update Plugin Loader** (`plugins/init.lua`):
```lua
-- Add to plugin specifications loading
vim.list_extend(plugin_specs, require("plugins.specs.lang.newlang"))
```

## Best Practices

1. **File Type Detection**: Ensure proper file type detection for language features
2. **Buffer-Local Settings**: Use buffer-local settings and keymaps for language-specific features
3. **Tool Availability**: Check for tool availability before executing commands
4. **Virtual Environments**: Respect language-specific environment management
5. **Performance**: Use lazy loading for language-specific plugins
6. **Consistency**: Follow established patterns across all language configurations
7. **Documentation**: Document language-specific features and keymaps 