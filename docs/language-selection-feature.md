# Language Selection Feature

## Overview
Users can now explicitly select their preferred language (English or Arabic) which is stored in the database and synced across all sessions.

## Implementation

### Backend

**New Endpoint:**
```
PUT /api/v1/users/language
```

**Request Body:**
```json
{
  "language": "en" | "ar"
}
```

**Files Added:**
- `src/controllers/user.controller.js` - Language update controller
- `src/routes/user.routes.js` - User routes including language endpoint

**Files Modified:**
- `src/server.js` - Added user routes

### Frontend

**Files Added:**
- `lib/features/settings/presentation/screens/language_selection_screen.dart` - Dedicated language selection screen

**Files Modified:**
- `lib/features/auth/presentation/screens/login_screen.dart` - Added language selector button (top-right corner)

### Database

**Table:** `users`
**Column:** `preferred_language VARCHAR(10) DEFAULT 'en'`

This is the single source of truth for user language preference.

## Usage

### For Unauthenticated Users (Login Screen)
1. Click the language icon (🌐) in the top-right corner
2. Select English or العربية
3. UI updates immediately (stored locally)

### For Authenticated Users
1. Navigate to language selection screen
2. Select preferred language
3. Language is saved to database and synced across devices

### On Login
- The system automatically loads the user's preferred language from the database
- This ensures consistency across all devices

## Testing

```bash
# Test the endpoint
curl -X PUT https://nodejscode-33ip.onrender.com/api/v1/users/language \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"language": "ar"}'
```

## Notes
- Language preference is stored per user in the `users` table
- The `client_profiles.preferred_language` column is deprecated
- Language changes take effect immediately in the UI
- Backend notifications use the user's preferred language
