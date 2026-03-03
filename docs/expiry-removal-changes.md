# Expiry Date Removal - Changes Summary

## Date: 2026-03-01

All expiry date functionality has been removed from the application.

## Database Changes

### Migration File Created
- `migrations/remove_expiry_dates.sql` - Removes expiry columns from database

### Schema Changes
1. **coupon_sizes table**: Removed `expiry_days` column
2. **client_profiles table**: Removed `subscription_expiry_date` column
3. **system_settings**: Removed `subscription_expiry_warning_days` setting

## Backend Changes (Node.js)

### Controllers Modified

**admin.controller.js:**
- `getCouponSizes()` - Removed `expiry_days` from SELECT query
- `updateCouponSize()` - Removed `expiry_days` parameter and UPDATE logic
- `getAllUsers()` - Removed `subscription_expiry_date` from client profile JSON
- `createUser()` - Removed `subscription_expiry_date` parameter and logic
- `getDashboard()` - Changed expired subscriptions count to always return 0

**client.controller.js:**
- `getClientProfile()` - Removed `subscription_expiry_date` from query and removed expiry status calculation logic
- `getSubscription()` - Removed expiry date checks and days_remaining calculation, status always returns 'active'

**delivery.controller.js:**
- `createDeliveryRequest()` - Removed `subscription_expiry_date` from query and removed all expiry validation checks

### Routes Modified

**admin.routes.js:**
- Removed `expiry_days` validation from PATCH `/coupon-sizes/:id` route

## Frontend Changes (Flutter)

### Screens Modified

**admin_coupon_settings_screen.dart:**
- Removed `expiryDaysController` from create coupon size dialog
- Removed expiry days TextField from UI

**client_home_screen.dart:**
- Removed expiry date display from subscription info card
- Removed "Expires in X days" text from header
- Removed subscription status display

### Services Modified

**admin_service.dart:**
- Removed `expiryDays` parameter from `createCouponSize()` method

## What Still Remains

The following are NOT removed (intentionally kept):
- Localization strings (app_en.arb, app_ar.arb) - kept for backward compatibility
- Model fields in Dart models - kept to avoid breaking existing data parsing
- Old test files and documentation - kept for reference

## Testing Required

1. ✅ Create new coupon size (without expiry)
2. ✅ Update existing coupon size
3. ✅ Create new client
4. ✅ View client profile
5. ✅ Create delivery request (no expiry checks)
6. ✅ View admin dashboard

## Migration Steps

To apply these changes to production:

1. Run the migration SQL:
   ```bash
   psql $DATABASE_URL -f migrations/remove_expiry_dates.sql
   ```

2. Deploy backend changes

3. Rebuild and deploy Flutter APK

## Notes

- All subscriptions are now considered perpetual/active
- No expiry warnings or notifications will be shown
- Coupon books have no time limit
- Cash subscriptions have no expiry date
