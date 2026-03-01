# Inventory Integrity Constraints

## Problem: The "Negative Water" Vulnerability

**Before:** Database allowed impossible inventory states:
- ❌ Negative inventory (`vehicle_current_gallons = -500`)
- ❌ Over-capacity inventory (`vehicle_current_gallons = 99999` when capacity is `1000`)
- ❌ Zero or negative capacity

**Risk:** 
- Workers could deliver more water than physically possible
- Inventory metrics become mathematically impossible
- Audit failures and financial discrepancies
- Potential fraud (reporting 500 gallons delivered with only 100 in truck)

## Solution: Database-Level Constraints

Added three CHECK constraints to `worker_profiles`:

### 1. Non-Negative Inventory
```sql
CHECK (vehicle_current_gallons >= 0)
```
Prevents negative inventory values.

### 2. Capacity Limit
```sql
CHECK (vehicle_current_gallons <= vehicle_capacity)
```
Ensures current inventory never exceeds vehicle capacity.

### 3. Positive Capacity
```sql
CHECK (vehicle_capacity > 0)
```
Ensures vehicles have valid capacity.

## Defense in Depth

**Application Layer (Already Exists):**
```javascript
if (currentGallons < gallons_delivered) {
  throw new ValidationError('Insufficient inventory');
}
```

**Database Layer (Now Added):**
```sql
CHECK (vehicle_current_gallons >= 0)
CHECK (vehicle_current_gallons <= vehicle_capacity)
```

## Benefits

1. **Data Integrity:** Impossible states rejected at database level
2. **Audit Compliance:** Inventory always mathematically valid
3. **Fraud Prevention:** Cannot report delivering more than physically possible
4. **Fail-Safe:** Even if application logic fails, database enforces rules

## Testing

Run verification script:
```bash
node scripts/check-inventory-constraints.js
```

Expected output:
- ✅ Negative inventory blocked
- ✅ Over-capacity blocked
- ✅ All constraints active
