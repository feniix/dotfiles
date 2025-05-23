-- Telescope configuration
local M = {}

-- Helper function to check if telescope can be opened safely
local function can_open_telescope()
  -- Check if we're in command-line window (where telescope cannot be opened)
  local cmdline_win = vim.fn.getcmdwintype()
  if cmdline_win ~= '' then
    vim.notify("Cannot open telescope from command-line window. Press <Esc> first.", vim.log.levels.WARN)
    return false
  end
  
  -- Check if we're in a special buffer type that might cause issues
  local buftype = vim.bo.buftype
  if buftype == 'nofile' or buftype == 'terminal' then
    -- Allow telescope in most cases, but warn if there might be issues
    if buftype == 'terminal' then
      vim.notify("Opening telescope from terminal buffer", vim.log.levels.INFO)
    end
  end
  
  return true
end

-- Safe wrapper for telescope functions
local function safe_telescope_call(telescope_func, ...)
  if not can_open_telescope() then
    return
  end
  
  local ok, err = pcall(telescope_func, ...)
  if not ok then
    vim.notify("Telescope error: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup()
  local telescope_ok, telescope = pcall(require, 'telescope')
  if not telescope_ok then
    vim.notify("Telescope not available", vim.log.levels.WARN)
    return
  end

  local actions_ok, actions = pcall(require, 'telescope.actions')
  if not actions_ok then
    vim.notify("Telescope actions not available", vim.log.levels.WARN)
    return
  end

  -- Telescope configuration
  telescope.setup({
    defaults = {
      -- Default configuration for telescope
      prompt_prefix = "🔍 ",
      selection_caret = "➤ ",
      path_display = { "truncate" },
      file_ignore_patterns = {
        "%.git/",
        "node_modules/",
        "%.cache/",
        "build/",
        "dist/",
        "target/",
        "%.o$",
        "%.a$",
        "%.out$",
        "%.class$",
        "%.pdf$",
        "%.mkv$",
        "%.mp4$",
        "%.zip$",
      },
      
      -- Configure layout
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.55,
          results_width = 0.8,
        },
        vertical = {
          mirror = false,
        },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120,
      },
      
      -- Sorting strategy
      sorting_strategy = "ascending",
      
      -- Color scheme
      color_devicons = true,
      use_less = true,
      
      -- Key mappings within telescope
      mappings = {
        i = {
          -- Insert mode mappings
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<C-c>"] = actions.close,
          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,
          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,
          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,
          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          ["<C-l>"] = actions.complete_tag,
          ["<C-/>"] = actions.which_key, -- keys from pressing <C-/>
          ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
        },
        
        n = {
          -- Normal mode mappings
          ["<esc>"] = actions.close,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,
          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,
          ["H"] = actions.move_to_top,
          ["M"] = actions.move_to_middle,
          ["L"] = actions.move_to_bottom,
          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,
          ["gg"] = actions.move_to_top,
          ["G"] = actions.move_to_bottom,
          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,
          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,
          ["?"] = actions.which_key,
        },
      },
    },
    
    pickers = {
      -- Default configuration for builtin pickers
      find_files = {
        theme = "dropdown",
        previewer = false,
        hidden = true,
        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
      },
      
      live_grep = {
        theme = "ivy",
        additional_args = function(opts)
          return {"--hidden", "--glob", "!**/.git/*"}
        end
      },
      
      buffers = {
        theme = "dropdown",
        previewer = false,
        initial_mode = "normal",
        mappings = {
          i = {
            ["<C-d>"] = actions.delete_buffer,
          },
          n = {
            ["dd"] = actions.delete_buffer,
          },
        },
      },
      
      colorscheme = {
        enable_preview = true,
      },
      
      lsp_references = {
        theme = "ivy",
        initial_mode = "normal",
      },
      
      lsp_definitions = {
        theme = "ivy",
        initial_mode = "normal",
      },
      
      lsp_declarations = {
        theme = "ivy",
        initial_mode = "normal",
      },
      
      lsp_implementations = {
        theme = "ivy",
        initial_mode = "normal",
      },
    },
    
    extensions = {
      -- FZF extension configuration
      fzf = {
        fuzzy = true,                    -- false will only do exact matching
        override_generic_sorter = true,  -- override the generic sorter
        override_file_sorter = true,     -- override the file sorter
        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
      }
    },
  })

  -- Load telescope extensions
  pcall(telescope.load_extension, 'fzf')

  -- Set up keymaps
  M.setup_keymaps()
end

function M.setup_keymaps()
  local builtin_ok, builtin = pcall(require, 'telescope.builtin')
  if not builtin_ok then
    vim.notify("Telescope builtin not available", vim.log.levels.WARN)
    return
  end

  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }

  -- File pickers (wrapped with safety checks)
  keymap('n', '<leader>ff', function() safe_telescope_call(builtin.find_files) end, vim.tbl_extend('force', opts, { desc = 'Telescope find files' }))
  keymap('n', '<leader>fg', function() safe_telescope_call(builtin.live_grep) end, vim.tbl_extend('force', opts, { desc = 'Telescope live grep' }))
  keymap('n', '<leader>fb', function() safe_telescope_call(builtin.buffers) end, vim.tbl_extend('force', opts, { desc = 'Telescope buffers' }))
  keymap('n', '<leader>fh', function() safe_telescope_call(builtin.help_tags) end, vim.tbl_extend('force', opts, { desc = 'Telescope help tags' }))
  keymap('n', '<leader>fr', function() safe_telescope_call(builtin.oldfiles) end, vim.tbl_extend('force', opts, { desc = 'Telescope recent files' }))
  keymap('n', '<leader>fc', function() safe_telescope_call(builtin.colorscheme) end, vim.tbl_extend('force', opts, { desc = 'Telescope colorschemes' }))

  -- Search (wrapped with safety checks)
  keymap('n', '<leader>fw', function() safe_telescope_call(builtin.grep_string) end, vim.tbl_extend('force', opts, { desc = 'Telescope grep string under cursor' }))
  keymap('n', '<leader>fs', function()
    if not can_open_telescope() then return end
    safe_telescope_call(builtin.grep_string, { search = vim.fn.input("Grep > ") })
  end, vim.tbl_extend('force', opts, { desc = 'Telescope grep search' }))

  -- Git (wrapped with safety checks)
  keymap('n', '<leader>gc', function() safe_telescope_call(builtin.git_commits) end, vim.tbl_extend('force', opts, { desc = 'Telescope git commits' }))
  keymap('n', '<leader>gb', function() safe_telescope_call(builtin.git_branches) end, vim.tbl_extend('force', opts, { desc = 'Telescope git branches' }))
  keymap('n', '<leader>gs', function() safe_telescope_call(builtin.git_status) end, vim.tbl_extend('force', opts, { desc = 'Telescope git status' }))

  -- LSP (wrapped with safety checks - these will be available when LSP is set up)
  keymap('n', '<leader>lr', function() safe_telescope_call(builtin.lsp_references) end, vim.tbl_extend('force', opts, { desc = 'Telescope LSP references' }))
  keymap('n', '<leader>ld', function() safe_telescope_call(builtin.lsp_definitions) end, vim.tbl_extend('force', opts, { desc = 'Telescope LSP definitions' }))
  keymap('n', '<leader>li', function() safe_telescope_call(builtin.lsp_implementations) end, vim.tbl_extend('force', opts, { desc = 'Telescope LSP implementations' }))
  keymap('n', '<leader>ls', function() safe_telescope_call(builtin.lsp_document_symbols) end, vim.tbl_extend('force', opts, { desc = 'Telescope LSP document symbols' }))
  keymap('n', '<leader>lw', function() safe_telescope_call(builtin.lsp_workspace_symbols) end, vim.tbl_extend('force', opts, { desc = 'Telescope LSP workspace symbols' }))

  -- Vim (wrapped with safety checks)
  keymap('n', '<leader>fk', function() safe_telescope_call(builtin.keymaps) end, vim.tbl_extend('force', opts, { desc = 'Telescope keymaps' }))
  keymap('n', '<leader>fm', function() safe_telescope_call(builtin.marks) end, vim.tbl_extend('force', opts, { desc = 'Telescope marks' }))
  keymap('n', '<leader>fo', function() safe_telescope_call(builtin.vim_options) end, vim.tbl_extend('force', opts, { desc = 'Telescope vim options' }))
  keymap('n', '<leader>ft', function() safe_telescope_call(builtin.filetypes) end, vim.tbl_extend('force', opts, { desc = 'Telescope filetypes' }))

  -- Additional convenience mappings (wrapped with safety checks)
  keymap('n', '<C-p>', function() safe_telescope_call(builtin.find_files) end, vim.tbl_extend('force', opts, { desc = 'Telescope find files' }))
  keymap('n', '<C-f>', function() safe_telescope_call(builtin.live_grep) end, vim.tbl_extend('force', opts, { desc = 'Telescope live grep' }))
end

return M 