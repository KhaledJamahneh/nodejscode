# Quick Reference: Using Extracted Widgets

## Import Once
```dart
import '../widgets/widgets.dart'; // Gets all admin widgets
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
```

## Replace Patterns

### 1. User Cards
**Before:**
```dart
Card(
  child: ListTile(
    leading: Icon(...),
    title: Text(user.username),
    // ... lots of code
  ),
)
```

**After:**
```dart
UserCard(
  user: user,
  onTap: () => _showUserDetails(user.id),
  onToggleActive: () => _toggleUserActive(user),
  onEdit: () => _editUser(user),
  onDelete: () => _deleteUser(user),
)
```

### 2. Filter Chips
**Before:**
```dart
GestureDetector(
  onTap: () => setState(...),
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(...),
    child: Text(label),
  ),
)
```

**After:**
```dart
UserFilterChip(
  label: 'Active',
  isSelected: filter.status == 'active',
  onTap: () => ref.read(filterProvider.notifier).setStatus('active'),
  icon: Icons.check_circle,
)
```

### 3. Dashboard Stats
**Before:**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(...),
  child: Column(
    children: [
      Icon(...),
      Text('Total Users'),
      Text('150'),
    ],
  ),
)
```

**After:**
```dart
StatCard(
  title: 'Total Users',
  value: '150',
  icon: Icons.people,
  color: AppTheme.primary,
  subtitle: '+12 this week',
  onTap: () => context.push('/users'),
)
```

### 4. Section Headers
**Before:**
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextButton(...),
    ],
  ),
)
```

**After:**
```dart
SectionTitle(
  title: 'Recent Activity',
  trailing: TextButton(
    onPressed: () => context.push('/activity'),
    child: Text('View All'),
  ),
)
```

### 5. Detail Rows
**Before:**
```dart
Row(
  children: [
    Text('Phone:', style: TextStyle(color: Colors.grey)),
    Spacer(),
    Text(user.phone, style: TextStyle(fontWeight: FontWeight.bold)),
  ],
)
```

**After:**
```dart
DetailRow(
  label: 'Phone',
  value: user.phone,
  icon: Icons.phone,
)
```

## Spacing

**Before:**
```dart
padding: EdgeInsets.all(16)
margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8)
SizedBox(height: 12)
```

**After:**
```dart
padding: EdgeInsets.all(AppSpacing.lg)
margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm)
SizedBox(height: AppSpacing.md)
```

## Border Radius

**Before:**
```dart
BorderRadius.circular(12)
BorderRadius.circular(16)
BorderRadius.circular(999)
```

**After:**
```dart
BorderRadius.circular(AppRadius.md)  // buttons, inputs
BorderRadius.circular(AppRadius.lg)  // cards
BorderRadius.circular(AppRadius.round)  // avatars
```

## Existing Premium Widgets

### Empty States
```dart
EmptyStateWidget(
  icon: Icons.inbox,
  title: 'No users found',
  message: 'Try adjusting your filters',
  actionLabel: 'Clear Filters',
  onAction: () => ref.read(filterProvider.notifier).reset(),
)
```

### Loading
```dart
ShimmerLoading(
  child: Column(
    children: List.generate(5, (_) => Skeletons.card()),
  ),
)
```

### Buttons
```dart
PremiumButton(
  text: 'Save Changes',
  onPressed: _save,
  icon: Icons.save,
  isLoading: isLoading,
)
```

### Search
```dart
SearchBarWidget(
  controller: _searchController,
  hintText: 'Search users...',
  onChanged: (query) => ref.read(searchProvider.notifier).state = query,
)
```

### Status Badges
```dart
StatusBadge(
  label: 'Active',
  color: AppTheme.successGreen,
  icon: Icons.check_circle,
)
```

## Tips

1. **Import once** - Use `widgets.dart` to get all admin widgets
2. **Use constants** - Always use AppSpacing and AppRadius
3. **Reuse existing** - Check core/widgets before creating new ones
4. **Keep it simple** - Extract when you see duplication
5. **Test as you go** - Hot reload works great with these widgets

## When to Extract New Widgets

Extract when you see:
- Same code in 3+ places
- Widget > 100 lines
- Complex nested structure
- Reusable pattern

## File Structure
```
lib/features/admin/presentation/
├── screens/
│   └── admin_users_screen.dart  (use widgets here)
└── widgets/
    ├── user_card.dart
    ├── user_filter_chip.dart
    ├── stat_card.dart
    ├── section_title.dart
    ├── detail_row.dart
    └── widgets.dart  (exports all)
```

## Need Help?

Check `/docs/frontend-refactoring-progress.md` for full status and examples.
