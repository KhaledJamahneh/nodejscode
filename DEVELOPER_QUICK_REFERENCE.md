# DEVELOPER QUICK REFERENCE - UPDATED LOGIC

## 🔑 Multiple Roles

### Database
```sql
-- Old
role user_role NOT NULL

-- New
roles user_role[] NOT NULL DEFAULT ARRAY['client']::user_role[]

-- Query
SELECT * FROM users WHERE 'client' = ANY(roles);
```

### Code
```javascript
// Old
if (req.user.role === 'client') { ... }

// New
const { hasRole, isClient } = require('./utils/roles');
if (hasRole(req.user.roles, 'client')) { ... }
// or
if (isClient(req.user.roles)) { ... }
```

### JWT Token
```javascript
// Old
{ id: 1, username: "user", role: "client" }

// New
{ id: 1, username: "user", roles: ["client", "delivery_worker"] }
```

---

## 💰 Atomic Coupon Deduction

### Old Way (Race Condition)
```javascript
// Check
if (client.remaining_coupons < needed) {
  throw new Error('Insufficient coupons');
}
// Deduct (another request could happen here!)
await query('UPDATE client_profiles SET remaining_coupons = remaining_coupons - $1', [needed]);
```

### New Way (Atomic)
```javascript
const result = await client.query(
  'SELECT use_coupons($1, $2) as success',
  [clientId, couponsNeeded]
);

if (!result.rows[0].success) {
  throw new Error('Insufficient coupons');
}
```

---

## 🚗 Atomic Vehicle Inventory

### Old Way (Race Condition)
```javascript
// Check and update separately
const current = await query('SELECT vehicle_current_gallons FROM worker_profiles WHERE id = $1', [workerId]);
if (current.rows[0].vehicle_current_gallons < needed) {
  throw new Error('Insufficient inventory');
}
await query('UPDATE worker_profiles SET vehicle_current_gallons = vehicle_current_gallons - $1', [needed]);
```

### New Way (Atomic)
```javascript
try {
  await client.query(
    'SELECT update_vehicle_inventory($1, $2)',
    [workerId, -gallonsDelivered] // negative to deduct
  );
} catch (error) {
  // Handles insufficient inventory and capacity violations
  throw error;
}
```

---

## 🕐 Timezone Handling

### Database
```sql
-- Old
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

-- New
created_at TIMESTAMPTZ DEFAULT NOW()
```

### Code
```javascript
// Always use Date objects, they handle timezones
const now = new Date(); // Automatically timezone-aware

// When querying
const result = await query(
  'SELECT * FROM deliveries WHERE delivery_date >= $1',
  [new Date('2026-02-28T00:00:00+02:00')]
);
```

---

## 📍 Location Fields

### Old
```javascript
// client_profiles had: latitude, longitude, home_latitude, home_longitude, location
const { latitude, longitude } = profile; // REMOVED
```

### New
```javascript
// Only use home_latitude/home_longitude for home address
const { home_latitude, home_longitude } = profile;

// For current location, use PostGIS location field
const result = await query(
  `SELECT ST_X(location::geometry) as longitude, 
          ST_Y(location::geometry) as latitude 
   FROM client_profiles WHERE id = $1`,
  [clientId]
);
```

---

## ⚙️ System Configuration

### Old (Hardcoded)
```javascript
const MAX_PENDING_REQUESTS = 3;
const DEBT_LIMIT = 10000;
```

### New (Configurable)
```javascript
const configResult = await query(
  `SELECT key, value FROM system_config 
   WHERE key IN ('max_pending_requests', 'debt_limit_ils')`
);
const config = Object.fromEntries(configResult.rows.map(r => [r.key, r.value]));
const maxPendingRequests = parseInt(config.max_pending_requests || '3');
const debtLimit = parseFloat(config.debt_limit_ils || '10000');
```

### Update Config
```sql
UPDATE system_config SET value = '5' WHERE key = 'max_pending_requests';
```

---

## 🔄 State Machine

### Valid Transitions
```
pending → in_progress → completed
pending → cancelled
in_progress → cancelled
```

### Code
```javascript
// Transitions are enforced at database level
// Just update status, trigger will validate
await query(
  'UPDATE deliveries SET status = $1 WHERE id = $2',
  ['in_progress', deliveryId]
);
// If invalid transition, database will throw error
```

---

## 💳 Payment Method Validation

### Old
```javascript
const { payment_method } = req.body;
// Defaulted to 'cash' if not provided
```

### New
```javascript
const { payment_method } = req.body;

// Required field
if (!payment_method) {
  return res.status(400).json({
    success: false,
    message: 'payment_method is required'
  });
}

// Must match subscription type
if (payment_method === 'coupon_book' && subscription_type !== 'coupon_book') {
  throw new Error('Cash subscription clients cannot use coupon payment');
}
```

---

## 📅 Subscription Expiry

### Old (Grace period for all)
```javascript
const gracePeriodDate = new Date(expiryDate);
gracePeriodDate.setDate(gracePeriodDate.getDate() + 10);
if (today > gracePeriodDate) {
  throw new Error('Subscription expired');
}
```

### New (Grace period only for cash)
```javascript
if (subscription_type === 'cash') {
  // Apply grace period for cash subscriptions
  const graceDays = grace_period_days || 10;
  const gracePeriodDate = new Date(expiryDate);
  gracePeriodDate.setDate(gracePeriodDate.getDate() + graceDays);
  
  if (today > gracePeriodDate) {
    throw new Error('Subscription expired');
  }
} else {
  // No grace period for coupon subscriptions (prepaid)
  if (today > expiryDate) {
    throw new Error('Subscription expired');
  }
}
```

---

## 🔔 Notification Handling

### Old (Fails transaction)
```javascript
await client.query(
  'INSERT INTO notifications ...',
  [userId, title, message]
);
```

### New (Fire-and-forget)
```javascript
try {
  await client.query(
    'INSERT INTO notifications ...',
    [userId, title, message]
  );
} catch (notifError) {
  logger.warn('Failed to create notification:', notifError);
  // Don't throw - continue with main operation
}
```

---

## 🔍 Role Checking Utilities

```javascript
const { 
  hasRole, 
  hasAnyRole, 
  hasAllRoles,
  isAdminOrOwner,
  isClient,
  isWorker 
} = require('./utils/roles');

// Check single role
if (hasRole(user.roles, 'client')) { ... }

// Check any of multiple roles
if (hasAnyRole(user.roles, ['administrator', 'owner'])) { ... }

// Check all roles
if (hasAllRoles(user.roles, ['client', 'delivery_worker'])) { ... }

// Convenience functions
if (isAdminOrOwner(user.roles)) { ... }
if (isClient(user.roles)) { ... }
if (isWorker(user.roles)) { ... }
```

---

## 📊 Composite Indexes

### Queries That Benefit
```javascript
// Fast: Uses idx_delivery_requests_client_status
await query(
  'SELECT * FROM delivery_requests WHERE client_id = $1 AND status = $2',
  [clientId, 'pending']
);

// Fast: Uses idx_deliveries_client_date
await query(
  'SELECT * FROM deliveries WHERE client_id = $1 AND delivery_date >= $2',
  [clientId, startDate]
);

// Fast: Uses idx_deliveries_worker_date
await query(
  'SELECT * FROM deliveries WHERE worker_id = $1 AND delivery_date = $2',
  [workerId, today]
);
```

---

## 🔧 Common Patterns

### Transaction with Error Handling
```javascript
const result = await transaction(async (client) => {
  // Lock row
  const data = await client.query(
    'SELECT * FROM table WHERE id = $1 FOR UPDATE',
    [id]
  );
  
  // Validate
  if (!data.rows[0]) {
    throw new Error('Not found');
  }
  
  // Update
  const updated = await client.query(
    'UPDATE table SET field = $1 WHERE id = $2 RETURNING *',
    [value, id]
  );
  
  return updated.rows[0];
});
```

### Role-based Authorization
```javascript
const { authorizeRoles } = require('./middleware/auth.middleware');

// Single role
router.get('/admin/dashboard', 
  authenticateToken, 
  authorizeRoles('administrator'),
  getDashboard
);

// Multiple roles
router.get('/deliveries', 
  authenticateToken, 
  authorizeRoles('client', 'delivery_worker', 'administrator'),
  getDeliveries
);
```

---

## 🐛 Debugging Tips

### Check User Roles
```sql
SELECT id, username, roles FROM users WHERE id = 1;
```

### Check System Config
```sql
SELECT * FROM system_config;
```

### Check Triggers
```sql
SELECT trigger_name, event_object_table, action_statement 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

### Check Indexes
```sql
SELECT tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;
```

### Monitor Query Performance
```sql
EXPLAIN ANALYZE 
SELECT * FROM delivery_requests 
WHERE client_id = 1 AND status = 'pending';
```

---

## ⚠️ Common Mistakes to Avoid

1. **Don't use `role` - use `roles`**
   ```javascript
   // ❌ Wrong
   if (user.role === 'client')
   
   // ✅ Correct
   if (hasRole(user.roles, 'client'))
   ```

2. **Don't use latitude/longitude - use home_latitude/home_longitude**
   ```javascript
   // ❌ Wrong
   const { latitude, longitude } = profile;
   
   // ✅ Correct
   const { home_latitude, home_longitude } = profile;
   ```

3. **Don't default payment_method**
   ```javascript
   // ❌ Wrong
   const payment_method = req.body.payment_method || 'cash';
   
   // ✅ Correct
   const { payment_method } = req.body;
   if (!payment_method) throw new Error('Required');
   ```

4. **Don't manually update updated_at**
   ```javascript
   // ❌ Wrong
   UPDATE table SET field = $1, updated_at = NOW()
   
   // ✅ Correct (trigger handles it)
   UPDATE table SET field = $1
   ```

5. **Don't check-then-update - use atomic functions**
   ```javascript
   // ❌ Wrong (race condition)
   if (coupons >= needed) {
     UPDATE ... SET coupons = coupons - needed
   }
   
   // ✅ Correct (atomic)
   SELECT use_coupons(client_id, needed)
   ```

---

**Last Updated:** 2026-02-28  
**Version:** 2.0.0
