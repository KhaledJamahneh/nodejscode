#!/usr/bin/env node

/**
 * Automated Button Migration Tool for Linux UI Redesign
 * Converts ElevatedButton, OutlinedButton, TextButton to PremiumButton
 */

const fs = require('fs');
const path = require('path');

const files = [
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
  'lib/features/client/presentation/screens/client_home_screen.dart',
  'lib/features/client/presentation/screens/request_water_screen.dart',
  'lib/features/worker/presentation/screens/worker_expenses_tab.dart',
  'lib/features/worker/presentation/screens/worker_home_screen.dart',
  'lib/features/worker/presentation/screens/worker_profile_tab.dart',
  'lib/features/notifications/presentation/screens/notifications_screen.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart',
  'lib/features/admin/presentation/screens/widgets/schedule_form_sheet.dart',
  'lib/features/client/presentation/widgets/client_side_drawer.dart',
];

function migrateFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  File not found: ${filePath}`);
    return { success: false, changes: 0 };
  }

  let content = fs.readFileSync(filePath, 'utf8');
  const originalContent = content;
  let changes = 0;

  // Simple pattern replacements for dialog buttons (keep TextButton for dialogs)
  // These are typically in actions: [] arrays
  
  // Replace ElevatedButton.icon patterns
  const elevatedIconPattern = /ElevatedButton\.icon\(\s*onPressed:\s*([^,]+),\s*icon:\s*Icon\(([^)]+)\),\s*label:\s*Text\(([^)]+)\)/g;
  content = content.replace(elevatedIconPattern, (match, onPressed, icon, label) => {
    changes++;
    return `PremiumButton(onPressed: ${onPressed}, icon: ${icon}, label: ${label})`;
  });

  // Replace OutlinedButton.icon patterns
  const outlinedIconPattern = /OutlinedButton\.icon\(\s*onPressed:\s*([^,]+),\s*icon:\s*Icon\(([^)]+)\),\s*label:\s*Text\(([^)]+)\)/g;
  content = content.replace(outlinedIconPattern, (match, onPressed, icon, label) => {
    changes++;
    return `PremiumButton(onPressed: ${onPressed}, icon: ${icon}, label: ${label}, variant: ButtonVariant.outlined)`;
  });

  // Replace simple ElevatedButton with child: Text()
  const elevatedSimplePattern = /ElevatedButton\(\s*onPressed:\s*([^,]+),\s*child:\s*Text\(([^)]+)\)\s*\)/g;
  content = content.replace(elevatedSimplePattern, (match, onPressed, label) => {
    changes++;
    return `PremiumButton(onPressed: ${onPressed}, label: ${label})`;
  });

  // Replace simple OutlinedButton with child: Text()
  const outlinedSimplePattern = /OutlinedButton\(\s*onPressed:\s*([^,]+),\s*child:\s*Text\(([^)]+)\)\s*\)/g;
  content = content.replace(outlinedSimplePattern, (match, onPressed, label) => {
    changes++;
    return `PremiumButton(onPressed: ${onPressed}, label: ${label}, variant: ButtonVariant.outlined)`;
  });

  // Remove SizedBox with double.infinity wrapping buttons
  content = content.replace(/SizedBox\(\s*width:\s*double\.infinity,\s*child:\s*PremiumButton\(/g, 'Center(child: PremiumButton(');
  
  // Remove style: ElevatedButton.styleFrom(...) patterns (no longer needed)
  content = content.replace(/,\s*style:\s*ElevatedButton\.styleFrom\([^)]*\)/g, '');
  content = content.replace(/,\s*style:\s*OutlinedButton\.styleFrom\([^)]*\)/g, '');

  if (content !== originalContent) {
    fs.writeFileSync(filePath + '.backup', originalContent);
    fs.writeFileSync(filePath, content);
    return { success: true, changes };
  }

  return { success: true, changes: 0 };
}

console.log('🚀 Starting Automated Button Migration...\n');

let totalChanges = 0;
let filesModified = 0;

files.forEach((file, index) => {
  console.log(`[${index + 1}/${files.length}] Processing: ${file}`);
  const result = migrateFile(file);
  
  if (result.success && result.changes > 0) {
    console.log(`   ✅ Migrated ${result.changes} button(s)`);
    totalChanges += result.changes;
    filesModified++;
  } else if (result.success) {
    console.log(`   ℹ️  No changes needed`);
  }
  console.log('');
});

console.log('\n✅ Migration Complete!');
console.log(`📊 Files modified: ${filesModified}/${files.length}`);
console.log(`🔄 Total button changes: ${totalChanges}`);
console.log('\n⚠️  Backups created with .backup extension');
console.log('\nNext steps:');
console.log('1. Run: flutter analyze');
console.log('2. Review changes: git diff');
console.log('3. Test: flutter run -d linux');
console.log('\nTo restore backups:');
console.log('  find lib -name "*.backup" -exec bash -c \'mv "$0" "${0%.backup}"\' {} \\;');
