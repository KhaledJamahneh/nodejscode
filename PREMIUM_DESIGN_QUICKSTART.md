# Premium Design System - Quick Start

## 🎨 Overview

The Linux version now uses an Android Material 3-inspired design system with:
- **Roboto font** for premium typography
- **Harmonious spacing** - no full-width buttons
- **4 button variants** - Filled, Outlined, Text, Tonal
- **3 card types** - Modern, Elevated, Outlined
- **Complete type scale** - Display, Headline, Title, Body, Label

## 📦 Components

### Buttons

```dart
import 'package:einhod_water/core/widgets/premium_button.dart';

// Primary action
PremiumButton(
  label: 'Continue',
  onPressed: () {},
)

// Secondary action
PremiumButton(
  label: 'Cancel',
  variant: ButtonVariant.outlined,
  onPressed: () {},
)

// With icon
PremiumButton(
  label: 'Add Item',
  icon: Icons.add,
  onPressed: () {},
)

// Loading state
PremiumButton(
  label: 'Saving',
  isLoading: true,
  onPressed: () {},
)
```

### Cards

```dart
import 'package:einhod_water/core/widgets/modern_card.dart';

// Flat card
ModernCard(
  child: Text('Content'),
)

// Card with shadow
ElevatedCard(
  child: Text('Important content'),
)

// Card with border
OutlinedCard(
  child: Text('Grouped content'),
)
```

### Icon Buttons

```dart
// Standard
PremiumIconButton(
  icon: Icons.favorite,
  onPressed: () {},
)

// Filled
PremiumIconButton(
  icon: Icons.favorite,
  variant: IconButtonVariant.filled,
  onPressed: () {},
)
```

### FAB

```dart
// Regular FAB
PremiumFAB(
  icon: Icons.add,
  onPressed: () {},
)

// Extended FAB
PremiumFAB(
  icon: Icons.add,
  label: 'New Order',
  extended: true,
  onPressed: () {},
)
```

## 🎯 Key Principles

### ✅ DO
- Use `PremiumButton` instead of `ElevatedButton`
- Center buttons or use natural width
- Add 12-16dp spacing between buttons
- Use proper card variants
- Follow the 8dp spacing grid
- Use Roboto font (automatic)

### ❌ DON'T
- Use full-width buttons
- Use `SizedBox(width: double.infinity)` for buttons
- Mix old and new components
- Ignore spacing guidelines
- Use excessive shadows

## 📐 Spacing

```dart
// Small spacing
SizedBox(height: 8)

// Medium spacing (default)
SizedBox(height: 16)

// Large spacing
SizedBox(height: 24)

// Section spacing
SizedBox(height: 32)
```

## 🔤 Typography

```dart
// Large heading
Text('Title', style: Theme.of(context).textTheme.headlineLarge)

// Medium heading
Text('Subtitle', style: Theme.of(context).textTheme.headlineMedium)

// Body text
Text('Content', style: Theme.of(context).textTheme.bodyLarge)

// Small text
Text('Caption', style: Theme.of(context).textTheme.bodySmall)
```

## 📱 Layout Examples

### Single Button
```dart
Center(
  child: PremiumButton(
    label: 'Submit',
    onPressed: () {},
  ),
)
```

### Multiple Buttons
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    PremiumButton(
      label: 'Cancel',
      variant: ButtonVariant.outlined,
      onPressed: () {},
    ),
    SizedBox(width: 12),
    PremiumButton(
      label: 'Confirm',
      onPressed: () {},
    ),
  ],
)
```

### Form Layout
```dart
ModernCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
        ),
      ),
      SizedBox(height: 16),
      TextField(
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock),
        ),
      ),
      SizedBox(height: 24),
      Center(
        child: PremiumButton(
          label: 'Login',
          onPressed: () {},
        ),
      ),
    ],
  ),
)
```

## 📚 Resources

- **Full Guide**: `docs/LINUX_UI_DESIGN_GUIDE.md`
- **Summary**: `docs/LINUX_UI_UPDATE_SUMMARY.md`
- **Showcase**: `lib/core/widgets/premium_showcase.dart`
- **Example**: `lib/features/example_premium_screen.dart`

## 🚀 Getting Started

1. **Import components**:
```dart
import 'package:einhod_water/core/widgets/premium_button.dart';
import 'package:einhod_water/core/widgets/modern_card.dart';
```

2. **Replace old buttons**:
```dart
// OLD
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)

// NEW
PremiumButton(
  label: 'Submit',
  onPressed: () {},
)
```

3. **Test on Linux**:
```bash
flutter run -d linux
```

## 🎨 View Examples

To see all components in action:

1. Add route to showcase:
```dart
GoRoute(
  path: '/showcase',
  builder: (context, state) => PremiumComponentsShowcase(),
)
```

2. Navigate to `/showcase` in your app

Or view the example screen:
```dart
GoRoute(
  path: '/example',
  builder: (context, state) => ExamplePremiumScreen(),
)
```

## 💡 Tips

- Use `variant: ButtonVariant.outlined` for secondary actions
- Use `variant: ButtonVariant.text` for low-priority actions
- Use `variant: ButtonVariant.tonal` for alternative primary actions
- Add `icon:` parameter for clarity
- Use `isLoading: true` for async operations
- Keep button labels short (1-2 words)
- Use proper spacing (12-16dp between elements)

## 🎯 Migration Checklist

- [ ] Replace `ElevatedButton` with `PremiumButton`
- [ ] Remove `SizedBox(width: double.infinity)` from buttons
- [ ] Center buttons or use natural width
- [ ] Update card components to use `ModernCard`, `ElevatedCard`, or `OutlinedCard`
- [ ] Add proper spacing between elements
- [ ] Use theme typography instead of hardcoded styles
- [ ] Test with both light and dark themes
- [ ] Verify touch targets are at least 48dp

---

**Design Philosophy**: Harmonious, elegant, and professional - inspired by Android Material 3.
