#!/bin/bash
# Check and fix dotfiles repository structure issues
# Detects and fixes circular symlinks, nested directories, and other structural problems

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo -e "${BLUE}${BOLD}=========================================${RESET}"
echo -e "${BLUE}${BOLD}Dotfiles Structure Check${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

# Change to dotfiles directory
cd "$DOTFILES_DIR" || {
    echo -e "${RED}✗ Cannot access dotfiles directory: $DOTFILES_DIR${RESET}"
    exit 1
}

# Check for circular symlinks
echo -e "\n${YELLOW}Checking for circular symlinks...${RESET}"

circular_links_found=0

# Find all symlinks and check if they create circular references
while IFS= read -r symlink; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        symlink_name=$(basename "$symlink")
        symlink_dir=$(dirname "$symlink")
        
        # Check if the symlink name appears in its target path
        if [[ "$target" == *"$symlink_name"* ]] && [[ "$target" == *"$symlink_dir"* ]]; then
            echo -e "${RED}✗ Circular symlink found: $symlink → $target${RESET}"
            circular_links_found=$((circular_links_found + 1))
            
            read -p "Remove this circular symlink? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$symlink"
                echo -e "${GREEN}✓ Removed circular symlink: $symlink${RESET}"
            fi
        fi
    fi
done < <(find . -type l 2>/dev/null)

if [ $circular_links_found -eq 0 ]; then
    echo -e "${GREEN}✓ No circular symlinks found${RESET}"
fi

# Check for problematic nested directories
echo -e "\n${YELLOW}Checking for problematic nested directories...${RESET}"

nested_issues_found=0

# Common patterns that indicate problems
problematic_patterns=(
    "nvim/nvim"
    "zsh-completions/zsh-completions"
    "dotfiles/dotfiles"
    "scripts/scripts"
)

for pattern in "${problematic_patterns[@]}"; do
    if find . -path "*/$pattern" -type d 2>/dev/null | grep -q .; then
        echo -e "${RED}✗ Found problematic nested structure: $pattern${RESET}"
        find . -path "*/$pattern" -type d 2>/dev/null | while read -r nested_dir; do
            echo -e "  ${YELLOW}$nested_dir${RESET}"
        done
        nested_issues_found=$((nested_issues_found + 1))
    fi
done

if [ $nested_issues_found -eq 0 ]; then
    echo -e "${GREEN}✓ No problematic nested directories found${RESET}"
fi

# Check symlinks pointing outside dotfiles
echo -e "\n${YELLOW}Checking symlinks pointing outside dotfiles...${RESET}"

external_links_found=0

while IFS= read -r symlink; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        # Convert to absolute path if relative
        if [[ "$target" != /* ]]; then
            target=$(cd "$(dirname "$symlink")" && readlink -f "$target" 2>/dev/null || echo "$target")
        fi
        
        # Check if target is outside dotfiles directory
        if [[ "$target" != "$DOTFILES_DIR"* ]] && [[ "$target" != \$* ]] && [[ "$target" != "~"* ]]; then
            # Skip common system symlinks
            if [[ "$target" != "/Users/"* ]] && [[ "$target" != "/home/"* ]] && [[ "$target" != "/usr/"* ]]; then
                echo -e "${YELLOW}! Symlink points outside dotfiles: $symlink → $target${RESET}"
                external_links_found=$((external_links_found + 1))
            fi
        fi
    fi
done < <(find . -type l 2>/dev/null)

if [ $external_links_found -eq 0 ]; then
    echo -e "${GREEN}✓ All internal symlinks point within dotfiles directory${RESET}"
fi

# Check for broken symlinks
echo -e "\n${YELLOW}Checking for broken symlinks...${RESET}"

broken_links_found=0

while IFS= read -r symlink; do
    if [ -L "$symlink" ] && [ ! -e "$symlink" ]; then
        echo -e "${RED}✗ Broken symlink: $symlink → $(readlink "$symlink")${RESET}"
        broken_links_found=$((broken_links_found + 1))
        
        read -p "Remove this broken symlink? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$symlink"
            echo -e "${GREEN}✓ Removed broken symlink: $symlink${RESET}"
        fi
    fi
done < <(find . -type l 2>/dev/null)

if [ $broken_links_found -eq 0 ]; then
    echo -e "${GREEN}✓ No broken symlinks found${RESET}"
fi

# Check essential directory structure
echo -e "\n${YELLOW}Checking essential directory structure...${RESET}"

essential_dirs=(
    "nvim"
    "scripts/setup"
    "scripts/nvim"
    "scripts/utils"
    "zsh_custom"
)

missing_dirs=0

for dir in "${essential_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ $dir exists${RESET}"
    else
        echo -e "${RED}✗ $dir is missing${RESET}"
        missing_dirs=$((missing_dirs + 1))
    fi
done

if [ $missing_dirs -gt 0 ]; then
    echo -e "\n${YELLOW}Missing essential directories. This may indicate a structural problem.${RESET}"
fi

# Check for duplicate files/directories that shouldn't exist
echo -e "\n${YELLOW}Checking for potential duplicates...${RESET}"

# Find directories that have the same name as their parent
duplicate_dirs=$(find . -type d -exec basename {} \; | sort | uniq -d | while read -r dirname; do
    find . -name "$dirname" -type d | head -2 | tr '\n' ' '
    echo
done | grep -v "^[[:space:]]*$" || true)

if [ -n "$duplicate_dirs" ]; then
    echo -e "${YELLOW}! Found directories with duplicate names:${RESET}"
    echo "$duplicate_dirs"
else
    echo -e "${GREEN}✓ No obvious duplicate directories found${RESET}"
fi

# Summary
echo -e "\n${BLUE}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD}Structure Check Complete${RESET}"
echo -e "${BLUE}${BOLD}=========================================${RESET}"

total_issues=$((circular_links_found + nested_issues_found + broken_links_found + missing_dirs))

if [ $total_issues -eq 0 ]; then
    echo -e "\n${GREEN}✅ Repository structure appears healthy!${RESET}"
else
    echo -e "\n${YELLOW}⚠️  Found $total_issues structural issues${RESET}"
    echo -e "${BLUE}Issues breakdown:${RESET}"
    echo -e "  • Circular symlinks: $circular_links_found"
    echo -e "  • Nested directories: $nested_issues_found"
    echo -e "  • Broken symlinks: $broken_links_found"
    echo -e "  • Missing directories: $missing_dirs"
fi

echo -e "\n${YELLOW}For specific components:${RESET}"
echo -e "  • Nvim structure: ./scripts/nvim/check_structure.sh"
echo -e "  • Full setup: ./setup.sh"

exit 0 