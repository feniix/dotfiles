#!/bin/bash
# Check and fix nvim directory structure issues
# Prevents and fixes circular symlinks and other structural problems

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
NVIM_DIR="$DOTFILES_DIR/nvim"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo -e "${BLUE}${BOLD}=========================================${RESET}"
echo -e "${BLUE}${BOLD}Nvim Structure Check${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

# Check for circular symlinks
echo -e "\n${YELLOW}Checking for circular symlinks...${RESET}"

# Look for any symlinks inside nvim directory that point back to nvim
if [ -d "$NVIM_DIR" ]; then
    circular_links=$(find "$NVIM_DIR" -type l -exec ls -la {} \; | grep -E "nvim.*nvim" || true)
    
    if [ -n "$circular_links" ]; then
        echo -e "${RED}✗ Found circular symlinks:${RESET}"
        echo "$circular_links"
        
        # Fix circular symlinks
        echo -e "\n${YELLOW}Fixing circular symlinks...${RESET}"
        find "$NVIM_DIR" -type l -name "nvim" -delete
        echo -e "${GREEN}✓ Removed circular symlinks${RESET}"
    else
        echo -e "${GREEN}✓ No circular symlinks found${RESET}"
    fi
else
    echo -e "${RED}✗ Nvim directory not found at $NVIM_DIR${RESET}"
    exit 1
fi

# Check main symlink
echo -e "\n${YELLOW}Checking main configuration symlink...${RESET}"

if [ -L "$XDG_CONFIG_HOME/nvim" ]; then
    target=$(readlink "$XDG_CONFIG_HOME/nvim")
    if [ "$target" = "$NVIM_DIR" ]; then
        echo -e "${GREEN}✓ Main symlink is correct: $XDG_CONFIG_HOME/nvim → $NVIM_DIR${RESET}"
    else
        echo -e "${YELLOW}! Main symlink points to: $target${RESET}"
        echo -e "${YELLOW}  Expected: $NVIM_DIR${RESET}"
        
        read -p "Fix main symlink? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$XDG_CONFIG_HOME/nvim"
            ln -sf "$NVIM_DIR" "$XDG_CONFIG_HOME/nvim"
            echo -e "${GREEN}✓ Fixed main symlink${RESET}"
        fi
    fi
elif [ -d "$XDG_CONFIG_HOME/nvim" ]; then
    echo -e "${YELLOW}! $XDG_CONFIG_HOME/nvim exists as directory, not symlink${RESET}"
    echo -e "${YELLOW}  This should be a symlink to $NVIM_DIR${RESET}"
    
    read -p "Replace directory with symlink? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_name="$XDG_CONFIG_HOME/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$XDG_CONFIG_HOME/nvim" "$backup_name"
        ln -sf "$NVIM_DIR" "$XDG_CONFIG_HOME/nvim"
        echo -e "${GREEN}✓ Replaced directory with symlink${RESET}"
        echo -e "${BLUE}  Backup saved to: $backup_name${RESET}"
    fi
else
    echo -e "${YELLOW}! Main symlink missing${RESET}"
    
    read -p "Create main symlink? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$(dirname "$XDG_CONFIG_HOME/nvim")"
        ln -sf "$NVIM_DIR" "$XDG_CONFIG_HOME/nvim"
        echo -e "${GREEN}✓ Created main symlink${RESET}"
    fi
fi

# Check for essential files
echo -e "\n${YELLOW}Checking essential configuration files...${RESET}"

essential_files=("init.lua" "lua" "lazy-lock.json")
missing_files=()

for file in "${essential_files[@]}"; do
    if [ -e "$NVIM_DIR/$file" ]; then
        echo -e "${GREEN}✓ $file exists${RESET}"
    else
        echo -e "${RED}✗ $file is missing${RESET}"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing essential files. This may indicate a structural problem.${RESET}"
fi

# Check for unexpected nested directories
echo -e "\n${YELLOW}Checking for unexpected nested structures...${RESET}"

nested_issues=$(find "$NVIM_DIR" -type d -name "nvim" -not -path "$NVIM_DIR" 2>/dev/null || true)

if [ -n "$nested_issues" ]; then
    echo -e "${RED}✗ Found unexpected nested 'nvim' directories:${RESET}"
    echo "$nested_issues"
    echo -e "${YELLOW}These may cause confusion and should be investigated.${RESET}"
else
    echo -e "${GREEN}✓ No unexpected nested structures found${RESET}"
fi

# Summary
echo -e "\n${BLUE}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD}Structure Check Complete${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

echo -e "\n${GREEN}Expected structure:${RESET}"
echo -e "  ~/dotfiles/nvim/           (configuration directory)"
echo -e "  ~/.config/nvim → ~/dotfiles/nvim  (symlink)"

echo -e "\n${YELLOW}To verify everything works:${RESET}"
echo -e "  nvim --version"
echo -e "  nvim -c ':checkhealth user' -c ':q'"

exit 0 