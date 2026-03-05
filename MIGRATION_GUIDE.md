# Desktop Design Migration Guide

## Quick Migration Checklist

### ✅ Step 1: Update Buttons

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)
```

**After:**
```dart
PremiumButton(
  label: 'Submit',
  onPressed: () {},
)
```

**With Icon:**
```dart
PremiumButton(
  label: 'Add New',
  icon: Icons.add,
  onPressed: () {},
)
```

**Different Styles:**
```dart
// Primary (default)
PremiumButton(label: 'Save', onPressed: () {})

// Secondary
PremiumButton(label: 'Cancel', style: PremiumButtonStyle.secondary, onPressed: () {})

// Outline
PremiumButton(label: 'Edit', style: PremiumButtonStyle.outline, onPressed: () {})

// Danger
PremiumButton(label: 'Delete', style: PremiumButtonStyle.danger, onPressed: () {})
```

### ✅ Step 2: Update Text Fields

**Before:**
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter email',
  ),
)
```

**After:**
```dart
PremiumInput(
  label: 'Email',
  hint: 'Enter email',
  prefixIcon: Icons.email,
)
```

**With Validation:**
```dart
PremiumInput(
  label: 'Password',
  hint: 'Enter password',
  obscureText: true,
  errorText: _passwordError,
  helperText: 'Must be at least 8 characters',
)
```

### ✅ Step 3: Update Cards

**Before:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: YourContent(),
  ),
)
```

**After:**
```dart
PremiumCard(
  child: YourContent(),
)
```

### ✅ Step 4: Add Desktop Layout

**Before:**
```dart
Scaffold(
  appBar: AppBar(title: Text('Dashboard')),
  drawer: Drawer(...),
  body: YourContent(),
)
```

**After:**
```dart
Scaffold(
  body: DesktopLayout(
    sidebar: _buildSidebar(),
    content: YourContent(),
  ),
)
```

### ✅ Step 5: Update Typography

**Before:**
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
)
```

**After:**
```dart
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineSmall,
)
```

**Typography Reference:**
```dart
// Large headlines
Theme.of(context).textTheme.displayLarge    // 64px
Theme.of(context).textTheme.displayMedium   // 52px
Theme.of(context).textTheme.displaySmall    // 42px

// Section titles
Theme.of(context).textTheme.headlineLarge   // 36px
Theme.of(context).textTheme.headlineMedium  // 30px
Theme.of(context).textTheme.headlineSmall   // 26px

// Card headers
Theme.of(context).textTheme.titleLarge      // 22px
Theme.of(context).textTheme.titleMedium     // 18px
Theme.of(context).textTheme.titleSmall      // 15px

// Body text
Theme.of(context).textTheme.bodyLarge       // 17px
Theme.of(context).textTheme.bodyMedium      // 15px
Theme.of(context).textTheme.bodySmall       // 13px
```

### ✅ Step 6: Update Spacing

**Before:**
```dart
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(20))
```

**After:**
```dart
SizedBox(height: AppTheme.spacing16)
Padding(padding: EdgeInsets.all(AppTheme.spacing20))
```

**Spacing Scale:**
```dart
AppTheme.spacing4   // 4px
AppTheme.spacing8   // 8px
AppTheme.spacing12  // 12px
AppTheme.spacing16  // 16px
AppTheme.spacing20  // 20px
AppTheme.spacing24  // 24px
AppTheme.spacing32  // 32px
AppTheme.spacing40  // 40px
AppTheme.spacing48  // 48px
AppTheme.spacing64  // 64px
AppTheme.spacing80  // 80px
```

### ✅ Step 7: Update Colors

**Before:**
```dart
Color(0xFF0A4D8C)
Colors.blue
```

**After:**
```dart
AppTheme.primary
AppTheme.accent
AppTheme.success
AppTheme.error
AppTheme.warning
```

**Or use theme colors:**
```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).colorScheme.error
```

### ✅ Step 8: Add Responsive Behavior

**Before:**
```dart
Container(
  width: 300,
  child: YourWidget(),
)
```

**After:**
```dart
Container(
  width: AppTheme.isDesktop(context) ? 400 : 300,
  child: YourWidget(),
)
```

**Or use ResponsiveGrid:**
```dart
ResponsiveGrid(
  desktopColumns: 3,
  tabletColumns: 2,
  mobileColumns: 1,
  children: [
    Card1(),
    Card2(),
    Card3(),
  ],
)
```

## 🎯 Common Patterns

### Dashboard Stats
```dart
Row(
  children: [
    Expanded(
      child: StatCard(
        label: 'Total Orders',
        value: '1,234',
        icon: Icons.shopping_cart,
        trend: '+12%',
        isPositive: true,
      ),
    ),
    SizedBox(width: AppTheme.spacing16),
    Expanded(
      child: StatCard(
        label: 'Revenue',
        value: '\$45.2K',
        icon: Icons.attach_money,
        color: AppTheme.success,
      ),
    ),
  ],
)
```

### Section with Header
```dart
Column(
  children: [
    SectionHeader(
      title: 'Recent Activity',
      subtitle: 'Last 7 days',
      trailing: TextButton(
        onPressed: () {},
        child: Text('View All'),
      ),
    ),
    PremiumCard(
      child: YourContent(),
    ),
  ],
)
```

### Form Layout
```dart
PremiumCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'User Information',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      SizedBox(height: AppTheme.spacing24),
      PremiumInput(
        label: 'Full Name',
        hint: 'Enter your name',
        prefixIcon: Icons.person,
      ),
      SizedBox(height: AppTheme.spacing16),
      PremiumInput(
        label: 'Email',
        hint: 'Enter your email',
        prefixIcon: Icons.email,
        keyboardType: TextInputType.email,
      ),
      SizedBox(height: AppTheme.spacing24),
      Row(
        children: [
          PremiumButton(
            label: 'Save',
            icon: Icons.save,
            onPressed: () {},
          ),
          SizedBox(width: AppTheme.spacing12),
          PremiumButton(
            label: 'Cancel',
            style: PremiumButtonStyle.outline,
            onPressed: () {},
          ),
        ],
      ),
    ],
  ),
)
```

### Sidebar Navigation
```dart
Widget _buildSidebar() {
  return Column(
    children: [
      // Logo
      Container(
        height: 72,
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: AppTheme.primary),
            SizedBox(width: AppTheme.spacing12),
            Text(
              'Einhod',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      
      // Navigation items
      Expanded(
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacing16),
          children: [
            _NavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              isActive: true,
            ),
            _NavItem(
              icon: Icons.people,
              label: 'Clients',
            ),
            // ... more items
          ],
        ),
      ),
    ],
  );
}
```

## 🔄 File-by-File Migration

### Priority 1: Main Screens
1. Dashboard
2. Login/Auth screens
3. Main navigation

### Priority 2: Feature Screens
1. Client management
2. Delivery management
3. Worker screens

### Priority 3: Settings & Misc
1. Settings screens
2. Profile screens
3. About/Help screens

## 📝 Import Statements

Add these to files using the new components:

```dart
import 'package:einhod_water/core/theme/app_theme.dart';
import 'package:einhod_water/core/widgets/premium_button.dart';
import 'package:einhod_water/core/widgets/premium_input.dart';
import 'package:einhod_water/core/widgets/desktop_layout.dart';
```

## ⚡ Quick Wins

Start with these easy changes for immediate visual improvement:

1. **Replace all ElevatedButton** → `PremiumButton`
2. **Replace all TextField** → `PremiumInput`
3. **Wrap content in PremiumCard** for elevation
4. **Use theme text styles** instead of custom TextStyle
5. **Use AppTheme spacing** constants

## 🎨 Before & After Examples

### Login Screen

**Before:**
```dart
Column(
  children: [
    TextField(
      decoration: InputDecoration(labelText: 'Email'),
    ),
    SizedBox(height: 16),
    TextField(
      decoration: InputDecoration(labelText: 'Password'),
      obscureText: true,
    ),
    SizedBox(height: 24),
    ElevatedButton(
      onPressed: () {},
      child: Text('Login'),
    ),
  ],
)
```

**After:**
```dart
Column(
  children: [
    PremiumInput(
      label: 'Email',
      hint: 'Enter your email',
      prefixIcon: Icons.email,
    ),
    SizedBox(height: AppTheme.spacing16),
    PremiumInput(
      label: 'Password',
      hint: 'Enter your password',
      obscureText: true,
    ),
    SizedBox(height: AppTheme.spacing24),
    PremiumButton(
      label: 'Login',
      icon: Icons.login,
      isFullWidth: true,
      onPressed: () {},
    ),
  ],
)
```

## 🚀 Testing

After migration, test:
1. ✅ All buttons are clickable
2. ✅ Hover effects work on desktop
3. ✅ Forms validate properly
4. ✅ Responsive layout adapts
5. ✅ Dark mode looks good
6. ✅ Arabic text displays correctly

---

**Need help? Check `PREMIUM_DESKTOP_DESIGN.md` for full documentation!**
