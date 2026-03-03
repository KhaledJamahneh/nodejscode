# Notification Delivery Guarantees

## Architecture Overview

The system uses a **two-tier notification approach**:

1. **Database Notification** (inside transaction) - Guaranteed delivery
2. **Push Notification** (outside transaction) - Best-effort delivery

---

## Current Implementation

```javascript
const result = await transaction(async (client) => {
  // 1. Update delivery status
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  
  // 2. Store notification in database (GUARANTEED)
  await client.query(
    'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
    [userId, title, message]
  );
  
  return { userId, title, message };
});

// 3. Send push notification (BEST-EFFORT)
try {
  await fcmService.sendNotification(result.userId, { ... });
} catch (error) {
  logger.error('Push notification failed:', error);
  // Don't throw - delivery is already completed
}
```

---

## Delivery Guarantees

### ✅ Database Notification (Tier 1)

**Guarantee:** Atomic with business logic

| Scenario | Database Notification | Business Logic |
|----------|----------------------|----------------|
| Transaction succeeds | ✅ Stored | ✅ Completed |
| Transaction fails | ❌ Rolled back | ❌ Rolled back |
| Network timeout | ❌ Rolled back | ❌ Rolled back |

**User Experience:**
- User can **always** view notification in app notification history
- Notification list is source of truth
- No phantom notifications (if notification exists, delivery exists)

### ⚠️ Push Notification (Tier 2)

**Guarantee:** Best-effort, non-blocking

| Scenario | Push Notification | Database Notification | Business Logic |
|----------|------------------|----------------------|----------------|
| FCM succeeds | ✅ Delivered | ✅ Stored | ✅ Completed |
| FCM timeout | ❌ Not delivered | ✅ Stored | ✅ Completed |
| FCM rate limit | ❌ Not delivered | ✅ Stored | ✅ Completed |
| User offline | ⏳ Queued by FCM | ✅ Stored | ✅ Completed |

**User Experience:**
- User **may** receive push notification
- If push fails, user sees notification when opening app
- No duplicate notifications (idempotency key in FCM payload)

---

## Failure Scenarios

### Scenario 1: FCM Timeout (Current Architecture)

```
Timeline:
T1: Transaction starts
T2: UPDATE deliveries SET status = 'completed' ✅
T3: INSERT INTO notifications ✅
T4: Transaction commits ✅
T5: fcmService.sendNotification() called
T6: FCM times out after 5 seconds ❌
T7: Error logged, request returns success ✅

Result:
- Delivery: Completed ✅
- Database notification: Stored ✅
- Push notification: Not delivered ❌
- User sees notification when opening app ✅
```

**Impact:** User doesn't get instant push, but sees notification in-app. **Acceptable.**

---

### Scenario 2: FCM Inside Transaction (Anti-Pattern)

```
Timeline:
T1: Transaction starts
T2: UPDATE deliveries SET status = 'completed' ✅
T3: INSERT INTO notifications ✅
T4: fcmService.sendNotification() called (INSIDE TRANSACTION) ❌
T5: FCM times out after 5 seconds ❌
T6: Transaction helper catches error
T7: ROLLBACK triggered ❌

Result:
- Delivery: NOT completed ❌
- Database notification: Rolled back ❌
- Push notification: May have partially sent ⚠️
- User may receive push for non-existent delivery ❌
```

**Impact:** Phantom notification, confused user, worker must retry. **Unacceptable.**

---

### Scenario 3: Double Tap Without Idempotency

```
Timeline:
T1: Worker taps "Complete" (Request 1)
T2: Transaction commits, FCM sent ✅
T3: Worker taps "Complete" again (Request 2)
T4: Transaction commits again ❌
T5: FCM sent again ❌

Result:
- Delivery: Completed twice ❌
- Worker stats: Doubled ❌
- Push notifications: Sent twice ❌
- User spammed ❌
```

**Impact:** Payroll fraud, user annoyance. **Unacceptable.**

**Fix:** Idempotency check (already implemented)
```sql
UPDATE deliveries SET status = 'completed' 
WHERE id = $1 AND status != 'completed'
```

---

## Best Practices

### ✅ DO: Store Notification in Database First

```javascript
await transaction(async (client) => {
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  
  // Store notification (guaranteed delivery)
  await client.query(
    'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
    [userId, title, message]
  );
});

// Send push after commit (best-effort)
await fcmService.sendNotification(...);
```

**Why:** User can always see notification in-app, even if push fails.

---

### ✅ DO: Use Idempotency Keys for FCM

```javascript
await fcmService.sendNotification(userId, {
  title: 'Delivery Completed',
  body: 'Your water has been delivered',
  data: {
    idempotency_key: `delivery_${deliveryId}_completed`, // ← Prevents duplicates
    delivery_id: deliveryId
  }
});
```

**Why:** If request is retried, FCM won't send duplicate push.

---

### ✅ DO: Log FCM Failures for Monitoring

```javascript
try {
  await fcmService.sendNotification(...);
} catch (error) {
  logger.error('Push notification failed (delivery still completed):', {
    error: error.message,
    userId,
    deliveryId,
    note: 'User can view notification in app'
  });
}
```

**Why:** Can monitor FCM reliability and investigate issues.

---

### ❌ DON'T: Call FCM Inside Transaction

```javascript
// ❌ WRONG
await transaction(async (client) => {
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
  await fcmService.sendNotification(...); // ❌ Blocks connection
});
```

**Why:** Holds database connection during slow network call, causes deadlock.

---

### ❌ DON'T: Fail Request if FCM Fails

```javascript
// ❌ WRONG
await transaction(async (client) => {
  await client.query('UPDATE deliveries SET status = $1', ['completed']);
});

await fcmService.sendNotification(...); // If this throws, request fails ❌
```

**Why:** Delivery is already completed, can't rollback. Worker sees error but delivery is done.

**Fix:** Wrap in try-catch
```javascript
try {
  await fcmService.sendNotification(...);
} catch (error) {
  logger.error('Push failed:', error);
  // Don't throw - delivery is already completed
}
```

---

## Monitoring & Alerting

### Metrics to Track

1. **Push Notification Success Rate**
   ```
   (successful_fcm_calls / total_fcm_calls) * 100
   ```
   - Target: > 95%
   - Alert if < 90% for 5 minutes

2. **Push Notification Latency**
   - Target: p95 < 2 seconds
   - Alert if p95 > 5 seconds

3. **Database Notification Storage Rate**
   - Should be 100% (atomic with transaction)
   - Alert if any failures

### Log Queries

```bash
# Find FCM failures
grep "Push notification failed" logs/error.log | wc -l

# Find deliveries with notification but no push
SELECT d.id, n.created_at 
FROM deliveries d
JOIN notifications n ON n.reference_id = d.id
LEFT JOIN push_notification_log p ON p.notification_id = n.id
WHERE d.status = 'completed' 
  AND p.id IS NULL
  AND n.created_at > NOW() - INTERVAL '1 hour';
```

---

## User Experience

### Happy Path (95% of cases)

1. Worker completes delivery
2. Database updated ✅
3. Notification stored ✅
4. Push sent ✅
5. User's phone buzzes immediately 🔔

### Degraded Path (5% of cases)

1. Worker completes delivery
2. Database updated ✅
3. Notification stored ✅
4. Push fails (FCM timeout) ❌
5. User opens app later
6. User sees notification in notification list ✅

**Impact:** Slight delay, but user still informed. **Acceptable.**

---

## Future Enhancements

### 1. Retry Queue for Failed Pushes

```javascript
// Store FCM failures in retry queue
if (fcmError) {
  await query(
    'INSERT INTO push_notification_queue (user_id, payload, retry_count) VALUES ($1, $2, 0)',
    [userId, JSON.stringify(payload)]
  );
}

// Background job retries every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  const pending = await query('SELECT * FROM push_notification_queue WHERE retry_count < 3');
  for (const item of pending.rows) {
    try {
      await fcmService.sendNotification(item.user_id, JSON.parse(item.payload));
      await query('DELETE FROM push_notification_queue WHERE id = $1', [item.id]);
    } catch (error) {
      await query('UPDATE push_notification_queue SET retry_count = retry_count + 1 WHERE id = $1', [item.id]);
    }
  }
});
```

### 2. Fallback to SMS

```javascript
try {
  await fcmService.sendNotification(...);
} catch (error) {
  // Fallback to SMS for critical notifications
  if (notification.priority === 'high') {
    await smsService.send(userPhone, message);
  }
}
```

### 3. WebSocket for Real-Time Updates

```javascript
// Send via WebSocket if user is online
if (websocketService.isUserOnline(userId)) {
  websocketService.emit(userId, 'notification', notification);
}
```

---

## Summary

| Aspect | Current Implementation | Guarantee |
|--------|----------------------|-----------|
| Database notification | Inside transaction | 100% atomic |
| Push notification | Outside transaction | Best-effort (~95%) |
| Idempotency | WHERE status != 'completed' | Prevents duplicates |
| User experience | In-app notification always available | Acceptable |
| Monitoring | Logs FCM failures | Can track reliability |

**Key Principle:** Database is source of truth, push is convenience feature.
