-- Rust language configuration for systems programming
-- Enhanced configuration for Rust development workflow

local M = {}

function M.setup()
  -- One group for every autocmd this module creates, cleared on each
  -- setup() so re-running it does not stack duplicates.
  local augroup = vim.api.nvim_create_augroup("RustConfig", { clear = true })

  -- Set up Rust-specific options
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "rust",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      
      -- Set buffer options following Rust conventions
      vim.bo[buf].tabstop = 4
      vim.bo[buf].shiftwidth = 4
      vim.bo[buf].softtabstop = 4
      vim.bo[buf].expandtab = true
      vim.bo[buf].textwidth = 100  -- Rust line length convention
      vim.wo.colorcolumn = "100"  -- Window-local option, not buffer-local
      
      -- Set local keymaps
      M.setup_rust_keymaps(buf)
    end,
    desc = "Rust buffer configuration",
  })

  -- Format on save is opt-in: set vim.g.rust_format_on_save = true
  if vim.g.rust_format_on_save == nil then
    vim.g.rust_format_on_save = false
  end

  -- Set up autocommands for Rust files
  M.setup_autocmds(augroup)
  
  -- Set up custom commands
  M.setup_commands()
end

function M.setup_rust_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, buffer = buf }
  
  -- Rust cargo commands
  keymap('n', '<leader>rb', ':RustBuild<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo build' }))
  keymap('n', '<leader>rr', ':RustRun<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo run' }))
  keymap('n', '<leader>rt', ':RustTest<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo test' }))
  keymap('n', '<leader>rc', ':RustCheck<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo check' }))
  keymap('n', '<leader>rC', ':RustClippy<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo clippy' }))
  
  -- Rust formatting and documentation
  keymap('n', '<leader>rf', ':RustFormat<CR>', vim.tbl_extend('force', opts, { desc = 'Format Rust (rustfmt)' }))
  keymap('n', '<leader>rd', ':RustDoc<CR>', vim.tbl_extend('force', opts, { desc = 'Cargo doc' }))
  keymap('n', '<leader>ro', ':RustDocOpen<CR>', vim.tbl_extend('force', opts, { desc = 'Open docs' }))
  
  -- Rust development helpers
  keymap('n', '<leader>re', ':RustExpand<CR>', vim.tbl_extend('force', opts, { desc = 'Expand macros' }))
  keymap('n', '<leader>rE', ':RustEmitAsm<CR>', vim.tbl_extend('force', opts, { desc = 'Emit assembly' }))
  keymap('n', '<leader>rL', ':RustEmitLlvm<CR>', vim.tbl_extend('force', opts, { desc = 'Emit LLVM IR' }))
  
  -- Debugging and profiling
  keymap('n', '<leader>rg', ':RustGdb<CR>', vim.tbl_extend('force', opts, { desc = 'Debug with GDB' }))
  keymap('n', '<leader>rp', ':RustPlay<CR>', vim.tbl_extend('force', opts, { desc = 'Rust playground' }))
end

function M.setup_autocmds(augroup)
  augroup = augroup or vim.api.nvim_create_augroup("RustConfig", { clear = true })
  
  -- Auto-format on save (optional)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "*.rs",
    callback = function()
      -- Compare explicitly: Vimscript's 0 is truthy in Lua.
      local enabled = vim.g.rust_format_on_save
      if enabled == true or enabled == 1 then
        M.format_rust()
      end
    end,
    desc = "Auto-format Rust files on save",
  })
  
  -- Set comment string for Rust files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "rust",
    callback = function()
      vim.bo.commentstring = "// %s"
    end,
    desc = "Set comment string for Rust files",
  })
end

function M.setup_commands()
  -- Cargo build commands
  vim.api.nvim_create_user_command('RustBuild', function()
    M.cargo_command('build')
  end, { desc = 'Run cargo build' })
  
  vim.api.nvim_create_user_command('RustRun', function()
    M.cargo_command('run')
  end, { desc = 'Run cargo run' })
  
  vim.api.nvim_create_user_command('RustTest', function()
    M.cargo_command('test')
  end, { desc = 'Run cargo test' })
  
  vim.api.nvim_create_user_command('RustCheck', function()
    M.cargo_command('check')
  end, { desc = 'Run cargo check' })
  
  vim.api.nvim_create_user_command('RustClippy', function()
    M.cargo_command('clippy')
  end, { desc = 'Run cargo clippy' })
  
  -- Formatting and documentation
  vim.api.nvim_create_user_command('RustFormat', function()
    M.format_rust()
  end, { desc = 'Format Rust file with rustfmt' })
  
  vim.api.nvim_create_user_command('RustDoc', function()
    M.cargo_command('doc')
  end, { desc = 'Generate documentation with cargo doc' })
  
  vim.api.nvim_create_user_command('RustDocOpen', function()
    M.cargo_command('doc --open')
  end, { desc = 'Generate and open documentation' })
  
  -- Advanced commands
  vim.api.nvim_create_user_command('RustExpand', function()
    M.rust_expand()
  end, { desc = 'Expand Rust macros' })
  
  vim.api.nvim_create_user_command('RustEmitAsm', function()
    M.emit_asm()
  end, { desc = 'Emit assembly code' })
  
  vim.api.nvim_create_user_command('RustEmitLlvm', function()
    M.emit_llvm()
  end, { desc = 'Emit LLVM IR' })
  
  vim.api.nvim_create_user_command('RustGdb', function()
    M.debug_rust()
  end, { desc = 'Debug Rust with GDB' })
  
  vim.api.nvim_create_user_command('RustPlay', function()
    M.rust_playground()
  end, { desc = 'Send to Rust playground' })
end

-- Run cargo commands
function M.cargo_command(cmd)
  if vim.fn.executable('cargo') == 1 then
    local full_cmd = 'cargo ' .. cmd
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. full_cmd)
    vim.cmd('startinsert')
  else
    vim.notify("cargo not found. Install Rust toolchain", vim.log.levels.ERROR)
  end
end

-- Format Rust file with rustfmt
local function rust_format_context()
  local filename = vim.api.nvim_buf_get_name(0)
  local directory = filename ~= '' and vim.fs.dirname(filename) or vim.fn.getcwd()
  local manifest = vim.fs.find('Cargo.toml', { path = directory, upward = true })[1]
  if not manifest then
    -- Standalone buffers have no Cargo edition; allow modern Rust syntax.
    return directory, '2021'
  end
  if vim.fn.executable('cargo') == 1 then
    local ok, metadata = pcall(function()
      local result = vim.system({
        'cargo', 'metadata', '--no-deps', '--offline', '--format-version', '1',
        '--manifest-path', manifest,
      }, { text = true, cwd = directory }):wait()
      if result.code ~= 0 then return nil end
      return vim.json.decode(result.stdout)
    end)
    if ok and metadata then
      local edition, longest = nil, 0
      local file = vim.uv.fs_realpath(filename) or filename
      if file == '' then file = directory .. '/untitled.rs' end
      for _, package in ipairs(metadata.packages or {}) do
        local package_dir = vim.fs.dirname(package.manifest_path)
        local root = (vim.uv.fs_realpath(package_dir) or package_dir) .. '/'
        if file:sub(1, #root) == root and #root > longest then
          edition, longest = package.edition, #root
        end
      end
      if edition then return directory, edition end
    end
  end
  -- Do not guess when Cargo cannot resolve an inherited edition. Keep the
  -- buffer untouched and explain the failure instead of parsing TOML loosely.
  vim.notify('Cannot resolve Rust edition from ' .. manifest .. ' (cargo metadata failed)',
    vim.log.levels.ERROR)
  return nil
end

function M.format_rust()
  if vim.fn.executable('rustfmt') == 1 then
    local directory, edition = rust_format_context()
    if not directory then return end
    local command = { 'rustfmt', '--emit', 'stdout', '--edition', edition }
    local config = vim.fs.find({ '.rustfmt.toml', 'rustfmt.toml' }, {
      path = directory, upward = true,
    })[1]
    -- --config-path must name an existing config; a directory without one
    -- is an error, and rustfmt does not search its ancestors for this flag.
    if config then
      vim.list_extend(command, { '--config-path', config })
    end
    if require('plugins.config.format').buffer(
      command, 'rustfmt', { cwd = directory }
    ) then
      vim.notify("Rust file formatted with rustfmt", vim.log.levels.INFO)
    end
  else
    vim.notify("rustfmt not found. Install with: rustup component add rustfmt", vim.log.levels.ERROR)
  end
end

-- Expand macros
function M.rust_expand()
  if vim.fn.executable('cargo') == 1 then
    local cmd = 'cargo expand'
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("cargo not found. Install cargo-expand with: cargo install cargo-expand", vim.log.levels.ERROR)
  end
end

-- Emit assembly code
function M.emit_asm()
  if vim.fn.executable('cargo') == 1 then
    local cmd = 'cargo rustc -- --emit asm'
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("cargo not found", vim.log.levels.ERROR)
  end
end

-- Emit LLVM IR
function M.emit_llvm()
  if vim.fn.executable('cargo') == 1 then
    local cmd = 'cargo rustc -- --emit llvm-ir'
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("cargo not found", vim.log.levels.ERROR)
  end
end

-- Debug Rust with GDB
function M.debug_rust()
  if vim.fn.executable('rust-gdb') == 1 then
    local cmd = 'cargo build && rust-gdb target/debug/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
    
    -- Open terminal and run command
    vim.cmd('botright split')
    vim.cmd('resize 15')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  else
    vim.notify("rust-gdb not found", vim.log.levels.ERROR)
  end
end

-- Send to Rust playground
function M.rust_playground()
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  local encoded = vim.fn.system('echo ' .. vim.fn.shellescape(content) .. ' | base64')
  
  if vim.v.shell_error == 0 then
    local url = "https://play.rust-lang.org/?code=" .. vim.fn.substitute(encoded, '\n', '', 'g')
    if vim.fn.has('mac') == 1 then
      vim.fn.system('open ' .. vim.fn.shellescape(url))
    elseif vim.fn.has('unix') == 1 then
      vim.fn.system('xdg-open ' .. vim.fn.shellescape(url))
    else
      vim.notify("Open " .. url .. " in your browser", vim.log.levels.INFO)
    end
  else
    vim.notify("Failed to encode content for playground", vim.log.levels.ERROR)
  end
end

return M
