# 🎨 Einhod Water App - Redesign & Localization Guide

## 🚀 Quick Start

### Start Everything
```bash
./start.sh
```

This will:
1. Start the backend API server
2. Install dependencies if needed
3. Generate localization files
4. Launch the Flutter app

### Start Backend Only
```bash
npm start
```

### Start Frontend Only
```bash
flutter run
```

## 📱 What's New

### ✨ Design System (UID-Inspired)

The app now follows a modern, clean design system inspired by the UID mockups:

**Colors:**
- Primary Blue: `#137FEC` (bright, trustworthy)
- Backgrounds: Light `#F6F7F8`, Dark `#101922`
- Surfaces: Light `#FFFFFF`, Dark `#1A2632`
- Text: Main `#0E141B`, Secondary `#4E7397`

**Typography:**
- Font: Manrope (clean, modern sans-serif)
- Weights: Regular (400), Medium (500), Bold (700), Extra Bold (800)

**Components:**
- Rounded corners (16px, 24px, 32px)
- Subtle shadows and borders
- Backdrop blur effects on headers
- Smooth transitions and animations

### 🌍 Full Localization

The app is fully localized in:
- **English** (en)
- **Arabic** (ar) with RTL support

All UI strings are translated, including:
- Screen titles and labels
- Button text
- Error messages
- Success messages
- Notifications
- Dialog messages

### 🎯 New Components

Located in `lib/core/widgets/uid_components.dart`:

1. **UIDFilterChip** - Rounded pill-shaped filter chips
2. **UIDSearchBar** - Search bar with icons
3. **UIDMetricCard** - Dashboard metric cards with trends
4. **UIDStickyHeader** - Headers with backdrop blur
5. **UIDStatusBadge** - Status indicators
6. **UIDActionButton** - Action buttons with icons

## 📂 Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # Theme system
│   ├── widgets/
│   │   ├── uid_components.dart     # NEW: UID-inspired components
│   │   └── feedback_widgets.dart   # Feedback components
│   ├── router/
│   │   └── app_router.dart         # Navigation
│   ├── providers/
│   │   ├── locale_provider.dart    # Language switching
│   │   └── theme_provider.dart     # Dark mode
│   ├── services/
│   │   ├── storage_service.dart    # Local storage
│   │   └── location_service.dart   # GPS tracking
│   └── network/
│       └── dio_client.dart         # API client
├── features/
│   ├── auth/                       # Authentication
│   ├── client/                     # Client features
│   ├── worker/                     # Worker features
│   ├── admin/                      # Admin features
│   └── notifications/              # Notifications
├── screens/
│   ├── auth/
│   │   └── login_screen.dart       # Login screen
│   ├── client/
│   │   └── client_home_screen.dart # Client dashboard
│   ├── worker/
│   │   └── worker_home_screen.dart # Worker dashboard
│   ├── admin/
│   │   └── admin_dashboard_screen.dart # Admin dashboard
│   └── station/
│       └── station_dashboard_screen.dart # Station dashboard
├── l10n/
│   ├── app_en.arb                  # English translations
│   ├── app_ar.arb                  # Arabic translations
│   └── app_localizations.dart      # Generated
└── main.dart                       # App entry point
```

## 🎨 Using the New Components

### Filter Chips

```dart
UIDFilterChipRow(
  labels: ['All', 'Pending', 'Completed'],
  selectedIndex: 0,
  onSelected: (index) {
    // Handle selection
  },
)
```

### Search Bar

```dart
UIDSearchBar(
  hintText: 'Search deliveries...',
  onChanged: (value) {
    // Handle search
  },
  onFilterTap: () {
    // Show filters
  },
)
```

### Metric Card

```dart
UIDMetricCard(
  title: 'Total Orders Today',
  value: '142',
  icon: Icons.shopping_cart,
  iconColor: AppTheme.primaryColor,
  iconBackgroundColor: AppTheme.primaryLight,
  trend: '+12%',
  isTrendPositive: true,
  onTap: () {
    // Navigate to details
  },
)
```

### Sticky Header

```dart
UIDStickyHeader(
  title: 'Worker Management',
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  trailing: UIDActionButton(
    label: 'Add New',
    icon: Icons.add,
    onTap: () {
      // Add new worker
    },
  ),
  bottom: UIDSearchBar(
    hintText: 'Search workers...',
  ),
)
```

## 🌍 Localization

### Adding New Translations

1. Add to `lib/l10n/app_en.arb`:
```json
{
  "myNewKey": "My New Text",
  "@myNewKey": {
    "description": "Description of what this text is for"
  }
}
```

2. Add to `lib/l10n/app_ar.arb`:
```json
{
  "myNewKey": "النص الجديد الخاص بي"
}
```

3. Regenerate:
```bash
flutter gen-l10n
```

4. Use in code:
```dart
Text(AppLocalizations.of(context)!.myNewKey)
```

### Switching Language

```dart
// In your widget
final localeNotifier = ref.read(localeProvider.notifier);

// Switch to Arabic
localeNotifier.setLocale(const Locale('ar'));

// Switch to English
localeNotifier.setLocale(const Locale('en'));
```

## 🎨 Theme System

### Using Theme Colors

```dart
// Primary color
color: AppTheme.primaryColor

// Background
color: Theme.of(context).scaffoldBackgroundColor

// Text colors
color: AppTheme.textMain
color: AppTheme.textSecondary

// Status colors
color: AppTheme.success
color: AppTheme.warning
color: AppTheme.error
```

### Dark Mode

```dart
// In your widget
final themeNotifier = ref.read(themeProvider.notifier);

// Toggle dark mode
themeNotifier.toggleTheme();

// Set specific mode
themeNotifier.setTheme(ThemeMode.dark);
themeNotifier.setTheme(ThemeMode.light);
```

### Checking Dark Mode

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

## 🔧 Development

### Running Tests

```bash
# Backend tests
npm test

# Flutter tests
flutter test
```

### Code Generation

```bash
# Generate localization
flutter gen-l10n

# Get dependencies
flutter pub get
```

### Debugging

```bash
# Backend logs
tail -f backend.log

# Flutter logs
flutter logs
```

## 📱 Screens Overview

### Login Screen
- Clean, modern design
- Language switcher
- Password visibility toggle
- Fully localized

### Client Dashboard
- Subscription status
- Quick actions (Request Delivery, View History)
- Recent deliveries
- Notifications

### Worker Dashboard
- Active deliveries
- Today's schedule
- GPS tracking
- Delivery completion

### Admin Dashboard
- Metrics cards (Orders, Drivers, Revenue)
- User management
- Delivery management
- Analytics

### Station Dashboard
- Production tracking
- Inventory management
- Quality control
- Equipment maintenance

## 🎯 Features

### ✅ Implemented
- [x] Full localization (EN/AR)
- [x] RTL support
- [x] Dark mode
- [x] Modern UI components
- [x] Authentication
- [x] Role-based routing
- [x] GPS tracking
- [x] Notifications
- [x] Backend API

### 🚧 In Progress
- [ ] Apply UID design to all screens
- [ ] Add animations
- [ ] Offline mode
- [ ] Push notifications

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check if port 3000 is in use
lsof -i :3000

# Kill existing process
kill $(lsof -t -i:3000)

# Check database connection
psql -U postgres -d einhod_water -c "SELECT 1"
```

### Flutter build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter gen-l10n
flutter run
```

### Localization not updating
```bash
# Regenerate localization files
flutter gen-l10n

# Hot restart (not hot reload)
# Press 'R' in the terminal or restart the app
```

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Material Design 3](https://m3.material.io)
- [Google Fonts](https://fonts.google.com)

## 🤝 Contributing

1. Follow the existing code style
2. Add translations for new strings
3. Test in both languages
4. Test in dark mode
5. Update documentation

## 📄 License

Proprietary - Einhod Pure Water

---

**Need Help?** Check the implementation plan in `REDESIGN_IMPLEMENTATION_PLAN.md`
