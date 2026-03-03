# Migration Guide: Premium Design System

## Quick Start

### 1. Update Imports

**Before:**
```dart
import '../../theme/app_theme.dart';
```

**After:**
```dart
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/premium_text_field.dart';
```

### 2. Replace Standard Buttons

**Before:**
```dart
ElevatedButton(
  onPressed: _handleSubmit,
  child: _isLoading
      ? CircularProgressIndicator()
      : Text('Submit'),
)
```

**After:**
```dart
PremiumButton(
  text: 'Submit',
  onPressed: _handleSubmit,
  isLoading: _isLoading,
  icon: Icons.check,
)
```

### 3. Replace TextFields

**Before:**
```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter email',
    prefixIcon: Icon(Icons.email),
  ),
)
```

**After:**
```dart
PremiumTextField(
  label: 'Email',
  hint: 'Enter email',
  controller: _controller,
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
)
```

### 4. Replace Status Indicators

**Before:**
```dart
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.green,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Completed'),
)
```

**After:**
```dart
StatusBadge(status: 'completed')
// or
PriorityBadge(priority: 'urgent')
```

### 5. Update Cards

**Before:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(20),
    child: content,
  ),
)
```

**After:**
```dart
ModernCard(
  padding: EdgeInsets.all(16),
  child: content,
)
```

## Color Reference

Replace old colors with new formal palette:

| Old | New | Usage |
|-----|-----|-------|
| `Color(0xFF0A4D8C)` | `AppTheme.primary` | Primary actions |
| `Color(0xFF00B4D8)` | `AppTheme.secondary` | Secondary elements |
| `Color(0xFF10B981)` | `AppTheme.successGreen` | Success states |
| `Color(0xFFF97316)` | `AppTheme.midUrgentOrange` | Warnings |
| `Color(0xFFEF4444)` | `AppTheme.criticalRed` | Errors |

## Border Radius Standards

- Cards: `12-16px`
- Buttons: `12px`
- Inputs: `12px`
- Badges: `8px`
- Modals: `20px` (top corners only)

## Spacing Standards

- Card padding: `16px`
- Button padding: `horizontal: 24px, vertical: 14px`
- Section spacing: `16-24px`
- Item spacing: `8-12px`

## Testing Checklist

- [ ] All buttons have haptic feedback
- [ ] Loading states work correctly
- [ ] RTL layout works for Arabic
- [ ] Dark mode (if enabled) looks good
- [ ] Animations are smooth (60fps)
- [ ] Text is readable (contrast check)
- [ ] Touch targets are 44x44 minimum

## Common Patterns

### Form with Premium Components
```dart
Column(
  children: [
    PremiumTextField(
      label: 'Name',
      hint: 'Enter your name',
      prefixIcon: Icons.person,
    ),
    SizedBox(height: 16),
    PremiumTextField(
      label: 'Email',
      hint: 'Enter your email',
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
    ),
    SizedBox(height: 24),
    PremiumButton(
      text: 'Submit',
      icon: Icons.check,
      onPressed: _handleSubmit,
      isLoading: _isLoading,
    ),
  ],
)
```

### List Item with Status
```dart
ModernCard(
  onTap: () {},
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery #123', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 4),
            Text('Client Name', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      StatusBadge(status: 'completed'),
    ],
  ),
)
```

### Action Buttons Row
```dart
Row(
  children: [
    Expanded(
      child: PremiumButton(
        text: 'Cancel',
        isOutlined: true,
        onPressed: () {},
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: PremiumButton(
        text: 'Confirm',
        icon: Icons.check,
        onPressed: () {},
      ),
    ),
  ],
)
```
