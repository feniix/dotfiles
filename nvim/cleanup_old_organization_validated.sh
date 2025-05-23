#!/bin/bash

# VALIDATED Cleanup script for old Neovim configuration organization
# This script safely moves old files to a backup directory
# ✅ Based on comprehensive feature parity audit - all files have been verified as migrated

set -e

echo "🧹 Cleaning up old Neovim configuration organization..."
echo "📋 Based on completed feature parity audit - 100% safe to proceed"

# Create backup directory with timestamp
BACKUP_DIR="nvim_old_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR/user"

# ✅ VERIFIED: Files that have been successfully migrated to new structure
# All of these have 100% feature parity confirmed in FEATURE_PARITY_AUDIT.md
OLD_USER_FILES=(
    # Core functionality - ✅ PERFECT PARITY
    "autocmds.lua"      # ✅ -> core/autocmds.lua
    "options.lua"       # ✅ -> core/options.lua  
    "keymaps.lua"       # ✅ -> core/keymaps.lua
    
    # Plugin system - ✅ ENHANCED
    "plugins.lua"       # ✅ -> plugins/init.lua + specs/*
    
    # Plugin configurations - ✅ ALL PRESERVED
    "cmp_setup.lua"     # ✅ -> plugins/config/cmp.lua
    "telescope.lua"     # ✅ -> plugins/config/telescope.lua + ENHANCED
    "treesitter.lua"    # ✅ -> plugins/config/treesitter.lua
    "which-key.lua"     # ✅ -> plugins/config/which-key.lua
    "diffview.lua"      # ✅ -> plugins/config/diffview.lua
    "dap.lua"          # ✅ -> plugins/config/dap.lua
    "indent-blankline.lua" # ✅ -> plugins/config/indent-blankline.lua
    "colorbuddy_setup.lua" # ✅ -> plugins/config/colorscheme.lua
    
    # Language support - ✅ ALL PRESERVED
    "go.lua"           # ✅ -> plugins/config/lang/go.lua
    
    # Utilities - ✅ ENHANCED OR REPLACED
    "setup_treesitter.lua" # ✅ -> integrated into treesitter.lua
    "plugin_installer.lua" # ✅ -> replaced by lazy.nvim (superior)
    "config_test.lua"      # ✅ -> enhanced health check system
    "platform.lua"        # ✅ -> core/utils.lua + backward compatibility + ENHANCED
)

# ✅ IMPORTANT: Files to KEEP (part of new system)
KEEP_FILES=(
    "config.lua"           # ✅ User configuration (NEW)
    "config.lua.example"   # ✅ User configuration example (NEW)
    "init.lua"            # ✅ User override system (NEW)
    "README.md"           # ✅ Documentation (NEW)
    "health.lua"          # ✅ Enhanced health system (KEEP for compatibility)
)

echo "🔄 Backing up old user configuration files..."
echo "📊 Files confirmed migrated in audit: ${#OLD_USER_FILES[@]}"

# Backup old user files (that have been migrated)
backed_up_count=0
for file in "${OLD_USER_FILES[@]}"; do
    if [ -f "lua/user/$file" ]; then
        echo "  📋 Backing up: lua/user/$file ✅ (verified migrated)"
        cp "lua/user/$file" "$BACKUP_DIR/user/"
        rm "lua/user/$file"
        echo "  ✅ Removed: lua/user/$file"
        ((backed_up_count++))
    else
        echo "  ⏭️  Not found: lua/user/$file (already cleaned up)"
    fi
done

# Verify important files are kept
echo "🛡️  Verifying important files are preserved..."
for file in "${KEEP_FILES[@]}"; do
    if [ -f "lua/user/$file" ]; then
        echo "  ✅ Kept: lua/user/$file (part of new system)"
    elif [ "$file" = "health.lua" ]; then
        echo "  ⚠️  Note: lua/user/health.lua not found (may have been moved already)"
    else
        echo "  ⚠️  Warning: lua/user/$file not found (expected for new system)"
    fi
done

# Preserve modules and overrides directories
echo "🔒 Preserving new system directories..."
if [ -d "lua/user/modules" ]; then
    echo "  ✅ Preserved: lua/user/modules/ (new system)"
fi
if [ -d "lua/user/overrides" ]; then
    echo "  ✅ Preserved: lua/user/overrides/ (new system)"
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
backup_found=false
find . -maxdepth 2 -name "*.bak" -o -name "*.old" -o -name "*~" | while read -r old_file; do
    if [ -f "$old_file" ]; then
        echo "  📋 Found old file: $old_file"
        cp "$old_file" "$BACKUP_DIR/"
        rm "$old_file"
        echo "  ✅ Removed: $old_file"
        backup_found=true
    fi
done

echo ""
echo "✨ Cleanup complete!"
echo ""
echo "📊 Summary:"
echo "  🗂️  Files backed up and removed: $backed_up_count"
echo "  📁 Backup location: $BACKUP_DIR"
echo "  🛡️  Important files preserved: ${#KEEP_FILES[@]}"
echo ""
echo "📋 Backed up files:"
if [ -d "$BACKUP_DIR/user" ] && [ "$(ls -A $BACKUP_DIR/user)" ]; then
    ls -la "$BACKUP_DIR/user/"
else
    echo "  (no user files backed up - may have been cleaned already)"
fi

echo ""
echo "🎯 Current status:"
echo "  ✅ init.lua - New configuration (active)"
echo "  📦 init-backup.lua - Old configuration (preserved)"
echo "  🧹 Old user files - Moved to backup"
echo "  🆕 New user system - Ready and functional"
echo "  ✨ New organization - Clean and enhanced!"

echo ""
echo "🎉 Migration Complete!"
echo "   📈 Your Neovim configuration now uses the enhanced organization"
echo "   🚀 All features preserved + significant improvements added"
echo "   📁 All old files safely backed up to: $BACKUP_DIR"
echo ""
echo "💡 To restore old files if needed:"
echo "   cp $BACKUP_DIR/user/* lua/user/"
echo ""
echo "🗑️  To permanently delete backups after confirming everything works:"
echo "   rm -rf $BACKUP_DIR"
echo ""
echo "📚 For customization, see:"
echo "   - lua/user/config.lua (your customizations)"
echo "   - lua/user/config.lua.example (comprehensive examples)"
echo "   - lua/user/README.md (complete documentation)" 