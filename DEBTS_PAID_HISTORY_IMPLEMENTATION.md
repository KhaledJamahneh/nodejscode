# Debts Page - Paid History Tab Implementation

## Summary

Added a tab system to the debts page that separates unpaid debts from paid history. When a debt is marked as paid, it moves to the history tab and is hidden from the main unpaid tab.

## Changes Made

### Backend Changes

1. **Database Migration** (`database/migrations/add_debt_tracking.sql`)
   - Added `debt_paid` (boolean) column to track payment status
   - Added `debt_paid_at` (timestamp) to record when debt was paid
   - Added `debt_payment_method` (varchar) to store payment method (cash/coupon)
   - Created index on `debt_paid` for faster queries

2. **Admin Controller** (`src/controllers/admin.controller.js`)
   - Updated `getClientDebts` to accept `status` query parameter ('unpaid' or 'paid')
   - Added filtering logic to show only unpaid or paid debts based on status
   - Added `markDebtAsPaid` endpoint to mark a delivery debt as paid
   - Returns additional fields: `debtPaid`, `debtPaidAt`, `debtPaymentMethod`

3. **Admin Routes** (`src/routes/admin.routes.js`)
   - Added `PATCH /api/v1/admin/debts/:deliveryId/mark-paid` endpoint
   - Validates `paymentMethod` must be 'cash' or 'coupon'

### Frontend Changes

1. **Debt Model** (`lib/features/admin/data/models/debt_model.dart`)
   - Added `debtPaid` field (boolean)
   - Added `debtPaidAt` field (nullable string)
   - Added `debtPaymentMethod` field (nullable string)

2. **Admin Service** (`lib/features/admin/data/admin_service.dart`)
   - Updated `getClientDebts` to accept `status` parameter
   - Added `markDebtAsPaid` method to call backend API

3. **Debts Provider** (`lib/features/admin/presentation/providers/debts_provider.dart`)
   - Changed from `FutureProvider` to `FutureProvider.family` to accept status parameter
   - Allows separate caching for unpaid and paid debts

4. **Debts Screen** (`lib/features/admin/presentation/screens/admin_debts_screen.dart`)
   - Added tab system with "Unpaid" and "Paid History" tabs
   - Added `_TabButton` widget for tab selection
   - Updated empty states for each tab
   - Modified `_DeliveryDebtRow` to:
     - Hide action buttons (mark as paid, edit) in paid history tab
     - Show payment info (paid date and method) in paid history tab
   - Updated `_showPayDebtDialog` to call backend API
   - Added proper error handling and refresh after marking as paid

5. **Localizations** (`lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`)
   - Added English strings:
     - `paidHistory`: "Paid History"
     - `noDebts`: "No Debts"
     - `noPaidDebts`: "No Paid Debts"
     - `allDebtsCleared`: "All debts are cleared!"
     - `paidDebtsWillAppearHere`: "Paid debts will appear here"
     - `paidOn`: "Paid on"
   - Added Arabic translations for all new strings

## API Endpoints

### Get Client Debts
```
GET /api/v1/admin/debts?status=unpaid
GET /api/v1/admin/debts?status=paid
```

**Query Parameters:**
- `status` (optional): 'unpaid' (default) or 'paid'

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "clientId": 1,
      "clientName": "John Doe",
      "deliveryId": 123,
      "cashDebt": 50.00,
      "couponDebt": 2,
      "debtPaid": false,
      "debtPaidAt": null,
      "debtPaymentMethod": null
    }
  ]
}
```

### Mark Debt as Paid
```
PATCH /api/v1/admin/debts/:deliveryId/mark-paid
```

**Body:**
```json
{
  "paymentMethod": "cash"  // or "coupon"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Debt marked as paid",
  "data": { ... }
}
```

## User Flow

1. Admin opens Debts page
2. By default, sees "Unpaid" tab with all outstanding debts
3. Can search and filter debts by client name or phone
4. Clicks "Mark as Paid" button on a debt
5. Selects payment method (cash or coupon)
6. Confirms payment
7. Debt disappears from "Unpaid" tab
8. Switches to "Paid History" tab to see the paid debt
9. Paid debt shows payment date and method
10. No action buttons available in paid history (read-only)

## Testing

1. Run the migration:
   ```bash
   node scripts/run-debt-tracking-migration.js
   ```

2. Restart the backend server:
   ```bash
   npm run dev
   ```

3. Test the API:
   ```bash
   # Get unpaid debts
   curl http://localhost:3000/api/v1/admin/debts?status=unpaid \
     -H "Authorization: Bearer YOUR_TOKEN"

   # Mark debt as paid
   curl -X PATCH http://localhost:3000/api/v1/admin/debts/123/mark-paid \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"paymentMethod": "cash"}'

   # Get paid debts
   curl http://localhost:3000/api/v1/admin/debts?status=paid \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

4. Test the Flutter app:
   - Navigate to Admin > Debts
   - Verify tabs are visible
   - Mark a debt as paid
   - Switch to "Paid History" tab
   - Verify debt appears with payment info

## Notes

- Debts are never deleted, only marked as paid
- Payment history is preserved for auditing
- Search works across both tabs
- Each tab maintains its own data cache
- Refresh indicator works independently for each tab
