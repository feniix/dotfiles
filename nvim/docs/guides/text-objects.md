# TreeSitter Text Objects Guide

nvim-treesitter-textobjects provides intelligent text objects based on your code's syntax tree. This allows for precise selection and manipulation of code structures.

## Text Object Selection

Use these in visual mode (`v`) or with operators (`d`, `c`, `y`, etc.):

### Function Text Objects
- `af` - **A** **F**unction (outer) - includes function signature and body
- `if` - **I**nner **F**unction - function body only

### Class Text Objects  
- `ac` - **A** **C**lass (outer) - entire class including declaration
- `ic` - **I**nner **C**lass - class body only

### Block Text Objects
- `ab` - **A** **B**lock (outer) - includes braces/delimiters
- `ib` - **I**nner **B**lock - block contents only

### Parameter/Argument Text Objects
- `aa` - **A** **A**rgument (outer) - includes commas and whitespace
- `ia` - **I**nner **A**rgument - parameter content only

### Conditional Text Objects
- `ai` - **A**n **I**f statement (outer) - entire if/else block
- `ii` - **I**nner **I**f - condition and body

### Loop Text Objects
- `al` - **A** **L**oop (outer) - entire loop structure
- `il` - **I**nner **L**oop - loop body only

### Call Text Objects
- `aC` - **A** **C**all (outer) - entire function call with arguments
- `iC` - **I**nner **C**all - arguments only

### Comment Text Objects
- `aM` - **A** co**M**ment (outer) - entire comment block
- `iM` - **I**nner co**M**ment - comment content

### Assignment Text Objects
- `a=` - **A**ssignment (outer) - entire assignment statement
- `i=` - **I**nner assignment - right-hand side only

### Number Text Objects
- `aN` / `iN` - **N**umber - numeric literals

### Return Text Objects
- `aR` - **A** **R**eturn (outer) - entire return statement
- `iR` - **I**nner **R**eturn - returned value only

## Examples

```go
// Example Go function
func calculateSum(a int, b int) int {
    if a > 0 {
        return a + b
    }
    return 0
}
```

- `vif` - Select function body (everything inside braces)
- `vaf` - Select entire function including signature
- `via` - Select first parameter content (`a int`)
- `vaa` - Select first parameter with comma (`a int,`)
- `vii` - Select if condition and body
- `vai` - Select entire if statement

## Movement Between Text Objects

### Navigate Functions and Classes
- `]m` - Go to next function start
- `[m` - Go to previous function start  
- `]M` - Go to next function end
- `[M` - Go to previous function end
- `]]` - Go to next class start
- `[[` - Go to previous class start
- `][` - Go to next class end
- `[]` - Go to previous class end

### Navigate Loops
- `]o` - Go to next loop start
- `[o` - Go to previous loop start
- `]O` - Go to next loop end
- `[O` - Go to previous loop end

### Navigate Conditionals
- `]d` - Go to next conditional
- `[d` - Go to previous conditional

### Navigate Scopes and Folds
- `]s` - Go to next scope
- `[s` - Go to previous scope
- `]z` - Go to next fold
- `[z` - Go to previous fold

## Swapping Text Objects

Quickly reorganize code by swapping elements:

### Parameters/Arguments
- `<leader>sna` - Swap with **N**ext **A**rgument
- `<leader>spa` - Swap with **P**revious **A**rgument

### Functions/Methods
- `<leader>snm` - Swap with **N**ext **M**ethod
- `<leader>spm` - Swap with **P**revious **M**ethod

## LSP Integration

Preview definitions without leaving current buffer:

- `<leader>df` - Peek **D**efinition of current **F**unction
- `<leader>dF` - Peek **D**efinition of current **C**lass

## Language-Specific Usage

### Go
Works great with:
- Functions, methods, interfaces
- Struct definitions
- For/range loops
- If statements and switch cases

### Python  
Excellent for:
- Function and class definitions
- List/dict comprehensions
- For/while loops
- Try/except blocks

### JavaScript/TypeScript
Perfect for:
- Function expressions and arrow functions
- Object methods and properties
- Promise chains
- Class definitions

### JSON/YAML
Useful for:
- Object/array structures
- Key-value pairs
- Nested configurations

## Tips

1. **Combine with operators**: `daf` deletes entire function, `cii` changes if condition
2. **Use in visual mode**: `vaa` then `p` to select and replace parameter
3. **Chain movements**: `]m]m` to jump to function after next
4. **Practice with your language**: Each language has different syntax patterns

## Troubleshooting

If text objects aren't working:
1. Ensure the language parser is installed: `:TSInstall <language>`
2. Check treesitter status: `:TSModuleInfo textobjects`
3. Verify highlighting works: `:TSHighlightTest`

## See Also

- `:help nvim-treesitter-textobjects` - Full documentation
- `:TSPlaygroundToggle` - Visualize syntax tree
- `:TSHighlightCapturesUnderCursor` - Debug textobject queries 