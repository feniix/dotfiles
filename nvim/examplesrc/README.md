# Language Support Validation Examples

This directory contains simplified example source files for validating language support in your Neovim configuration. Each file demonstrates core language features to test syntax highlighting, LSP functionality, autocompletion, and other language-specific features.

## Files Overview

### 🐹 Go (`main.go`)
- **Features Tested:**
  - Package declarations and imports
  - Struct definitions with JSON tags
  - Method implementations (Stringer interface)
  - Goroutines and channels
  - Select statements with timeout
  - Basic conditionals and loops

### 🐍 Python (`main.py`)
- **Features Tested:**
  - Type hints and annotations
  - Dataclasses and decorators
  - Async/await patterns
  - Context managers
  - List comprehensions
  - Class methods and inheritance
  - F-strings

### 🦀 Rust (`main.rs`)
- **Features Tested:**
  - Struct definitions and implementations
  - Traits and generics
  - Error handling with Result types
  - Pattern matching
  - Macros
  - Collections (HashMap)
  - Display trait implementation

### 🏗️ Terraform (`main.tf`)
- **Features Tested:**
  - Provider configurations
  - Resource definitions
  - Variables with validation
  - Data sources
  - Local values
  - Conditional expressions
  - Template functions
  - Output values

### 🎭 Puppet (`main.pp`)
- **Features Tested:**
  - Class definitions with parameters
  - Resource declarations
  - Conditionals and case statements
  - Custom defined types
  - Facts and Hiera lookups
  - Resource collectors
  - Virtual resources
  - Custom functions
  - Node classification

### 📋 Template (`userdata.tpl`)
- **Features Tested:**
  - Bash scripting
  - Template variable interpolation
  - Basic system commands
  - JSON configuration
  - Here documents

## How to Use

These files are designed to be opened in Neovim to test:

1. **Syntax Highlighting**: Open each file and verify that different language constructs are properly highlighted
2. **LSP Features**: Test go-to-definition, hover information, and error detection
3. **Autocompletion**: Try typing and see if intelligent suggestions appear
4. **Formatting**: Test automatic code formatting capabilities
5. **Linting**: Check if syntax errors and style issues are detected

## Language Server Requirements

To get full language support, ensure you have the following language servers installed:

- **Go**: `gopls`
- **Python**: `pyright` or `pylsp`
- **Rust**: `rust-analyzer`
- **Terraform**: `terraform-ls`
- **Puppet**: `puppet-languageserver`

## Testing Checklist

For each language, verify the following work correctly:

- [ ] Syntax highlighting
- [ ] Error detection and diagnostics
- [ ] Code completion
- [ ] Go to definition
- [ ] Find references
- [ ] Hover documentation
- [ ] Code formatting
- [ ] Symbol search
- [ ] Rename refactoring (where supported)

## Example Commands

You can run these files to verify they're syntactically correct:

```bash
# Go
go run main.go

# Python
python main.py

# Rust (requires Cargo.toml)
rustc main.rs && ./main

# Terraform
terraform validate

# Puppet
puppet parser validate main.pp
```

## Notes

- Files are simplified for quick language support testing
- The Terraform configuration is designed for AWS but won't create resources without proper setup
- All examples use modern language features and idiomatic patterns
- Files are designed to be concise while covering essential language constructs 