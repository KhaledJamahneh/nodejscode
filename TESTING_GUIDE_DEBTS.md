# Testing Guide - Debts Paid History Feature

## Prerequisites

1. Database migration has been run (✅ Already completed)
2. Backend server is running
3. Flutter app is running

## Step 1: Start the Backend Server

```bash
cd /home/eito_new/Downloads/einhod-longterm
npm run dev
```

The server should start on `http://localhost:3000`

## Step 2: Test Backend API

### Option A: Using the Test Script

```bash
chmod +x test_debts_api.sh
./test_debts_api.sh
```

### Option B: Manual Testing with curl

1. **Login to get token:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"owner","password":"Admin123!"}'
```

Copy the `accessToken` from the response.

2. **Get unpaid debts:**
```bash
curl http://localhost:3000/api/v1/admin/debts?status=unpaid \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

3. **Get paid debts:**
```bash
curl http://localhost:3000/api/v1/admin/debts?status=paid \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

4. **Mark a debt as paid (replace 123 with actual delivery ID):**
```bash
curl -X PATCH http://localhost:3000/api/v1/admin/debts/123/mark-paid \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"paymentMethod": "cash"}'
```

## Step 3: Test Flutter App

1. **Start the Flutter app:**
```bash
cd /home/eito_new/Downloads/einhod-longterm
flutter run
```

2. **Navigate to Debts Page:**
   - Login as admin/owner
   - Go to Admin section
   - Click on "Debts" menu item

3. **Test Unpaid Tab:**
   - Should see all unpaid debts by default
   - Try searching for a client
   - Click on a debt to expand details

4. **Test Mark as Paid:**
   - Click the green checkmark button on a debt
   - Select payment method (cash or coupon)
   - Click "Confirm Payment"
   - Debt should disappear from unpaid tab

5. **Test Paid History Tab:**
   - Click on "Paid History" tab
   - Should see the debt you just marked as paid
   - Verify payment date and method are shown
   - Verify action buttons are hidden (read-only)

6. **Test Search in Paid Tab:**
   - Search for a client in paid history
   - Results should filter correctly

7. **Test Pull to Refresh:**
   - Pull down on either tab to refresh
   - Data should reload

## Expected Results

### Unpaid Tab
- Shows only debts where `debt_paid = false`
- Shows action buttons (mark as paid, edit)
- Empty state: "No Debts - All debts are cleared!"

### Paid History Tab
- Shows only debts where `debt_paid = true`
- Shows payment date and method
- No action buttons (read-only)
- Empty state: "No Paid Debts - Paid debts will appear here"

## Troubleshooting

### Backend Issues

**Error: "Cannot connect to database"**
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify database credentials in `.env`

**Error: "Column debt_paid does not exist"**
- Run migration: `node scripts/run-debt-tracking-migration.js`

**Error: "markDebtAsPaid is not a function"**
- Restart the server to reload the code

### Frontend Issues

**Error: "No such method: getClientDebts"**
- Run `flutter clean && flutter pub get`
- Restart the app

**Error: "Undefined name 'paidHistory'"**
- Run `flutter gen-l10n` to regenerate localizations
- Restart the app

**Tabs not showing**
- Check console for errors
- Verify imports are correct
- Hot restart the app (not just hot reload)

## Database Verification

Check the database directly:

```sql
-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'deliveries' 
  AND column_name IN ('debt_paid', 'debt_paid_at', 'debt_payment_method');

-- Check unpaid debts
SELECT id, client_id, total_price, paid_amount, debt_paid 
FROM deliveries 
WHERE status = 'completed' 
  AND (total_price - COALESCE(paid_amount, 0)) > 0
  AND COALESCE(debt_paid, false) = false;

-- Check paid debts
SELECT id, client_id, total_price, paid_amount, debt_paid, debt_paid_at, debt_payment_method
FROM deliveries 
WHERE COALESCE(debt_paid, false) = true;

-- Mark a debt as paid manually (for testing)
UPDATE deliveries 
SET debt_paid = true, 
    debt_paid_at = NOW(), 
    debt_payment_method = 'cash'
WHERE id = 123;
```

## Success Criteria

✅ Backend migration runs without errors
✅ Backend API returns unpaid debts with status=unpaid
✅ Backend API returns paid debts with status=paid
✅ Backend API marks debt as paid successfully
✅ Flutter app shows two tabs
✅ Unpaid tab shows only unpaid debts
✅ Paid history tab shows only paid debts
✅ Mark as paid moves debt from unpaid to paid tab
✅ Payment info is displayed in paid history
✅ Action buttons are hidden in paid history
✅ Search works in both tabs
✅ Pull to refresh works in both tabs
✅ Localizations work in both English and Arabic

## Next Steps

After successful testing:
1. Test with real data
2. Verify performance with large datasets
3. Test edge cases (no debts, all paid, etc.)
4. Test on different devices/screen sizes
5. Deploy to production
