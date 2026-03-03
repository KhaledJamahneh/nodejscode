# Financial Integrity Constraints

## Problem: Payment Validation Loophole

**Before:** Database allowed invalid financial transactions:
- ❌ Zero payments (`amount = 0.00`)
- ❌ Negative payments (`amount = -100.00`)
- ❌ Zero expenses
- ❌ Negative delivery prices

**Risk:**
- Financial compliance violations
- Accounting discrepancies
- Audit failures
- Potential fraud (negative payments = money flowing wrong direction)
- Route validators can be bypassed (migrations, scripts, direct DB access)

## Solution: Database-Level Financial Constraints

### Defense in Depth Strategy

**Layer 1 (Application):** Express validators
```javascript
body('amount').isFloat({ min: 0.01 })
```

**Layer 2 (Database):** CHECK constraints (Last line of defense)
```sql
CHECK (amount > 0)
```

### Constraints Added

#### 1. Payments Table
```sql
CHECK (amount > 0)
```
Ensures all payments are positive (minimum $0.01).

#### 2. Expenses Table
```sql
CHECK (amount > 0)
```
Ensures all expenses are positive.

#### 3. Deliveries Table
```sql
CHECK (paid_amount >= 0)
CHECK (total_price >= 0)
```
Allows zero (unpaid) but prevents negative values.

#### 4. Coupon Sizes Table
```sql
CHECK (price > 0)
```
Ensures coupon books have valid prices.

## Why Database Constraints Matter

### Scenario: Migration Script
```javascript
// Migration bypasses route validators
await pool.query(`
  INSERT INTO payments (payer_id, amount, payment_method)
  VALUES (123, -500.00, 'refund')
`);
```

**Without constraints:** ✅ Succeeds - Creates invalid data  
**With constraints:** ❌ Fails - Database rejects invalid transaction

### Scenario: Direct Database Access
Admin runs SQL directly:
```sql
UPDATE payments SET amount = -1000 WHERE id = 456;
```

**Without constraints:** ✅ Succeeds - Corrupts financial data  
**With constraints:** ❌ Fails - Database protects integrity

## Financial Compliance Benefits

1. **SOX Compliance:** Financial data integrity enforced at lowest level
2. **Audit Trail:** Invalid transactions rejected before they enter system
3. **Fraud Prevention:** Cannot record negative payments or zero-value transactions
4. **Data Quality:** Mathematically valid financial records guaranteed

## Testing

Run verification:
```bash
node scripts/check-payment-constraints.js
```

Expected results:
- ✅ Zero payment blocked
- ✅ Negative payment blocked
- ✅ Zero expense blocked
- ✅ Negative expense blocked
- ✅ All financial constraints active

## Tables Protected

- `payments` - Customer payments
- `expenses` - Worker expenses
- `deliveries` - Delivery transactions
- `coupon_sizes` - Coupon book pricing

## Migration Safety

The migration includes data cleanup:
```sql
-- Fix any existing invalid data before adding constraints
UPDATE payments SET amount = 0.01 WHERE amount <= 0;
UPDATE expenses SET amount = 0.01 WHERE amount <= 0;
```

This ensures the migration succeeds even if invalid data exists.
