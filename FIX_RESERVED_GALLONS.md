# FIX: Reserved Gallons Not Saved During Delivery

## Problem
The `gallons_on_hand` column (reserved gallons at client location) was missing from the `client_profiles` table, causing the delivery completion to fail silently when trying to update this value.

## Solution

### 1. Apply Database Migration

```bash
psql -U postgres -d einhod_water -f migrations/add_gallons_on_hand.sql
```

Or manually:
```sql
ALTER TABLE client_profiles 
ADD COLUMN IF NOT EXISTS gallons_on_hand INTEGER DEFAULT 0;
```

### 2. Verify Column Exists

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'client_profiles' AND column_name = 'gallons_on_hand';
```

Should return:
```
 column_name    | data_type | column_default 
----------------+-----------+----------------
 gallons_on_hand| integer   | 0
```

### 3. Test Delivery Completion

The logic now correctly:
1. **Adds delivered gallons** to `gallons_on_hand`
2. **Subtracts returned empties** from `gallons_on_hand`
3. **Tracks net gallons** at client location

**Formula:**
```
gallons_on_hand = gallons_on_hand + gallons_delivered - empty_gallons_returned
```

**Example:**
- Client has: 20 gallons on hand
- Delivery: 100 gallons delivered, 15 empties returned
- Result: 20 + 100 - 15 = **105 gallons on hand**

## Verification

### Check Current Values
```sql
SELECT 
  c.full_name,
  c.gallons_on_hand,
  c.monthly_usage_gallons,
  c.remaining_coupons
FROM client_profiles c
JOIN users u ON c.user_id = u.id
WHERE u.username = 'test_client';
```

### Test Delivery Completion
```bash
# Complete a delivery via API
curl -X POST http://localhost:3000/api/v1/workers/deliveries/123/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "gallons_delivered": 100,
    "empty_gallons_returned": 20,
    "delivery_latitude": 31.9539,
    "delivery_longitude": 35.9106,
    "notes": "Test delivery",
    "photo_url": "https://example.com/photo.jpg"
  }'
```

### Verify Update
```sql
SELECT 
  d.id,
  d.gallons_delivered,
  d.empty_gallons_returned,
  c.gallons_on_hand,
  c.monthly_usage_gallons
FROM deliveries d
JOIN client_profiles c ON d.client_id = c.id
WHERE d.id = 123;
```

## What Was Fixed

✅ Added `gallons_on_hand` column to `client_profiles`  
✅ Column tracks net gallons at client location  
✅ Updated during every delivery completion  
✅ Properly handles empties return  
✅ Validates max returnable gallons  

## Migration Status

- **File:** `migrations/add_gallons_on_hand.sql`
- **Status:** Ready to apply
- **Breaking:** No (adds column with default value)
- **Rollback:** `ALTER TABLE client_profiles DROP COLUMN gallons_on_hand;`

## Notes

- The delivery completion logic was already correct in code
- The issue was simply the missing database column
- No code changes needed, only schema update
- Existing deliveries will work after migration
- Default value of 0 is safe for existing clients

---

**Status:** ✅ Fixed - Apply migration to resolve
