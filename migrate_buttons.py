#!/usr/bin/env python3
"""
Intelligent Button Migration Tool for Linux UI Redesign
Converts Flutter buttons to PremiumButton with proper syntax
"""

import re
import sys
from pathlib import Path

# Files to migrate
FILES = [
    'lib/features/admin/presentation/screens/admin_shifts_screen.dart',
    'lib/features/admin/presentation/screens/admin_users_screen.dart',
    'lib/features/admin/presentation/screens/admin_settings_screen.dart',
    'lib/features/admin/presentation/screens/admin_schedules_screen.dart',
    'lib/features/admin/presentation/screens/admin_home_screen.dart',
    'lib/features/admin/presentation/screens/admin_assets_screen.dart',
    'lib/features/admin/presentation/screens/admin_analytics_screen.dart',
    'lib/features/admin/presentation/screens/admin_coupon_settings_screen.dart',
    'lib/features/admin/presentation/screens/admin_deliveries_screen.dart',
    'lib/features/admin/presentation/screens/admin_expenses_screen.dart',
    'lib/features/admin/presentation/screens/dispenser_detail_screen.dart',
    'lib/features/admin/presentation/screens/dispenser_settings_screen.dart',
    'lib/features/admin/presentation/screens/admin_requests_screen.dart',
    'lib/features/admin/presentation/screens/admin_dashboard_screen.dart',
    'lib/features/client/presentation/screens/track_delivery_screen.dart',
    'lib/features/client/presentation/screens/buy_coupons_screen.dart',
    'lib/features/client/presentation/screens/client_payments_screen.dart',
    'lib/features/client/presentation/screens/client_requests_screen.dart',
    'lib/features/client/presentation/screens/client_dispensers_screen.dart',
    'lib/features/worker/presentation/screens/worker_expenses_tab.dart',
    'lib/features/worker/presentation/screens/worker_home_screen.dart',
    'lib/features/worker/presentation/screens/worker_profile_tab.dart',
    'lib/features/notifications/presentation/screens/notifications_screen.dart',
    'lib/features/settings/presentation/screens/settings_screen.dart',
    'lib/features/admin/presentation/screens/widgets/schedule_form_sheet.dart',
    'lib/features/client/presentation/widgets/client_side_drawer.dart',
]

def migrate_simple_buttons(content):
    """Migrate simple button patterns"""
    changes = 0
    
    # Pattern 1: TextButton(onPressed: X, child: Text(Y))
    pattern1 = r'TextButton\(\s*onPressed:\s*([^,]+),\s*child:\s*Text\(([^)]+)\)\s*\)'
    def repl1(m):
        nonlocal changes
        changes += 1
        return f'PremiumButton(onPressed: {m.group(1)}, label: {m.group(2)}, variant: ButtonVariant.text, size: ButtonSize.small)'
    content = re.sub(pattern1, repl1, content)
    
    # Pattern 2: ElevatedButton(onPressed: X, child: Text(Y))
    pattern2 = r'ElevatedButton\(\s*onPressed:\s*([^,]+),\s*child:\s*Text\(([^)]+)\)\s*\)'
    def repl2(m):
        nonlocal changes
        changes += 1
        return f'PremiumButton(onPressed: {m.group(1)}, label: {m.group(2)})'
    content = re.sub(pattern2, repl2, content)
    
    # Pattern 3: OutlinedButton(onPressed: X, child: Text(Y))
    pattern3 = r'OutlinedButton\(\s*onPressed:\s*([^,]+),\s*child:\s*Text\(([^)]+)\)\s*\)'
    def repl3(m):
        nonlocal changes
        changes += 1
        return f'PremiumButton(onPressed: {m.group(1)}, label: {m.group(2)}, variant: ButtonVariant.outlined)'
    content = re.sub(pattern3, repl3, content)
    
    return content, changes

def remove_button_styles(content):
    """Remove old button style declarations"""
    # Remove style: ElevatedButton.styleFrom(...)
    content = re.sub(r',\s*style:\s*ElevatedButton\.styleFrom\([^)]*\)', '', content)
    content = re.sub(r',\s*style:\s*OutlinedButton\.styleFrom\([^)]*\)', '', content)
    content = re.sub(r',\s*style:\s*TextButton\.styleFrom\([^)]*\)', '', content)
    return content

def migrate_file(filepath):
    """Migrate a single file"""
    path = Path(filepath)
    
    if not path.exists():
        print(f"⚠️  File not found: {filepath}")
        return False
    
    # Read content
    content = path.read_text(encoding='utf-8')
    original = content
    
    # Count buttons before
    before_count = (
        content.count('ElevatedButton') +
        content.count('OutlinedButton') +
        content.count('TextButton')
    )
    
    if before_count == 0:
        print(f"   ✅ No buttons to migrate")
        return True
    
    print(f"   Found {before_count} button instance(s)")
    
    # Apply migrations
    content, changes = migrate_simple_buttons(content)
    content = remove_button_styles(content)
    
    # Only write if changes were made
    if content != original:
        # Create backup
        backup_path = path.with_suffix('.dart.backup')
        backup_path.write_text(original, encoding='utf-8')
        
        # Write updated content
        path.write_text(content, encoding='utf-8')
        print(f"   ✅ Migrated {changes} button(s), backup created")
        return True
    else:
        print(f"   ⚠️  No automatic changes possible, manual review needed")
        return False

def main():
    print("🚀 Starting Intelligent Button Migration...\n")
    
    total = len(FILES)
    migrated = 0
    manual_review = 0
    
    for i, filepath in enumerate(FILES, 1):
        print(f"[{i}/{total}] Processing: {filepath}")
        
        if migrate_file(filepath):
            migrated += 1
        else:
            manual_review += 1
        
        print()
    
    print("\n✅ Migration Complete!")
    print(f"📊 Files processed: {migrated}/{total}")
    if manual_review > 0:
        print(f"⚠️  Files needing manual review: {manual_review}")
    
    print("\n⚠️  Backups created with .backup extension")
    print("\nNext steps:")
    print("1. Run: flutter analyze")
    print("2. Review changes: git diff")
    print("3. Test: flutter run -d linux")
    print("\nTo restore backups:")
    print("  find lib -name '*.backup' -exec bash -c 'mv \"$0\" \"${0%.backup}\"' {} \\;")

if __name__ == '__main__':
    main()
