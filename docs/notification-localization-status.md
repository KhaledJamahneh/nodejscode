# Notification Localization Status

## ✅ Fixed Issues

### 1. Admin Notification Filter
**Problem:** Worker assignment notifications were showing in admin notification center
**Fix:** Removed `'worker_assignment'` from admin notification types
**File:** `src/controllers/notifications.controller.js`
**Status:** ✅ Fixed and deployed

## ⚠️ Notifications Needing Localization

### Currently Localized (Using `t()` function):
1. ✅ Scheduled delivery accepted (worker.controller.js:443-444)
2. ✅ Delivery completed (worker.controller.js:735-736)
3. ✅ Request accepted (worker.controller.js:870-871)
4. ✅ Water delivered (admin.controller.js:1044-1045)

### NOT Localized (Hardcoded English):

#### admin.controller.js:
- Line 576: "New Task Assigned" / "Admin assigned you a new delivery request."
- Line 592: "Request Assigned" / "Your request has been assigned to a worker."
- Line 860: "Low Inventory Alert" / "Coupon size X is running low..."
- Line 877: "Low Inventory Alert" / "Coupon size X is running low..."
- Line 1043: "Water Delivered" / "X gallons delivered..."

#### delivery.controller.js:
- Line 156: "New Delivery Request" / "You have a new delivery request..."
- Line 512: "Request Cancelled" / "Your delivery request has been cancelled."

#### payment.controller.js:
- Line 57: "Payment Received" / "Your payment of X has been received."

#### worker.controller.js:
- Line 441: "Delivery Accepted" / "Worker X accepted your scheduled delivery."
- Line 733: "Delivery Completed" / "Your delivery of X gallons has been completed."

## 📝 How to Fix

### Step 1: Add translation keys to messages.json

Example for "New Task Assigned":
```json
{
  "en": {
    "new_task_assigned_title": "New Task Assigned",
    "new_task_assigned_body": "Admin assigned you a new delivery request."
  },
  "ar": {
    "new_task_assigned_title": "تم تعيين مهمة جديدة",
    "new_task_assigned_body": "قام المسؤول بتعيين طلب توصيل جديد لك."
  }
}
```

### Step 2: Get user's preferred language

Before creating notification:
```javascript
const userLang = await client.query(
  'SELECT preferred_language FROM users WHERE id = $1',
  [userId]
);
const lang = userLang.rows[0]?.preferred_language || 'en';
```

### Step 3: Use t() function

```javascript
const { t } = require('../utils/i18n');

await client.query(
  `INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
   VALUES ($1, $2, $3, 'worker_assignment', $4, 'delivery_request')`,
  [
    userId,
    t(lang, 'new_task_assigned_title'),
    t(lang, 'new_task_assigned_body'),
    requestId
  ]
);
```

## 🎯 Priority Order

1. **High Priority** (User-facing):
   - New Task Assigned (workers see this often)
   - Request Assigned (clients see this)
   - Delivery Completed
   - Payment Received

2. **Medium Priority**:
   - Low Inventory Alert
   - Request Cancelled

3. **Low Priority** (already localized in some places):
   - Water Delivered (partially done)

## 📊 Current Status

- **Total Notifications:** ~15 types
- **Localized:** 4 (27%)
- **Not Localized:** 11 (73%)
- **Admin Filter:** ✅ Fixed
