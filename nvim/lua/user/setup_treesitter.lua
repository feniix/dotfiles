local M = {}

-- Helper function to install parsers that might have issues with the regular install process
M.install_parsers = function()
  local ok, install = pcall(require, 'nvim-treesitter.install')
  if not ok then
    vim.notify("nvim-treesitter.install not found. Cannot install parsers.", vim.log.levels.ERROR)
    return
  end

  -- Save current compiler
  local current_compile_command = install.compilers[1]
  
  -- Set compiler to clang for better compatibility
  if vim.fn.executable('clang') == 1 then
    install.compilers = { 'clang', 'gcc', 'cc' }
  end
  
  -- Force install vim parser (which often has issues)
  M.install_vim_parser()
  
  -- Restore compiler
  install.compilers[1] = current_compile_command
end

-- Function to manually install the vim parser if it fails with the standard process
M.install_vim_parser = function()
  local vim_parser_installed = false
  local parsers_dir = vim.fn.stdpath('data') .. '/parser'
  
  -- Security check: validate parsers_dir path
  if not parsers_dir or parsers_dir == '' or string.find(parsers_dir, '%.%.') then
    vim.notify("Invalid parser directory path", vim.log.levels.ERROR)
    return
  end
  
  -- Check if the vim parser already exists
  if vim.fn.filereadable(parsers_dir .. '/vim.so') == 1 then
    vim_parser_installed = true
  end
  
  if not vim_parser_installed then
    -- Create temporary directory with validation
    local temp_dir = vim.fn.stdpath('cache') .. '/treesitter-vim'
    
    -- Security check: validate temp_dir path
    if not temp_dir or temp_dir == '' or string.find(temp_dir, '%.%.') then
      vim.notify("Invalid temporary directory path", vim.log.levels.ERROR)
      return
    end
    
    -- Remove the directory if it already exists
    if vim.fn.isdirectory(temp_dir) == 1 then
      vim.fn.delete(temp_dir, 'rf')
    end
    
    vim.fn.mkdir(temp_dir, 'p')
    
    -- Security: Use safer git clone with explicit options
    local git_cmd = {
      'git', 'clone', '--depth=1', '--single-branch',
      'https://github.com/neovim/tree-sitter-vim.git',
      temp_dir
    }
    
    vim.notify("Installing vim parser manually...", vim.log.levels.INFO)
    local git_result = vim.system(git_cmd, { capture_output = true, timeout = 30000 })
    
    if git_result.code ~= 0 then
      vim.notify("Failed to clone tree-sitter-vim: " .. (git_result.stderr or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    
    -- Set up directories with validation
    if not vim.fn.isdirectory(parsers_dir) then
      vim.fn.mkdir(parsers_dir, 'p')
    end
    
    -- Security: Use safer compilation with explicit paths and flags
    local compile_cmd
    if vim.fn.has('mac') == 1 then
      compile_cmd = {
        'cc', '-o', parsers_dir .. '/vim.so',
        '-I' .. temp_dir .. '/src',
        temp_dir .. '/src/parser.c',
        '-shared', '-Os', '-lstdc++', '-fPIC'
      }
    else
      compile_cmd = {
        'cc', '-o', parsers_dir .. '/vim.so',
        '-I' .. temp_dir .. '/src', 
        temp_dir .. '/src/parser.c',
        '-shared', '-Os', '-lstdc++', '-fPIC'
      }
    end
    
    local compile_result = vim.system(compile_cmd, { 
      capture_output = true, 
      timeout = 30000,
      cwd = temp_dir 
    })
    
    if compile_result.code ~= 0 then
      vim.notify("Failed to compile vim parser: " .. (compile_result.stderr or "Unknown error"), vim.log.levels.ERROR)
      -- Clean up on failure
      vim.fn.delete(temp_dir, 'rf')
      return
    end
    
    -- Clean up temporary directory
    vim.fn.delete(temp_dir, 'rf')
    
    vim.notify("Successfully installed vim parser manually", vim.log.levels.INFO)
  end
end

return M