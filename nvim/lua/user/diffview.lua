-- Diffview configuration for comprehensive Git diff and history visualization
local M = {}

function M.setup()
  local diffview_ok, diffview = pcall(require, 'diffview')
  if not diffview_ok then
    vim.notify("diffview.nvim not available. Run :PackerSync to install.", vim.log.levels.WARN)
    return
  end

  -- Configure diffview with custom settings
  diffview.setup({
    diff_binaries = false,    -- Show diffs for binaries
    enhanced_diff_hl = false, -- Enhanced syntax highlighting for diffs
    git_cmd = { "git" },      -- Git command to use
    hg_cmd = { "hg" },        -- Mercurial command to use
    use_icons = true,         -- Requires nvim-web-devicons
    
    -- Show/hide components in the file panel
    show_help_hints = true,
    
    -- File panel configuration
    file_panel = {
      listing_style = "tree",             -- "list" or "tree"
      tree_options = {
        flatten_dirs = true,              -- Flatten dirs that only contain one dir
        folder_statuses = "only_folded",  -- "never", "only_folded", "always"
      },
      win_config = {
        position = "left",                -- "left", "right", "top", "bottom"
        width = 35,                      -- Window width
        win_opts = {}
      },
    },
    
    -- File history panel configuration
    file_history_panel = {
      log_options = {
        git = {
          single_file = {
            diff_merges = "combined",
          },
          multi_file = {
            diff_merges = "first-parent",
          },
        },
        hg = {
          single_file = {},
          multi_file = {},
        },
      },
      win_config = {
        position = "bottom",
        height = 16,
        win_opts = {}
      },
    },
    
    -- Commit log panel configuration
    commit_log_panel = {
      win_config = {
        win_opts = {},
      }
    },
    
    -- Default args for Diffview commands
    default_args = {
      DiffviewOpen = {},
      DiffviewFileHistory = {},
    },
    
    -- Key mappings for diffview windows
    keymaps = {
      disable_defaults = false, -- Disable default keymaps
      view = {
        -- Normal mode mappings in diff view
        { "n", "<tab>",       function() 
          vim.cmd("DiffviewToggleFiles")
        end,                                                desc = "Toggle the file panel" },
        { "n", "gf",          diffview.actions.goto_file_edit,         desc = "Open the file in a new buffer" },
        { "n", "<C-w><C-f>",  diffview.actions.goto_file_split,        desc = "Open the file in a new split" },
        { "n", "<C-w>gf",     diffview.actions.goto_file_tab,          desc = "Open the file in a new tab" },
        { "n", "<leader>e",   diffview.actions.focus_files,            desc = "Bring focus to the file panel" },
        { "n", "<leader>b",   diffview.actions.toggle_files,           desc = "Toggle the file panel" },
        { "n", "g<C-x>",      diffview.actions.cycle_layout,           desc = "Cycle through available layouts" },
        { "n", "[x",          diffview.actions.prev_conflict,          desc = "In the merge-tool: jump to the previous conflict" },
        { "n", "]x",          diffview.actions.next_conflict,          desc = "In the merge-tool: jump to the next conflict" },
        { "n", "<leader>co",  diffview.actions.conflict_choose("ours"),   desc = "Choose the OURS version of a conflict" },
        { "n", "<leader>ct",  diffview.actions.conflict_choose("theirs"), desc = "Choose the THEIRS version of a conflict" },
        { "n", "<leader>cb",  diffview.actions.conflict_choose("base"),   desc = "Choose the BASE version of a conflict" },
        { "n", "<leader>ca",  diffview.actions.conflict_choose("all"),    desc = "Choose all the versions of a conflict" },
        { "n", "dx",          diffview.actions.conflict_choose("none"),   desc = "Delete the conflict region" },
      },
      diff1 = {
        -- Mappings for single-file diff view
        { "n", "g?", diffview.actions.help("view"), desc = "Open the help panel" },
      },
      diff2 = {
        -- Mappings for 2-way diff view  
        { "n", "g?", diffview.actions.help("view"), desc = "Open the help panel" },
      },
      diff3 = {
        -- Mappings for 3-way diff view (merge conflicts)
        { "n", "g?", diffview.actions.help("view"), desc = "Open the help panel" },
      },
      diff4 = {
        -- Mappings for 4-way diff view
        { "n", "g?", diffview.actions.help("view"), desc = "Open the help panel" },
      },
      file_panel = {
        { "n", "j",              diffview.actions.next_entry,         desc = "Bring the cursor to the next file entry" },
        { "n", "<down>",         diffview.actions.next_entry,         desc = "Bring the cursor to the next file entry" },
        { "n", "k",              diffview.actions.prev_entry,         desc = "Bring the cursor to the previous file entry" },
        { "n", "<up>",           diffview.actions.prev_entry,         desc = "Bring the cursor to the previous file entry" },
        { "n", "<cr>",           diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "o",              diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "l",              diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "<2-LeftMouse>",  diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "-",              diffview.actions.toggle_stage_entry, desc = "Stage / unstage the selected entry" },
        { "n", "S",              diffview.actions.stage_all,          desc = "Stage all entries" },
        { "n", "U",              diffview.actions.unstage_all,        desc = "Unstage all entries" },
        { "n", "X",              diffview.actions.restore_entry,      desc = "Restore entry to the state on the left side" },
        { "n", "L",              diffview.actions.open_commit_log,    desc = "Open the commit log panel" },
        { "n", "zo",             diffview.actions.open_fold,          desc = "Expand fold" },
        { "n", "h",              diffview.actions.close_fold,         desc = "Collapse fold" },
        { "n", "zc",             diffview.actions.close_fold,         desc = "Collapse fold" },
        { "n", "za",             diffview.actions.toggle_fold,        desc = "Toggle fold" },
        { "n", "zR",             diffview.actions.open_all_folds,     desc = "Expand all folds" },
        { "n", "zM",             diffview.actions.close_all_folds,    desc = "Collapse all folds" },
        { "n", "<c-b>",          diffview.actions.scroll_view(-0.25), desc = "Scroll the view up" },
        { "n", "<c-f>",          diffview.actions.scroll_view(0.25),  desc = "Scroll the view down" },
        { "n", "<tab>",          diffview.actions.select_next_entry,  desc = "Open the diff for the next file" },
        { "n", "<s-tab>",        diffview.actions.select_prev_entry,  desc = "Open the diff for the previous file" },
        { "n", "gf",             diffview.actions.goto_file_edit,     desc = "Open the file in a new buffer" },
        { "n", "<C-w><C-f>",     diffview.actions.goto_file_split,    desc = "Open the file in a new split" },
        { "n", "<C-w>gf",        diffview.actions.goto_file_tab,      desc = "Open the file in a new tab" },
        { "n", "i",              diffview.actions.listing_style,      desc = "Toggle between 'list' and 'tree' views" },
        { "n", "f",              diffview.actions.toggle_flatten_dirs, desc = "Flatten empty subdirectories in tree listing style" },
        { "n", "R",              diffview.actions.refresh_files,      desc = "Update stats and entries in the file list" },
        { "n", "<leader>e",      diffview.actions.focus_files,        desc = "Bring focus to the file panel" },
        { "n", "<leader>b",      diffview.actions.toggle_files,       desc = "Toggle the file panel" },
        { "n", "g<C-x>",         diffview.actions.cycle_layout,       desc = "Cycle through available layouts" },
        { "n", "[x",             diffview.actions.prev_conflict,      desc = "Go to the previous conflict" },
        { "n", "]x",             diffview.actions.next_conflict,      desc = "Go to the next conflict" },
        { "n", "g?",             diffview.actions.help("file_panel"), desc = "Open the help panel" },
      },
      file_history_panel = {
        { "n", "g!",            diffview.actions.options,            desc = "Open the option panel" },
        { "n", "<C-A-d>",       diffview.actions.open_in_diffview,   desc = "Open the entry under the cursor in a diffview" },
        { "n", "y",             diffview.actions.copy_hash,          desc = "Copy the commit hash of the entry under the cursor" },
        { "n", "L",             diffview.actions.open_commit_log,    desc = "Show commit details" },
        { "n", "zR",            diffview.actions.open_all_folds,     desc = "Expand all folds" },
        { "n", "zM",            diffview.actions.close_all_folds,    desc = "Collapse all folds" },
        { "n", "j",             diffview.actions.next_entry,         desc = "Bring the cursor to the next file entry" },
        { "n", "<down>",        diffview.actions.next_entry,         desc = "Bring the cursor to the next file entry" },
        { "n", "k",             diffview.actions.prev_entry,         desc = "Bring the cursor to the previous file entry" },
        { "n", "<up>",          diffview.actions.prev_entry,         desc = "Bring the cursor to the previous file entry" },
        { "n", "<cr>",          diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "o",             diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "<2-LeftMouse>", diffview.actions.select_entry,       desc = "Open the diff for the selected entry" },
        { "n", "<c-b>",         diffview.actions.scroll_view(-0.25), desc = "Scroll the view up" },
        { "n", "<c-f>",         diffview.actions.scroll_view(0.25),  desc = "Scroll the view down" },
        { "n", "<tab>",         diffview.actions.select_next_entry,  desc = "Open the diff for the next file" },
        { "n", "<s-tab>",       diffview.actions.select_prev_entry,  desc = "Open the diff for the previous file" },
        { "n", "gf",            diffview.actions.goto_file_edit,     desc = "Open the file in a new buffer" },
        { "n", "<C-w><C-f>",    diffview.actions.goto_file_split,    desc = "Open the file in a new split" },
        { "n", "<C-w>gf",       diffview.actions.goto_file_tab,      desc = "Open the file in a new tab" },
        { "n", "<leader>e",     diffview.actions.focus_files,        desc = "Bring focus to the file panel" },
        { "n", "<leader>b",     diffview.actions.toggle_files,       desc = "Toggle the file panel" },
        { "n", "g<C-x>",        diffview.actions.cycle_layout,       desc = "Cycle through available layouts" },
        { "n", "g?",            diffview.actions.help("file_history_panel"), desc = "Open the help panel" },
      },
      option_panel = {
        { "n", "<tab>", diffview.actions.select_entry,          desc = "Change the current option" },
        { "n", "q",     diffview.actions.close,                 desc = "Close the panel" },
        { "n", "g?",    diffview.actions.help("option_panel"), desc = "Open the help panel" },
      },
      help_panel = {
        { "n", "q",     diffview.actions.close, desc = "Close help menu" },
        { "n", "<esc>", diffview.actions.close, desc = "Close help menu" },
      },
    },
  })

  -- Custom commands for easier access
  vim.api.nvim_create_user_command('DiffviewOpenMaster', function()
    vim.cmd('DiffviewOpen origin/master...HEAD')
  end, { desc = 'Open diffview comparing current branch to origin/master' })

  vim.api.nvim_create_user_command('DiffviewOpenMain', function()
    vim.cmd('DiffviewOpen origin/main...HEAD')
  end, { desc = 'Open diffview comparing current branch to origin/main' })

  vim.api.nvim_create_user_command('DiffviewOpenStaged', function()
    vim.cmd('DiffviewOpen --staged')
  end, { desc = 'Open diffview for staged changes' })

  -- Set up global keymaps
  M.setup_keymaps()
end

function M.setup_keymaps()
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }

  -- Diffview commands
  keymap('n', '<leader>gd', ':DiffviewOpen<CR>', vim.tbl_extend('force', opts, { desc = 'Open Git diff view' }))
  keymap('n', '<leader>gh', ':DiffviewFileHistory<CR>', vim.tbl_extend('force', opts, { desc = 'Open Git file history' }))
  keymap('n', '<leader>gH', ':DiffviewFileHistory %<CR>', vim.tbl_extend('force', opts, { desc = 'Open current file history' }))
  keymap('n', '<leader>gq', ':DiffviewClose<CR>', vim.tbl_extend('force', opts, { desc = 'Close Git diff view' }))
  
  -- Advanced Git diff commands
  keymap('n', '<leader>gm', ':DiffviewOpenMain<CR>', vim.tbl_extend('force', opts, { desc = 'Diff against origin/main' }))
  keymap('n', '<leader>gM', ':DiffviewOpenMaster<CR>', vim.tbl_extend('force', opts, { desc = 'Diff against origin/master' }))
  keymap('n', '<leader>gS', ':DiffviewOpenStaged<CR>', vim.tbl_extend('force', opts, { desc = 'View staged changes' }))
  
  -- File history with range selection (visual mode)
  keymap('v', '<leader>gh', ':DiffviewFileHistory<CR>', vim.tbl_extend('force', opts, { desc = 'File history for selection' }))
end

return M 