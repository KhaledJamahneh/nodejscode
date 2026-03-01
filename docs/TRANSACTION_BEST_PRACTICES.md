# Database Transaction Best Practices

## Critical Rule: Keep Transactions Fast

**Target:** < 100ms ideal, < 1s maximum

Transactions hold database connections and row-level locks. Slow transactions cause:
- Connection pool exhaustion (self-DOS)
- Blocked concurrent requests
- Cascading failures
- Production outages

---

## ❌ Anti-Pattern: External APIs Inside Transactions

### The Deadlock Scenario

```javascript
// ❌ WRONG: External API inside transaction
await transaction(async (client) => {
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  await fcmService.sendNotification(...); // ❌ Takes 2-5 seconds
  await stripeService.createCharge(...);  // ❌ Takes 1-3 seconds
});
```

**What happens:**
1. Transaction starts, locks `deliveries` row
2. FCM call takes 3 seconds (network latency)
3. Database connection held for 3+ seconds
4. Other requests waiting for same row are blocked
5. With 20 concurrent deliveries, all 20 pool connections are held
6. New requests get "connection pool exhausted" errors
7. **Application is effectively down**

---

## ✅ Correct Pattern: Deferred Execution

### Pattern 1: Return Data for Post-Commit Actions

```javascript
// ✅ CORRECT: Fast transaction, deferred external calls
const result = await transaction(async (client) => {
  // Fast database operations only
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  
  const user = await client.query('SELECT user_id, fcm_token FROM users WHERE id = $1', [userId]);
  
  // Return data needed for external calls
  return {
    userId: user.rows[0].user_id,
    fcmToken: user.rows[0].fcm_token
  };
});

// Execute external APIs AFTER transaction commits
try {
  await fcmService.sendNotification(result.fcmToken, { ... });
  await stripeService.createCharge({ ... });
} catch (error) {
  // Log but don't fail - external calls are non-critical
  logger.error('Post-commit action failed:', error);
}
```

### Pattern 2: Task Queue for Multiple Actions

```javascript
// ✅ CORRECT: Queue multiple deferred tasks
const deferredTasks = [];

await transaction(async (client) => {
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  
  const users = await client.query('SELECT fcm_token FROM users WHERE id = ANY($1)', [userIds]);
  
  // Queue tasks for later
  users.rows.forEach(user => {
    deferredTasks.push(() => fcmService.sendNotification(user.fcm_token, { ... }));
  });
});

// Execute all tasks in parallel after commit
await Promise.allSettled(deferredTasks.map(fn => fn()));
```

---

## What Belongs Inside vs Outside Transactions

### ✅ Inside Transaction (Fast Operations)

- `SELECT`, `INSERT`, `UPDATE`, `DELETE` queries
- Row-level locks (`FOR UPDATE`)
- Data validation against database state
- Atomic multi-table updates
- Incrementing counters

### ❌ Outside Transaction (Slow Operations)

- **External HTTP APIs:**
  - Firebase Cloud Messaging (FCM)
  - Stripe/payment gateways
  - Twilio/SMS services
  - Email services (SendGrid, SES)
  - Webhook calls
  
- **File Operations:**
  - Image uploads to S3
  - PDF generation
  - File compression
  
- **Heavy Computation:**
  - Image processing
  - Report generation
  - Data aggregation
  
- **Third-party Services:**
  - Geocoding APIs
  - Analytics tracking
  - Logging services (if synchronous)

---

## Real-World Example: Complete Delivery

### ❌ Before (Vulnerable to Deadlock)

```javascript
const completeDelivery = async (req, res) => {
  await transaction(async (client) => {
    // Update delivery status
    await client.query('UPDATE deliveries SET status = $1', ['completed']);
    
    // Update worker stats
    await client.query('UPDATE worker_profiles SET deliveries_count = deliveries_count + 1');
    
    // ❌ PROBLEM: External API call inside transaction
    await fcmService.sendNotification(clientId, {
      title: 'Delivery Completed',
      body: 'Your water has been delivered'
    });
    
    // ❌ PROBLEM: Another external API
    await stripeService.createCharge(clientId, amount);
  });
  
  res.json({ success: true });
};
```

**Impact with 20 concurrent deliveries:**
- Each transaction holds connection for 3-5 seconds
- All 20 pool connections exhausted
- New requests fail with "connection timeout"
- **Revenue loss during outage**

### ✅ After (Production-Ready)

```javascript
const completeDelivery = async (req, res) => {
  // Fast transaction (< 50ms)
  const result = await transaction(async (client) => {
    await client.query('UPDATE deliveries SET status = $1', ['completed']);
    await client.query('UPDATE worker_profiles SET deliveries_count = deliveries_count + 1');
    
    const client = await client.query('SELECT user_id, fcm_token FROM users WHERE id = $1', [clientId]);
    
    return {
      clientId: client.rows[0].user_id,
      fcmToken: client.rows[0].fcm_token
    };
  });
  
  // Deferred external calls (non-blocking)
  Promise.allSettled([
    fcmService.sendNotification(result.fcmToken, { ... }),
    stripeService.createCharge(result.clientId, amount)
  ]).catch(error => {
    logger.error('Post-commit action failed:', error);
  });
  
  res.json({ success: true });
};
```

**Benefits:**
- Transaction completes in < 50ms
- Connection released immediately
- External API failures don't block database
- Can handle 100+ concurrent requests

---

## Monitoring & Detection

### Log Analysis

The transaction helper logs warnings for slow transactions:

```json
{
  "level": "warn",
  "message": "Long transaction detected - possible external API call inside transaction",
  "duration": "3245ms",
  "hint": "Move FCM/Stripe/Twilio/email calls outside transaction"
}
```

**Action:** Search logs for these warnings and refactor the code.

### Metrics to Track

1. **Transaction Duration** (p50, p95, p99)
   - Target: p95 < 100ms, p99 < 500ms
   
2. **Connection Pool Utilization**
   - Alert if > 80% for > 1 minute
   
3. **Connection Wait Time**
   - Alert if requests wait > 100ms for connection

---

## Exception: Idempotent External APIs

If an external API is **idempotent** and **critical** to transaction success, you may include it:

```javascript
// Acceptable if payment MUST succeed for delivery to complete
await transaction(async (client) => {
  const charge = await stripeService.createCharge(...); // Idempotent with idempotency key
  
  if (!charge.success) {
    throw new Error('Payment failed'); // Triggers rollback
  }
  
  await client.query('UPDATE deliveries SET status = $1, payment_id = $2', 
    ['completed', charge.id]);
});
```

**Requirements:**
- API must be idempotent (safe to retry)
- API must have timeout < 5 seconds
- Failure must trigger transaction rollback
- Document why it's inside transaction

---

## Testing

### Load Test for Transaction Deadlock

```bash
# Simulate 50 concurrent delivery completions
ab -n 50 -c 50 -p delivery.json \
  -T application/json \
  https://api.example.com/api/v1/workers/deliveries/123/complete
```

**Expected:**
- ✅ All requests succeed
- ✅ No connection pool exhaustion
- ✅ p95 response time < 200ms

**Red Flags:**
- ❌ "Connection pool exhausted" errors
- ❌ Requests timing out
- ❌ p95 response time > 1 second

---

## Summary

| Scenario | Inside Transaction | Outside Transaction |
|----------|-------------------|---------------------|
| Database queries | ✅ | ❌ |
| FCM push notifications | ❌ | ✅ |
| Stripe payments | ❌ (usually) | ✅ |
| Email sending | ❌ | ✅ |
| S3 uploads | ❌ | ✅ |
| Webhook calls | ❌ | ✅ |

**Golden Rule:** If it touches the network (except database), it goes outside the transaction.
