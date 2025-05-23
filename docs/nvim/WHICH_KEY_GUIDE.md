# Which-Key Guide

Which-key provides helpful popup menus showing available keybindings when you start typing a key sequence. Perfect for discovering and remembering your extensive keymap configuration!

**Note**: This configuration uses the modern which-key.nvim v3 API with the `add()` method for improved performance and maintainability.

## Installation

1. Run `:PackerSync` in Neovim to install which-key
2. Restart Neovim
3. Start typing any leader key sequence and see the magic! ✨
4. Run `:checkhealth which-key` to verify everything is working properly

## Key Groups

When you press `<leader>` (space), you'll see organized groups:

### 📁 **Buffer Operations** (`<leader>b`)
- `<leader>bn` - Next buffer
- `<leader>bp` - Previous buffer
- `<leader>bd` - Delete buffer
- `<leader>bl` - List buffers

### 🔍 **Find/File Operations** (`<leader>f`)
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Buffers
- `<leader>fh` - Help tags
- `<leader>fr` - Recent files
- `<leader>fc` - Colorschemes
- `<leader>fw` - Grep word under cursor
- `<leader>fs` - Grep search
- `<leader>fk` - Keymaps
- `<leader>fm` - Marks
- `<leader>fo` - Vim options
- `<leader>ft` - Filetypes

### 🌱 **Git Operations** (`<leader>g`)
- `<leader>gc` - Git commits
- `<leader>gb` - Git branches
- `<leader>gs` - Git status
- `<leader>gl` - Go metalinter (when in Go files)
- `<leader>gd` - Git diff view
- `<leader>gh` - Git file history
- `<leader>gH` - Current file history
- `<leader>gq` - Close Git diff view
- `<leader>gm` - Diff against origin/main
- `<leader>gM` - Diff against origin/master
- `<leader>gS` - View staged changes

### 🔧 **LSP/Language** (`<leader>l`)
- `<leader>lr` - LSP references
- `<leader>ld` - LSP definitions
- `<leader>li` - LSP implementations
- `<leader>ls` - LSP document symbols
- `<leader>lw` - LSP workspace symbols
- `<leader>ll` - Toggle list characters

### 🐛 **Debug Operations** (`<leader>d`)
- `<leader>db` - Toggle breakpoint
- `<leader>df` - Peek function definition
- `<leader>dF` - Peek class definition

### 🔄 **Text Object Swapping** (`<leader>s`)
- `<leader>sn` - Next swapping
  - `<leader>sna` - Swap **N**ext **A**rgument
  - `<leader>snm` - Swap **N**ext **M**ethod
- `<leader>sp` - Previous swapping
  - `<leader>spa` - Swap **P**revious **A**rgument
  - `<leader>spm` - Swap **P**revious **M**ethod

### ⚙️ **Toggle Operations** (`<leader>t`)
- `<leader>tn` - Toggle relative line numbers
- `<leader>tw` - Toggle wrap
- `<leader>ts` - Toggle spell check
- `<leader>ti` - Toggle indent guides
- `<leader>tI` - Toggle indent scope highlighting

### ⚡ **Quick Actions**
- `<leader>q` - Clear search highlight

### 🐹 **Go Operations** (`<leader>G` - in Go files only)
- `<leader>Gb` - Build Go files
- `<leader>Gt` - Go test
- `<leader>Gr` - Go run
- `<leader>Gd` - Go doc
- `<leader>Gc` - Go coverage toggle
- `<leader>Gi` - Go info
- `<leader>Gv` - Go def vertical split
- `<leader>Gs` - Go def horizontal split
- `<leader>Gl` - Go metalinter

## Control Key Shortcuts

When you press `Ctrl` keys, you'll also see helpful descriptions:

### 🪟 **Window Navigation**
- `<C-h>` - Window left
- `<C-j>` - Window down
- `<C-k>` - Window up
- `<C-l>` - Window right

### 📄 **File Operations**
- `<C-s>` - Save file
- `<C-a>` - Select all
- `<C-z>` - Undo
- `<C-y>` - Redo
- `<C-p>` - Find files (Telescope)
- `<C-f>` - Live grep (Telescope)

## TreeSitter Text Object Navigation

When you type `]` or `[`, you'll see movement options:

### ➡️ **Next** (`]`)
- `]m` - Next function start
- `]M` - Next function end
- `]]` - Next class start
- `]}` - Next class end
- `]o` - Next loop start
- `]O` - Next loop end
- `]d` - Next conditional
- `]s` - Next scope
- `]z` - Next fold

### ⬅️ **Previous** (`[`)
- `[m` - Previous function start
- `[M` - Previous function end
- `[[` - Previous class start
- `[{` - Previous class end
- `[o` - Previous loop start
- `[O` - Previous loop end
- `[d` - Previous conditional
- `[s` - Previous scope
- `[z` - Previous fold

## Text Objects Help

In visual or operator-pending mode, which-key shows text object options:

### 🎯 **Around** (`a`)
- `af` - Function
- `ac` - Class
- `ab` - Block
- `aa` - Argument
- `ai` - Conditional
- `al` - Loop
- `aC` - Call
- `aM` - Comment
- `a=` - Assignment
- `aN` - Number
- `aR` - Return

### 🎯 **Inside** (`i`)
- `if` - Function
- `ic` - Class
- `ib` - Block
- `ia` - Argument
- `ii` - Conditional
- `il` - Loop
- `iC` - Call
- `iM` - Comment
- `i=` - Assignment
- `iN` - Number
- `iR` - Return

## Tips

1. **Wait for the popup** - Don't rush! Let which-key show you options
2. **Learn gradually** - Focus on one group at a time
3. **Use frequently** - The more you use it, the faster you'll remember
4. **Scroll through options** - Use `<C-d>`/`<C-u>` to scroll long lists
5. **ESC to cancel** - Press Escape if you start a sequence by mistake

## Customization

All groups and descriptions are defined in `nvim/lua/user/which-key.lua`. You can:
- Add new key groups
- Modify descriptions
- Change the popup appearance
- Add buffer-specific mappings

### Plugin Overlaps

Some plugins use intentional "overlapping" keymaps that are actually hierarchical. These appear as warnings in `:checkhealth which-key` but are **expected behavior**:

**vim-surround / nvim-surround:**
- `ys` + motion - Add surround around motion (waits for motion)
- `yss` - Add surround around current line (complete command)
- `yS` + motion - Add surround around motion with new lines (waits for motion)
- `ySS` - Add surround around current line with new lines (complete command)

**Comment.nvim:**
- `gc` + motion - Comment linewise over motion (waits for motion)
- `gcc` - Comment current line (complete command)
- `gcA` - Comment at end of line (complete command)
- `gco` / `gcO` - Comment line below/above (complete commands)
- `gb` + motion - Comment blockwise over motion (waits for motion)
- `gbc` - Comment current block (complete command)

**Why these aren't real conflicts:**
- The shorter keys (`ys`, `gc`, `gb`) wait for additional input (motion or text object)
- The longer keys (`yss`, `gcc`, `gbc`) are complete commands that execute immediately
- This is how these plugins are designed to work - it's **intentional hierarchical design**

**Configuration:** Overlap notifications are disabled in the which-key setup because these warnings are false positives for legitimate plugin behavior.

These are documented in the which-key configuration so you can see helpful descriptions when you press these keys.

## Features

- **Auto-discovery** - Automatically shows all mapped keys
- **Smart grouping** - Related commands grouped together
- **Context-aware** - Different mappings for different file types
- **Beautiful UI** - Clean, readable popup with icons
- **Fast** - Triggers automatically with configurable delays

Enjoy discovering your keybindings! 🎉 