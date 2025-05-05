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
  
  -- Check if the vim parser already exists
  if vim.fn.filereadable(parsers_dir .. '/vim.so') == 1 then
    vim_parser_installed = true
  end
  
  if not vim_parser_installed then
    -- Create temporary directory
    local temp_dir = vim.fn.stdpath('cache') .. '/treesitter-vim'
    
    -- Remove the directory if it already exists
    if vim.fn.isdirectory(temp_dir) == 1 then
      vim.fn.delete(temp_dir, 'rf')
    end
    
    vim.fn.mkdir(temp_dir, 'p')
    
    -- Clone the repository
    local git_cmd = string.format('git clone https://github.com/neovim/tree-sitter-vim.git %s', temp_dir)
    vim.notify("Installing vim parser manually...", vim.log.levels.INFO)
    local git_result = vim.fn.system(git_cmd)
    
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to clone tree-sitter-vim: " .. git_result, vim.log.levels.ERROR)
      return
    end
    
    -- Set up directories
    vim.fn.mkdir(parsers_dir, 'p')
    
    -- Compile the parser
    local compile_cmd
    if vim.fn.has('mac') == 1 then
      compile_cmd = string.format('cd %s && cc -o %s/vim.so -I./src src/parser.c -shared -Os -lstdc++ -fPIC', 
                                 temp_dir, parsers_dir)
    else
      compile_cmd = string.format('cd %s && cc -o %s/vim.so -I./src src/parser.c -shared -Os -lstdc++ -fPIC', 
                                 temp_dir, parsers_dir)
    end
    
    local compile_result = vim.fn.system(compile_cmd)
    
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to compile vim parser: " .. compile_result, vim.log.levels.ERROR)
      return
    end
    
    -- Clean up temporary directory
    vim.fn.delete(temp_dir, 'rf')
    
    vim.notify("Successfully installed vim parser manually", vim.log.levels.INFO)
  end
end

return M