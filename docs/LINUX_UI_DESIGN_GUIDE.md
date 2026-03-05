# Linux UI Design Guide - Android-Inspired Premium Design

## Design Philosophy

The Linux version follows Android Material 3 design principles:
- **Harmonious spacing** - Elements breathe with proper padding
- **Premium typography** - Roboto font family for Latin, Cairo for Arabic
- **Elegant proportions** - No full-width buttons, balanced layouts
- **Subtle elevation** - Minimal shadows, clean surfaces
- **Purposeful motion** - Smooth transitions and interactions

## Typography

### Font Families
- **Latin**: Roboto (Regular 400, Medium 500, Light 300)
- **Arabic**: Cairo (Regular 400, Medium 500, Light 300)

### Type Scale (Material 3)
```
Display Large:  57sp / Light 300
Display Medium: 45sp / Regular 400
Display Small:  36sp / Regular 400

Headline Large:  32sp / Regular 400
Headline Medium: 28sp / Regular 400
Headline Small:  24sp / Regular 400

Title Large:  22sp / Medium 500
Title Medium: 16sp / Medium 500
Title Small:  14sp / Medium 500

Body Large:  16sp / Regular 400 / 1.5 line height
Body Medium: 14sp / Regular 400 / 1.43 line height
Body Small:  12sp / Regular 400 / 1.33 line height

Label Large:  14sp / Medium 500
Label Medium: 12sp / Medium 500
Label Small:  11sp / Medium 500
```

## Buttons

### Button Variants

#### 1. Filled Button (Primary Actions)
```dart
PremiumButton(
  label: 'Continue',
  onPressed: () {},
  variant: ButtonVariant.filled,
  size: ButtonSize.medium,
)
```
- Use for primary actions
- High emphasis
- Elevated appearance

#### 2. Outlined Button (Secondary Actions)
```dart
PremiumButton(
  label: 'Cancel',
  onPressed: () {},
  variant: ButtonVariant.outlined,
  size: ButtonSize.medium,
)
```
- Use for secondary actions
- Medium emphasis
- Border with transparent background

#### 3. Text Button (Tertiary Actions)
```dart
PremiumButton(
  label: 'Learn More',
  onPressed: () {},
  variant: ButtonVariant.text,
  size: ButtonSize.medium,
)
```
- Use for low-priority actions
- Low emphasis
- No border or background

#### 4. Tonal Button (Alternative Primary)
```dart
PremiumButton(
  label: 'Save Draft',
  onPressed: () {},
  variant: ButtonVariant.tonal,
  size: ButtonSize.medium,
)
```
- Use for alternative primary actions
- Medium-high emphasis
- Colored background with lower opacity

### Button Sizes
- **Small**: 36dp height, 16dp horizontal padding
- **Medium**: 48dp height, 24dp horizontal padding
- **Large**: 56dp height, 32dp horizontal padding

### Button Guidelines
- ❌ **Never** use full-width buttons
- ✅ Use `width: null` or specific width (e.g., 200)
- ✅ Add icons for clarity: `icon: Icons.add`
- ✅ Show loading state: `isLoading: true`
- ✅ Proper spacing between buttons: 12-16dp

### Button Layout Examples

#### Single Button (Centered)
```dart
Center(
  child: PremiumButton(
    label: 'Submit',
    onPressed: () {},
  ),
)
```

#### Multiple Buttons (Row)
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  spacing: 12,
  children: [
    PremiumButton(
      label: 'Cancel',
      variant: ButtonVariant.outlined,
      onPressed: () {},
    ),
    PremiumButton(
      label: 'Confirm',
      onPressed: () {},
    ),
  ],
)
```

#### Button with Icon
```dart
PremiumButton(
  label: 'Add Item',
  icon: Icons.add,
  onPressed: () {},
)
```

## Cards

### Card Variants

#### 1. Modern Card (Default)
```dart
ModernCard(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Text('Content'),
)
```
- Flat design with minimal shadow
- Use for most content containers

#### 2. Elevated Card
```dart
ElevatedCard(
  padding: EdgeInsets.all(16),
  child: Text('Content'),
)
```
- Subtle shadow for emphasis
- Use for important content

#### 3. Outlined Card
```dart
OutlinedCard(
  padding: EdgeInsets.all(16),
  child: Text('Content'),
)
```
- Border with no shadow
- Use for grouped content

### Card Guidelines
- ✅ Border radius: 16dp (default)
- ✅ Padding: 16dp (default)
- ✅ Margin: 16dp horizontal, 8dp vertical
- ✅ Use InkWell for tap feedback
- ❌ Avoid excessive elevation

## Spacing System

### Padding Scale
```
4dp  - Minimal spacing
8dp  - Small spacing
12dp - Medium-small spacing
16dp - Medium spacing (default)
24dp - Large spacing
32dp - Extra large spacing
48dp - Section spacing
```

### Margin Scale
```
Horizontal: 16dp (default)
Vertical:   8dp (default)
Between sections: 24-32dp
```

## Input Fields

### Text Field Design
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
  ),
)
```

### Input Field Guidelines
- ✅ Border radius: 12dp
- ✅ Filled background with subtle color
- ✅ No border (use filled style)
- ✅ Focus border: 2dp primary color
- ✅ Content padding: 16dp
- ✅ Use prefix/suffix icons for clarity

## Icon Buttons

### Icon Button Variants

#### 1. Standard Icon Button
```dart
PremiumIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  variant: IconButtonVariant.standard,
)
```

#### 2. Filled Icon Button
```dart
PremiumIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  variant: IconButtonVariant.filled,
)
```

#### 3. Tonal Icon Button
```dart
PremiumIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  variant: IconButtonVariant.filledTonal,
)
```

#### 4. Outlined Icon Button
```dart
PremiumIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  variant: IconButtonVariant.outlined,
)
```

## Floating Action Buttons

### FAB Variants

#### Regular FAB
```dart
PremiumFAB(
  icon: Icons.add,
  onPressed: () {},
)
```

#### Extended FAB
```dart
PremiumFAB(
  icon: Icons.add,
  label: 'Add Item',
  extended: true,
  onPressed: () {},
)
```

### FAB Guidelines
- ✅ Use for primary screen action
- ✅ Position: bottom-right (16dp margin)
- ✅ One FAB per screen
- ❌ Don't use for navigation

## Color System

### Primary Colors
```dart
Primary:   #0A4D8C (Blue)
Accent:    #00B4D8 (Sky Blue)
Success:   #10B981 (Green)
Error:     #EF4444 (Red)
Warning:   #F97316 (Orange)
Info:      #3B82F6 (Blue)
```

### Surface Colors
```dart
Light Mode:
  Background: #F8F9FA
  Surface:    #FFFFFF
  Card:       #FFFFFF

Dark Mode:
  Background: #000000
  Surface:    #1C1C1E
  Card:       #2C2C2E
```

### Text Colors
```dart
Light Mode:
  Primary:   #1C1C1E
  Secondary: #636366

Dark Mode:
  Primary:   #FFFFFF
  Secondary: #E5E5EA
```

## Layout Guidelines

### Screen Structure
```
┌─────────────────────────┐
│      App Bar (56dp)     │
├─────────────────────────┤
│                         │
│   Content (16dp pad)    │
│                         │
│   ┌───────────────┐     │
│   │  Card         │     │
│   └───────────────┘     │
│                         │
│   ┌───────────────┐     │
│   │  Card         │     │
│   └───────────────┘     │
│                         │
└─────────────────────────┘
```

### Content Padding
- Screen edges: 16dp
- Between cards: 8dp vertical
- Section spacing: 24-32dp

### Maximum Width
- Content max width: 600dp (for large screens)
- Center content on wide screens

## Dialogs

### Dialog Design
```dart
PremiumDialog.show(
  context,
  title: 'Confirm Action',
  subtitle: 'Are you sure?',
  icon: Icons.warning,
  actions: [
    DialogAction(
      label: 'Cancel',
      onTap: () => Navigator.pop(context),
    ),
    DialogAction(
      label: 'Confirm',
      onTap: () {
        // Action
        Navigator.pop(context);
      },
    ),
  ],
)
```

### Dialog Guidelines
- ✅ Border radius: 24dp
- ✅ Padding: 24dp
- ✅ Max width: 400dp
- ✅ Actions aligned right
- ✅ Use text buttons for actions

## Lists

### List Item Design
```dart
ListTile(
  leading: Icon(Icons.person),
  title: Text('Title'),
  subtitle: Text('Subtitle'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)
```

### List Guidelines
- ✅ Item height: 56-72dp
- ✅ Leading icon: 24dp
- ✅ Padding: 16dp horizontal
- ✅ Divider: 1dp, subtle color
- ✅ Use InkWell for tap feedback

## Bottom Sheets

### Bottom Sheet Design
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: 24),
        // Content
      ],
    ),
  ),
)
```

### Bottom Sheet Guidelines
- ✅ Border radius: 24dp (top only)
- ✅ Handle: 40x4dp, centered
- ✅ Padding: 24dp
- ✅ Max height: 90% screen

## Chips

### Chip Design
```dart
StatusChip(
  label: 'Active',
  color: AppTheme.success,
  icon: Icons.check_circle,
)
```

### Chip Guidelines
- ✅ Border radius: 20dp (pill shape)
- ✅ Padding: 12dp horizontal, 6dp vertical
- ✅ Font size: 11sp
- ✅ Font weight: 700 (Bold)
- ✅ Letter spacing: 0.5

## Animations

### Duration Scale
```
Fast:     150ms (micro-interactions)
Normal:   250ms (default)
Slow:     350ms (complex transitions)
```

### Curves
```
Standard:     Curves.easeInOut
Emphasized:   Curves.easeOutCubic
Decelerated:  Curves.easeOut
```

## Accessibility

### Touch Targets
- Minimum: 48x48dp
- Recommended: 56x56dp for primary actions

### Contrast Ratios
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum
- Icons: 3:1 minimum

### Focus Indicators
- Visible focus ring
- 2dp border
- Primary color

## Best Practices

### DO ✅
- Use consistent spacing (8dp grid)
- Provide visual feedback for interactions
- Use semantic colors (success, error, warning)
- Keep button labels concise (1-2 words)
- Use icons to enhance clarity
- Maintain proper contrast ratios
- Test with both light and dark themes

### DON'T ❌
- Use full-width buttons
- Mix different design patterns
- Use excessive shadows
- Overcrowd the interface
- Use too many colors
- Ignore touch target sizes
- Forget loading states

## Migration from Old Design

### Button Migration
```dart
// OLD (Full-width)
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Submit'),
  ),
)

// NEW (Harmonious)
Center(
  child: PremiumButton(
    label: 'Submit',
    onPressed: () {},
  ),
)
```

### Card Migration
```dart
// OLD
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)

// NEW
ModernCard(
  child: Text('Content'),
)
```

## Component Import

```dart
// Import premium components
import 'package:einhod_water/core/widgets/premium_button.dart';
import 'package:einhod_water/core/widgets/modern_card.dart';
import 'package:einhod_water/core/theme/app_theme.dart';
```

---

**Remember**: The goal is to create a harmonious, elegant interface that feels premium and professional, inspired by Android's Material 3 design language.
