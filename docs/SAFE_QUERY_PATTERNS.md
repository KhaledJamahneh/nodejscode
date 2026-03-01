# Safe Database Query Result Access

## The Problem

Accessing `rows[0]` without checking if the query returned results causes runtime crashes:

```javascript
// ❌ UNSAFE: Crashes if no rows returned
const user = await query('SELECT * FROM users WHERE id = $1', [userId]);
const name = user.rows[0].name; // TypeError: Cannot read property 'name' of undefined
```

---

## The Pattern

### ✅ Always Check Row Count

```javascript
// ✅ SAFE: Check before accessing
const userResult = await query('SELECT * FROM users WHERE id = $1', [userId]);

if (userResult.rows.length === 0) {
  throw new Error('User not found');
}

const user = userResult.rows[0];
const name = user.name; // Safe
```

---

## Common Scenarios

### Scenario 1: User Deleted During Request

```javascript
// Timeline:
// T1: Worker starts delivery completion
// T2: Admin deletes client account
// T3: Worker submits completion
// T4: Query for client returns 0 rows
// T5: Code tries to access rows[0].user_id → CRASH ❌

// Fix:
const clientUser = await client.query(
  'SELECT user_id FROM client_profiles WHERE id = $1',
  [delivery.client_id]
);

if (clientUser.rows.length === 0) {
  throw new Error('Client profile not found');
}

const userId = clientUser.rows[0].user_id; // Safe ✅
```

### Scenario 2: Data Inconsistency

```javascript
// Scenario: delivery.client_id references non-existent client_profile
// (Foreign key constraint missing or disabled)

// Before (Crashes):
const client = await query('SELECT * FROM client_profiles WHERE id = $1', [clientId]);
const debt = client.rows[0].current_debt; // CRASH ❌

// After (Graceful):
const clientResult = await query('SELECT * FROM client_profiles WHERE id = $1', [clientId]);

if (clientResult.rows.length === 0) {
  throw new Error('Client profile not found');
}

const debt = clientResult.rows[0].current_debt; // Safe ✅
```

### Scenario 3: Race Condition

```javascript
// Timeline:
// T1: Request A checks if delivery exists → Found
// T2: Request B deletes delivery
// T3: Request A tries to update delivery → 0 rows updated
// T4: Request A queries for delivery details → 0 rows returned
// T5: Request A accesses rows[0] → CRASH ❌

// Fix: Use idempotent updates with rowCount check
const updateResult = await query(
  'UPDATE deliveries SET status = $1 WHERE id = $2 AND status != $1',
  ['completed', deliveryId]
);

if (updateResult.rowCount === 0) {
  throw new Error('Delivery not found or already completed');
}
```

---

## Helper Function (Optional)

### Create Utility

```javascript
// src/utils/query-helpers.js

/**
 * Get first row from query result or throw error
 * @param {object} result - Query result from pg
 * @param {string} errorMessage - Error message if no rows found
 * @returns {object} - First row
 * @throws {Error} - If no rows found
 */
const getFirstRow = (result, errorMessage = 'Record not found') => {
  if (!result.rows || result.rows.length === 0) {
    throw new Error(errorMessage);
  }
  return result.rows[0];
};

/**
 * Get first row or null if not found
 * @param {object} result - Query result from pg
 * @returns {object|null} - First row or null
 */
const getFirstRowOrNull = (result) => {
  return result.rows && result.rows.length > 0 ? result.rows[0] : null;
};

module.exports = { getFirstRow, getFirstRowOrNull };
```

### Usage

```javascript
const { getFirstRow, getFirstRowOrNull } = require('../utils/query-helpers');

// Throw error if not found
const userResult = await query('SELECT * FROM users WHERE id = $1', [userId]);
const user = getFirstRow(userResult, 'User not found');
console.log(user.name); // Safe

// Return null if not found
const profileResult = await query('SELECT * FROM profiles WHERE user_id = $1', [userId]);
const profile = getFirstRowOrNull(profileResult);
if (profile) {
  console.log(profile.bio);
}
```

---

## Audit Checklist

Search codebase for unsafe patterns:

```bash
# Find all .rows[0] accesses
grep -rn "\.rows\[0\]" src/controllers/

# Check if they have safety checks
grep -B5 "\.rows\[0\]" src/controllers/ | grep "rows.length"
```

### High-Risk Patterns

1. **Direct access without check**
   ```javascript
   const user = result.rows[0]; // ❌ UNSAFE
   ```

2. **Chained access**
   ```javascript
   const name = result.rows[0].name; // ❌ UNSAFE
   ```

3. **Inside transaction**
   ```javascript
   await transaction(async (client) => {
     const user = await client.query('SELECT * FROM users WHERE id = $1', [id]);
     const name = user.rows[0].name; // ❌ UNSAFE - crashes transaction
   });
   ```

### Safe Patterns

1. **Check before access**
   ```javascript
   if (result.rows.length === 0) throw new Error('Not found');
   const user = result.rows[0]; // ✅ SAFE
   ```

2. **Use helper function**
   ```javascript
   const user = getFirstRow(result, 'User not found'); // ✅ SAFE
   ```

3. **Optional chaining (Node.js 14+)**
   ```javascript
   const name = result.rows[0]?.name; // ✅ SAFE (returns undefined if no rows)
   ```

---

## Testing

### Unit Test

```javascript
const { getFirstRow, getFirstRowOrNull } = require('../utils/query-helpers');

describe('Query Helpers', () => {
  it('should return first row if exists', () => {
    const result = { rows: [{ id: 1, name: 'John' }] };
    const row = getFirstRow(result);
    expect(row.name).toBe('John');
  });

  it('should throw error if no rows', () => {
    const result = { rows: [] };
    expect(() => getFirstRow(result)).toThrow('Record not found');
  });

  it('should throw custom error message', () => {
    const result = { rows: [] };
    expect(() => getFirstRow(result, 'User not found')).toThrow('User not found');
  });

  it('should return null if no rows', () => {
    const result = { rows: [] };
    const row = getFirstRowOrNull(result);
    expect(row).toBeNull();
  });
});
```

### Integration Test

```javascript
describe('Complete Delivery', () => {
  it('should fail gracefully if client deleted', async () => {
    // Create delivery
    const delivery = await createDelivery(clientId, workerId);
    
    // Delete client
    await query('DELETE FROM client_profiles WHERE id = $1', [clientId]);
    
    // Attempt to complete delivery
    const response = await request(app)
      .post(`/api/v1/workers/deliveries/${delivery.id}/complete`)
      .set('Authorization', `Bearer ${workerToken}`)
      .send({ gallons_delivered: 20 });
    
    // Should return error, not crash
    expect(response.status).toBe(500);
    expect(response.body.message).toContain('Client profile not found');
  });
});
```

---

## Migration Guide

### Step 1: Find All Unsafe Accesses

```bash
# Find all .rows[0] without safety check
grep -rn "\.rows\[0\]" src/controllers/ > unsafe_accesses.txt
```

### Step 2: Add Safety Checks

For each occurrence, add a check:

```javascript
// Before
const user = userResult.rows[0];

// After
if (userResult.rows.length === 0) {
  throw new Error('User not found');
}
const user = userResult.rows[0];
```

### Step 3: Test Each Change

```bash
# Run tests after each fix
npm test
```

---

## Best Practices

### ✅ DO: Check Row Count

```javascript
if (result.rows.length === 0) {
  throw new Error('Not found');
}
const row = result.rows[0];
```

### ✅ DO: Use Descriptive Error Messages

```javascript
if (clientResult.rows.length === 0) {
  throw new Error('Client profile not found'); // ✅ Clear
}

// Not:
if (clientResult.rows.length === 0) {
  throw new Error('Not found'); // ❌ Vague
}
```

### ✅ DO: Check Inside Transactions

```javascript
await transaction(async (client) => {
  const result = await client.query('SELECT * FROM users WHERE id = $1', [id]);
  
  if (result.rows.length === 0) {
    throw new Error('User not found'); // Triggers rollback
  }
  
  const user = result.rows[0];
  // ... rest of transaction
});
```

### ❌ DON'T: Assume Data Exists

```javascript
// ❌ WRONG: Assumes foreign key guarantees data exists
const delivery = await query('SELECT client_id FROM deliveries WHERE id = $1', [id]);
const client = await query('SELECT * FROM client_profiles WHERE id = $1', [delivery.rows[0].client_id]);
const name = client.rows[0].name; // Can crash if client deleted

// ✅ CORRECT: Always check
const deliveryResult = await query('SELECT client_id FROM deliveries WHERE id = $1', [id]);
if (deliveryResult.rows.length === 0) throw new Error('Delivery not found');

const clientResult = await query('SELECT * FROM client_profiles WHERE id = $1', [deliveryResult.rows[0].client_id]);
if (clientResult.rows.length === 0) throw new Error('Client not found');

const name = clientResult.rows[0].name;
```

### ❌ DON'T: Use Optional Chaining for Critical Data

```javascript
// ❌ WRONG: Silently fails
const name = result.rows[0]?.name || 'Unknown';
// If no rows, name = 'Unknown' (hides the problem)

// ✅ CORRECT: Explicit error
if (result.rows.length === 0) {
  throw new Error('User not found');
}
const name = result.rows[0].name;
```

---

## Summary

| Pattern | Safe? | Use Case |
|---------|-------|----------|
| `result.rows[0]` | ❌ | Never use directly |
| `if (rows.length === 0) throw` | ✅ | Critical data |
| `getFirstRow(result)` | ✅ | Critical data |
| `getFirstRowOrNull(result)` | ✅ | Optional data |
| `result.rows[0]?.property` | ⚠️ | Non-critical data only |

**Key Principle:** Always validate query results before accessing data.
