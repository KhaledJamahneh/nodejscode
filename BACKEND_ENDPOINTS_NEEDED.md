# 🔧 Backend Endpoints Required for Phase 5

## Quick Implementation Guide

Add these 4 endpoints to complete the frontend integration.

---

## 1️⃣ User Registration (Admin)

**Endpoint:** `POST /api/v1/admin/users/register`

**Purpose:** Allow admins to create new users/workers

**Request Body:**
```json
{
  "username": "newuser123",
  "password": "SecurePass123!",
  "role": "delivery_worker",
  "phone_number": "+1234567890",
  "full_name": "John Doe",
  "is_dual_role": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "user_id": 42,
    "username": "newuser123",
    "role": "delivery_worker"
  }
}
```

**Implementation:**
```javascript
// src/controllers/admin.controller.js
exports.registerUser = async (req, res) => {
  const { username, password, role, phone_number, full_name, is_dual_role } = req.body;
  
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);
  
  // Insert user
  const result = await pool.query(
    `INSERT INTO users (username, password_hash, role, phone_number, is_active, is_dual_role)
     VALUES ($1, $2, $3, $4, true, $5) RETURNING id`,
    [username, hashedPassword, role, phone_number, is_dual_role || false]
  );
  
  const userId = result.rows[0].id;
  
  // Create role-specific profile
  if (role === 'client') {
    await pool.query(
      `INSERT INTO client_profiles (user_id, full_name) VALUES ($1, $2)`,
      [userId, full_name]
    );
  } else if (role === 'delivery_worker' || role === 'onsite_worker') {
    await pool.query(
      `INSERT INTO worker_profiles (user_id, full_name, worker_type) VALUES ($1, $2, $3)`,
      [userId, full_name, role]
    );
  }
  
  res.json({ success: true, message: 'User created', data: { user_id: userId, username, role } });
};
```

---

## 2️⃣ Dispenser Settings (Client)

**Endpoint:** `GET /api/v1/clients/dispensers/settings`

**Purpose:** Get client's dispenser settings

**Response:**
```json
{
  "success": true,
  "data": {
    "auto_refill": true,
    "notifications_enabled": true,
    "low_water_threshold": 2
  }
}
```

**Endpoint:** `PUT /api/v1/clients/dispensers/:id/settings`

**Purpose:** Update dispenser settings

**Request Body:**
```json
{
  "auto_refill": false,
  "notifications_enabled": true,
  "low_water_threshold": 3
}
```

**Implementation:**
```javascript
// Add column to client_profiles table first:
// ALTER TABLE client_profiles ADD COLUMN dispenser_settings JSONB DEFAULT '{"auto_refill": true, "notifications_enabled": true, "low_water_threshold": 2}';

exports.getDispenserSettings = async (req, res) => {
  const userId = req.user.id;
  
  const result = await pool.query(
    `SELECT dispenser_settings FROM client_profiles WHERE user_id = $1`,
    [userId]
  );
  
  res.json({ success: true, data: result.rows[0].dispenser_settings });
};

exports.updateDispenserSettings = async (req, res) => {
  const userId = req.user.id;
  const settings = req.body;
  
  await pool.query(
    `UPDATE client_profiles SET dispenser_settings = $1 WHERE user_id = $2`,
    [JSON.stringify(settings), userId]
  );
  
  res.json({ success: true, message: 'Settings updated' });
};
```

---

## 3️⃣ Coupon Price Update (Admin)

**Endpoint:** `PUT /api/v1/admin/coupon-sizes/:id`

**Purpose:** Update coupon size price

**Request Body:**
```json
{
  "price": 15.99
}
```

**Response:**
```json
{
  "success": true,
  "message": "Price updated successfully"
}
```

**Implementation:**
```javascript
exports.updateCouponPrice = async (req, res) => {
  const { id } = req.params;
  const { price } = req.body;
  
  await pool.query(
    `UPDATE coupon_sizes SET price = $1 WHERE id = $2`,
    [price, id]
  );
  
  res.json({ success: true, message: 'Price updated' });
};
```

---

## 4️⃣ Request Cancel/Delete (Admin)

**Endpoint:** `DELETE /api/v1/admin/requests/:id`

**Purpose:** Permanently delete a request

**Response:**
```json
{
  "success": true,
  "message": "Request deleted successfully"
}
```

**Endpoint:** `POST /api/v1/admin/requests/:id/cancel`

**Purpose:** Cancel a request (soft delete)

**Response:**
```json
{
  "success": true,
  "message": "Request cancelled successfully"
}
```

**Implementation:**
```javascript
exports.deleteRequest = async (req, res) => {
  const { id } = req.params;
  
  await pool.query(`DELETE FROM delivery_requests WHERE id = $1`, [id]);
  
  res.json({ success: true, message: 'Request deleted' });
};

exports.cancelRequest = async (req, res) => {
  const { id } = req.params;
  
  await pool.query(
    `UPDATE delivery_requests SET status = 'cancelled' WHERE id = $1`,
    [id]
  );
  
  res.json({ success: true, message: 'Request cancelled' });
};
```

---

## 5️⃣ CRITICAL FIX: Payment Endpoint

**Issue:** Dio 500 error when `debt` field is null

**Location:** Payment controller (wherever you handle payments)

**Fix:**
```javascript
// BEFORE (causes 500 error):
const debt = req.body.debt;
const totalAmount = debt + processingFee;

// AFTER (safe):
const debt = req.body.debt || 0;
const totalAmount = debt + processingFee;
```

---

## 📋 Routes to Add

Add these to your route files:

```javascript
// src/routes/admin.routes.js
router.post('/users/register', adminController.registerUser);
router.put('/coupon-sizes/:id', adminController.updateCouponPrice);
router.delete('/requests/:id', adminController.deleteRequest);
router.post('/requests/:id/cancel', adminController.cancelRequest);

// src/routes/client.routes.js
router.get('/dispensers/settings', clientController.getDispenserSettings);
router.put('/dispensers/:id/settings', clientController.updateDispenserSettings);
```

---

## ✅ Testing Checklist

After implementing, test with these curl commands:

```bash
# 1. Register user
curl -X POST http://localhost:3000/api/v1/admin/users/register \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test123","password":"Test123!","role":"client","phone_number":"+1234567890","full_name":"Test User"}'

# 2. Get dispenser settings
curl -X GET http://localhost:3000/api/v1/clients/dispensers/settings \
  -H "Authorization: Bearer YOUR_CLIENT_TOKEN"

# 3. Update coupon price
curl -X PUT http://localhost:3000/api/v1/admin/coupon-sizes/1 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"price":19.99}'

# 4. Cancel request
curl -X POST http://localhost:3000/api/v1/admin/requests/5/cancel \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## 🚀 Quick Setup

1. Copy the controller code above
2. Add routes to your route files
3. Run database migration for dispenser_settings column
4. Restart your server
5. Test with curl or Postman
6. Frontend will work automatically

---

**Estimated Implementation Time:** 30-45 minutes
