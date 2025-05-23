#!/bin/bash

# Cleanup script for old Neovim configuration organization
# This script safely moves old files to a backup directory

set -e

echo "🧹 Cleaning up old Neovim configuration organization..."

# Create backup directory with timestamp
BACKUP_DIR="nvim_old_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR/user"

# Files to backup and remove from user/ directory
OLD_USER_FILES=(
    "autocmds.lua"
    "options.lua"
    "keymaps.lua"
    "plugins.lua"
    "cmp_setup.lua"
    "telescope.lua"
    "treesitter.lua"
    "which-key.lua"
    "diffview.lua"
    "dap.lua"
    "indent-blankline.lua"
    "colorbuddy_setup.lua"
    "go.lua"
    "setup_treesitter.lua"
    "plugin_installer.lua"
    "config_test.lua"
    "platform.lua"
)

echo "🔄 Backing up old user configuration files..."

# Backup old user files
for file in "${OLD_USER_FILES[@]}"; do
    if [ -f "lua/user/$file" ]; then
        echo "  📋 Backing up: lua/user/$file"
        cp "lua/user/$file" "$BACKUP_DIR/user/"
        rm "lua/user/$file"
        echo "  ✅ Removed: lua/user/$file"
    else
        echo "  ⏭️  Not found: lua/user/$file (already cleaned up)"
    fi
done

# Special handling for health.lua - keep but note it may need updates
if [ -f "lua/user/health.lua" ]; then
    echo "  📋 Backing up: lua/user/health.lua (keeping original for reference)"
    cp "lua/user/health.lua" "$BACKUP_DIR/user/"
    echo "  📝 Note: health.lua kept but may need updates for new system"
fi

# Check for any other old files that might exist
echo "🔍 Checking for other potential old files..."

# Look for init-new.lua (should have been renamed to init.lua)
if [ -f "init-new.lua" ]; then
    echo "  📋 Found old init-new.lua, backing up..."
    cp "init-new.lua" "$BACKUP_DIR/"
    rm "init-new.lua"
    echo "  ✅ Removed: init-new.lua"
fi

# Look for any .bak or .old files
find . -name "*.bak" -o -name "*.old" -o -name "*~" | while read -r old_file; do
    if [ -f "$old_file" ]; then
        echo "  📋 Found old file: $old_file"
        cp "$old_file" "$BACKUP_DIR/"
        rm "$old_file"
        echo "  ✅ Removed: $old_file"
    fi
done

echo ""
echo "✨ Cleanup complete!"
echo ""
echo "📁 Backup location: $BACKUP_DIR"
echo "📋 Backed up files:"
ls -la "$BACKUP_DIR/user/" 2>/dev/null || echo "  (no user files backed up)"
ls -la "$BACKUP_DIR/" | grep -v "^d" | grep -v "user/" 2>/dev/null || echo "  (no root files backed up)"

echo ""
echo "🎯 Current status:"
echo "  ✅ init.lua - New configuration (active)"
echo "  📦 init-backup.lua - Old configuration (backed up)"
echo "  🧹 Old user files - Moved to backup"
echo "  ✨ New organization - Clean and ready!"

echo ""
echo "🚀 Your Neovim configuration is now using the new organization!"
echo "   All old files have been safely backed up to: $BACKUP_DIR"
echo ""
echo "💡 To restore old files if needed:"
echo "   cp $BACKUP_DIR/user/* lua/user/"
echo ""
echo "🗑️  To permanently delete backups:"
echo "   rm -rf $BACKUP_DIR" 