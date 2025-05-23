# Diffview.nvim Guide

diffview.nvim provides a comprehensive Git diff and history viewer directly in Neovim. It's perfect for reviewing changes, exploring file history, and resolving merge conflicts.

## Installation

diffview.nvim is included in the default plugin configuration.

1. Run `:Lazy sync` in Neovim to install diffview.nvim
2. Restart Neovim
3. Start using the commands below! 🚀

## Quick Start

### **Basic Commands**
- `:DiffviewOpen` - Open diff view for current working directory changes
- `:DiffviewFileHistory` - Show file history for current repository
- `:DiffviewFileHistory %` - Show history for current file only
- `:DiffviewClose` - Close the diff view

### **Quick Access Keybindings**
- `<leader>gd` - Open Git diff view
- `<leader>gh` - Open Git file history  
- `<leader>gH` - Open current file history
- `<leader>gq` - Close Git diff view

## Advanced Usage

### **Branch Comparisons**
- `<leader>gm` - Compare current branch to `origin/main`
- `<leader>gM` - Compare current branch to `origin/master`
- `:DiffviewOpen HEAD~1` - Compare to previous commit
- `:DiffviewOpen main..feature-branch` - Compare branches

### **Staging Area**
- `<leader>gS` - View staged changes
- `:DiffviewOpen --staged` - Same as above
- `:DiffviewOpen --cached` - Alternative syntax

### **File History with Ranges**
- Select lines in visual mode, then `<leader>gh` - Show history for selected lines
- `:DiffviewFileHistory --range=10,20` - Show history for specific line range

## Interface Navigation

### **File Panel (Left Side)**
When in the file panel, use these keys:

**Navigation:**
- `j`/`k` or `↓`/`↑` - Move between files
- `<CR>`, `o`, or `l` - Open diff for selected file
- `<Tab>` - Open next file diff
- `<S-Tab>` - Open previous file diff

**File Operations:**
- `-` - Stage/unstage the selected file
- `S` - Stage all files
- `U` - Unstage all files
- `X` - Restore file to previous state
- `R` - Refresh file list

**View Controls:**
- `i` - Toggle between list and tree view
- `f` - Toggle flatten empty directories
- `zo`/`zc` - Open/close folds
- `zR`/`zM` - Open/close all folds

**Panel Management:**
- `<leader>b` - Toggle file panel visibility
- `g<C-x>` - Cycle through different layouts

### **Diff View (Right Side)**
When viewing diffs:

**Navigation:**
- `]x`/`[x` - Jump to next/previous conflict (during merges)
- `<C-f>`/`<C-b>` - Scroll view down/up
- `gf` - Open file in new buffer
- `<C-w><C-f>` - Open file in new split
- `<C-w>gf` - Open file in new tab

**Merge Conflict Resolution:**
- `<leader>co` - Choose **O**urs (local version)
- `<leader>ct` - Choose **T**heirs (remote version)  
- `<leader>cb` - Choose **B**ase (common ancestor)
- `<leader>ca` - Choose **A**ll (keep both versions)
- `dx` - Delete conflict region entirely

**Layout & Help:**
- `<Tab>` - Toggle file panel
- `g<C-x>` - Cycle layouts
- `g?` - Show help

### **File History Panel**
When viewing file history:

**Navigation:**
- `j`/`k` - Move between commits
- `<CR>` - Open commit diff
- `y` - Copy commit hash
- `L` - Show commit details

**Advanced:**
- `<C-A-d>` - Open commit in full diffview
- `g!` - Open options panel

## Custom Commands

The configuration includes several custom commands for convenience:

### **Branch Comparison Commands**
- `:DiffviewOpenMain` - Compare to `origin/main`
- `:DiffviewOpenMaster` - Compare to `origin/master`  
- `:DiffviewOpenStaged` - View staged changes

### **Common Git Workflows**

**Reviewing Your Changes:**
```
<leader>gd              " See unstaged changes
<leader>gS              " See staged changes  
<leader>gm              " Compare to main branch
```

**Exploring History:**
```
<leader>gh              " Repository history
<leader>gH              " Current file history
```

**During Code Review:**
```
:DiffviewOpen pr-branch..main    " Compare PR to main
<Tab>                            " Navigate between files
]x / [x                          " Jump between conflicts
```

## Tips & Tricks

### **1. Efficient File Navigation**
- Use `<Tab>`/`<S-Tab>` to quickly cycle through changed files
- Use `i` to toggle between list and tree view for better organization
- Use `f` to flatten nested directories

### **2. Staging Workflow**
- Use `-` to quickly stage/unstage individual files
- Use `S`/`U` to stage/unstage all files at once
- Combine with `<leader>gS` to review staged changes

### **3. Merge Conflict Resolution**
- Use `]x`/`[x` to jump between conflicts
- Use conflict choice commands (`<leader>co`, `<leader>ct`, etc.)
- Use `dx` to delete entire conflict sections

### **4. History Exploration**
- Use visual selection + `<leader>gh` to see history for specific lines
- Use `y` in history view to copy commit hashes for other Git commands
- Use `L` to see full commit details

### **5. Integration with Other Tools**
- Copy commit hashes with `y` and use in terminal: `git show <hash>`
- Use `gf` to open files for editing while keeping diff view open
- Use `<C-w>gf` to open in new tab for side-by-side editing

## Customization

The diffview configuration is in `nvim/lua/user/diffview.lua`. You can:
- Change panel positions and sizes
- Modify keybindings
- Add custom Git commands
- Change file listing style defaults

## Troubleshooting

**Q: Diffview won't open**
A: Make sure you're in a Git repository and have changes to view.

**Q: Can't see staged changes**  
A: Use `<leader>gS` or `:DiffviewOpen --staged` specifically for staged changes.

**Q: Performance issues with large repos**
A: Consider using specific file paths: `:DiffviewOpen -- path/to/files`

**Q: Merge conflicts look confusing**
A: Use `g?` for help, and remember `]x`/`[x` to navigate between conflicts.

## Integration with Gitsigns

diffview.nvim works perfectly with gitsigns.nvim:
- Use gitsigns for inline change indicators
- Use diffview for comprehensive diff viewing
- Both share the `<leader>g` keymap group for consistency

Enjoy exploring your Git history and changes! 🎉 