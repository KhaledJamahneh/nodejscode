# Expense Payment Logic Fix

## Issue
When a worker pays for an expense from their own pocket (`worker_pocket`), the company owes that money back to the worker. However, the system was incorrectly treating it as a "paid" expense.

## Previous (Incorrect) Logic
```javascript
paid_expenses = WHERE payment_status = 'paid'
unpaid_expenses = WHERE payment_status IN ('unpaid', 'pending')
```

**Problem**: `worker_pocket` expenses were counted as "paid" because they had `payment_status = 'paid'`, but the company still owes the worker!

## New (Correct) Logic
```javascript
paid_expenses = WHERE payment_method IN ('cash', 'card', 'company_pocket')
unpaid_expenses = WHERE payment_method IN ('unpaid', 'worker_pocket')
```

## Payment Method Meanings

| Payment Method | Who Paid? | Company Owes? | Category |
|----------------|-----------|---------------|----------|
| `cash` | Company | No | Paid ✅ |
| `card` | Company | No | Paid ✅ |
| `company_pocket` | Company | No | Paid ✅ |
| `worker_pocket` | Worker | **Yes** | **Debt** ⚠️ |
| `unpaid` | Nobody | **Yes** | **Debt** ⚠️ |

## Company Debt Calculation

```javascript
company_debt_to_workers = unpaid_expenses
                        = worker_pocket + unpaid
```

This represents the total amount the company owes to workers.

## Pay Debt Feature

When admin clicks "Pay Debt":
```sql
UPDATE worker_expenses 
SET payment_method = 'cash'
WHERE payment_method IN ('unpaid', 'worker_pocket')
```

This:
1. Reimburses workers for out-of-pocket expenses
2. Pays all pending unpaid expenses
3. Clears company debt to workers

## Example Scenario

### Before Fix
```
Worker submits fuel expense: ₪50
Payment method: worker_pocket
Status: paid

Analytics shows:
- Paid expenses: ₪50 ✅
- Company debt: ₪0 ❌ WRONG!
```

### After Fix
```
Worker submits fuel expense: ₪50
Payment method: worker_pocket

Analytics shows:
- Paid expenses: ₪0
- Unpaid expenses: ₪50
- Company debt to workers: ₪50 ✅ CORRECT!

Admin clicks "Pay Debt":
- Payment method changes to 'cash'
- Worker gets reimbursed
- Company debt: ₪0
```

## Files Modified

1. **src/controllers/admin.controller.js**
   - Fixed `paid_expenses` calculation (line 1627)
   - Fixed `unpaid_expenses` calculation (line 1628)
   - Added `company_debt_to_workers` to analytics response
   - Added `payCompanyDebt` function

2. **src/routes/admin.routes.js**
   - Added `POST /api/v1/admin/analytics/pay-debt` route

3. **Frontend** (already implemented)
   - Analytics screen shows company debt
   - Pay button with confirmation dialog
   - Refreshes data after payment

## Testing

1. **Create expense with worker_pocket**:
   ```bash
   POST /api/v1/worker/expenses
   {
     "amount": 50,
     "payment_method": "worker_pocket",
     "destination": "Fuel"
   }
   ```

2. **Check analytics**:
   ```bash
   GET /api/v1/admin/analytics/overview
   ```
   Should show:
   - `unpaid_expenses`: 50
   - `company_debt_to_workers`: 50

3. **Pay debt**:
   ```bash
   POST /api/v1/admin/analytics/pay-debt
   ```

4. **Verify**:
   - Expense `payment_method` changed to `cash`
   - `company_debt_to_workers`: 0

## Deployed
- Commit: `977ab2f`
- Status: Live on production
