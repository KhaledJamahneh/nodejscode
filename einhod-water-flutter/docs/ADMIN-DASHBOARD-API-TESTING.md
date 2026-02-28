# Admin Dashboard API Testing Guide

Complete guide to test all admin management and analytics endpoints.

## Overview

The admin system provides:
- 📊 **Dashboard** - Real-time metrics and overview
- 📋 **Request Management** - View and assign delivery requests
- 🚚 **Delivery Management** - Monitor all deliveries
- 👥 **User Management** - Create and manage users
- 📈 **Analytics** - Business insights and reports

---

## Test Account

**Username:** `owner`  
**Password:** `Admin123!`  
**Role:** owner (has all admin permissions)

---

## API Endpoints

### 1. Get Dashboard Overview

**Endpoint:** `GET /api/v1/admin/dashboard`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "metrics": {
      "active_workers": 1,
      "pending_deliveries": 2,
      "today_deliveries": 3,
      "pending_requests": 1,
      "urgent_requests": 1,
      "active_clients": 1,
      "low_inventory_workers": 0,
      "clients_with_debt": 0
    },
    "revenue": {
      "today": 0,
      "this_month": 350
    },
    "recent_activity": [
      {
        "id": 11,
        "delivery_date": "2026-02-15",
        "actual_delivery_time": "2026-02-15T20:30:00.000Z",
        "status": "completed",
        "gallons_delivered": 20,
        "client_name": "John Doe",
        "worker_name": "Ahmed Ali"
      }
    ]
  }
}
```

**Metrics Explained:**
- `active_workers`: Workers currently active
- `pending_deliveries`: Deliveries awaiting completion
- `today_deliveries`: Total scheduled for today
- `pending_requests`: Client requests not assigned
- `urgent_requests`: Urgent priority requests
- `active_clients`: Active client accounts
- `low_inventory_workers`: Workers with <10 gallons
- `clients_with_debt`: Clients owing money

---

### 2. Get All Delivery Requests

**Endpoint:** `GET /api/v1/admin/requests`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `status` (optional): pending, in_progress, completed, cancelled
- `priority` (optional): urgent, mid_urgent, non_urgent
- `limit` (optional): 1-100, default 50
- `offset` (optional): For pagination

**Examples:**
```
GET /api/v1/admin/requests
GET /api/v1/admin/requests?status=pending
GET /api/v1/admin/requests?priority=urgent
GET /api/v1/admin/requests?status=pending&priority=urgent&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "id": 1,
        "priority": "urgent",
        "requested_gallons": 40,
        "request_date": "2026-02-15T19:35:36.851Z",
        "status": "pending",
        "notes": "Need water ASAP!",
        "client_name": "John Doe",
        "client_address": "123 Main Street, City Center",
        "client_phone": "+1234567891",
        "assigned_worker_name": null
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 50,
      "offset": 0,
      "has_more": false
    }
  }
}
```

---

### 3. Assign Worker to Request

**Endpoint:** `POST /api/v1/admin/requests/:id/assign`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "worker_id": 1
}
```

**Example:**
```
POST /api/v1/admin/requests/1/assign
Body: {"worker_id": 1}
```

**Response:**
```json
{
  "success": true,
  "message": "Worker assigned successfully"
}
```

**Rules:**
- Can only assign pending requests
- Worker must exist
- Request will appear in worker's secondary list

---

### 4. Get All Deliveries

**Endpoint:** `GET /api/v1/admin/deliveries`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `status` (optional): pending, in_progress, completed, cancelled
- `worker_id` (optional): Filter by specific worker
- `date` (optional): YYYY-MM-DD format
- `limit` (optional): 1-100, default 50
- `offset` (optional): For pagination

**Examples:**
```
GET /api/v1/admin/deliveries
GET /api/v1/admin/deliveries?status=pending
GET /api/v1/admin/deliveries?worker_id=1
GET /api/v1/admin/deliveries?date=2026-02-15
GET /api/v1/admin/deliveries?status=completed&date=2026-02-15
```

**Response:**
```json
{
  "success": true,
  "data": {
    "deliveries": [
      {
        "id": 11,
        "delivery_date": "2026-02-15",
        "scheduled_time": "09:00:00",
        "actual_delivery_time": "2026-02-15T09:15:00.000Z",
        "gallons_delivered": 20,
        "status": "completed",
        "notes": "Delivered successfully",
        "client_name": "John Doe",
        "client_address": "123 Main Street",
        "client_phone": "+1234567891",
        "worker_name": "Ahmed Ali"
      }
    ],
    "pagination": {
      "total": 15,
      "limit": 50,
      "offset": 0,
      "has_more": false
    }
  }
}
```

---

### 5. Get All Users

**Endpoint:** `GET /api/v1/admin/users`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `role` (optional): client, delivery_worker, onsite_worker, administrator, owner
- `is_active` (optional): true or false
- `search` (optional): Search in username, email, phone
- `limit` (optional): 1-100, default 50
- `offset` (optional): For pagination

**Examples:**
```
GET /api/v1/admin/users
GET /api/v1/admin/users?role=client
GET /api/v1/admin/users?is_active=true
GET /api/v1/admin/users?search=john
GET /api/v1/admin/users?role=client&is_active=true
```

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 3,
        "username": "testclient",
        "email": "client@test.com",
        "phone_number": "+1234567891",
        "role": "client",
        "is_active": true,
        "created_at": "2026-02-15T18:58:06.173Z",
        "last_login": "2026-02-15T19:19:04.852Z"
      },
      {
        "id": 4,
        "username": "testworker",
        "email": "worker@test.com",
        "phone_number": "+1234567892",
        "role": "delivery_worker",
        "is_active": true,
        "created_at": "2026-02-15T18:58:06.295Z",
        "last_login": "2026-02-15T20:45:00.000Z"
      }
    ],
    "pagination": {
      "total": 2,
      "limit": 50,
      "offset": 0,
      "has_more": false
    }
  }
}
```

---

### 6. Create New User

**Endpoint:** `POST /api/v1/admin/users`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body (Client):**
```json
{
  "username": "newclient",
  "email": "newclient@example.com",
  "phone_number": "+1234567899",
  "password": "Password123!",
  "role": "client",
  "full_name": "New Client Name",
  "address": "123 New Street, City",
  "latitude": 31.9500,
  "longitude": 35.9400,
  "subscription_type": "coupon_book"
}
```

**Request Body (Worker):**
```json
{
  "username": "newworker",
  "email": "newworker@example.com",
  "phone_number": "+1234567898",
  "password": "Password123!",
  "role": "delivery_worker",
  "full_name": "New Worker Name",
  "worker_type": "delivery"
}
```

**Fields:**
- `username` (required): 3-50 chars, alphanumeric + underscore
- `email` (optional): Valid email format
- `phone_number` (required): International format
- `password` (required): Min 8 chars, uppercase, lowercase, number
- `role` (required): client, delivery_worker, onsite_worker, administrator
- `full_name` (required): 2-255 characters
- `address` (for clients): Client address
- `latitude/longitude` (for clients): GPS coordinates
- `subscription_type` (for clients): coupon_book or cash
- `worker_type` (for workers): delivery, onsite, social_media

**Response:**
```json
{
  "success": true,
  "message": "User created successfully"
}
```

**What happens automatically:**
- Password is hashed securely
- Client profile created (if role is client)
- Worker profile created (if role is worker)
- Client gets 100 coupons (if coupon_book)
- Subscription set to 1 year

---

### 7. Toggle User Active Status

**Endpoint:** `PUT /api/v1/admin/users/:id/toggle-active`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Example:**
```
PUT /api/v1/admin/users/3/toggle-active
```

**Response:**
```json
{
  "success": true,
  "message": "User deactivated",
  "data": {
    "is_active": false
  }
}
```

**Rules:**
- Cannot deactivate your own account
- Toggles between active/inactive
- Inactive users cannot login

---

### 8. Get Analytics Overview

**Endpoint:** `GET /api/v1/admin/analytics/overview`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `start_date` (optional): YYYY-MM-DD, defaults to 30 days ago
- `end_date` (optional): YYYY-MM-DD, defaults to today

**Examples:**
```
GET /api/v1/admin/analytics/overview
GET /api/v1/admin/analytics/overview?start_date=2026-01-01&end_date=2026-02-15
```

**Response:**
```json
{
  "success": true,
  "data": {
    "deliveries": {
      "total_deliveries": "15",
      "total_gallons": "300",
      "avg_gallons": "20.0000000000000000",
      "unique_clients": "1",
      "active_workers": "1"
    },
    "revenue": {
      "total_transactions": "2",
      "total_revenue": "350.00",
      "avg_transaction": "175.0000000000000000",
      "cash_revenue": "150.00",
      "card_revenue": "200.00"
    },
    "top_workers": [
      {
        "id": 1,
        "full_name": "Ahmed Ali",
        "deliveries_completed": "15",
        "total_gallons": "300"
      }
    ],
    "clients": {
      "total_clients": "1",
      "active_subscriptions": "1",
      "expired_subscriptions": "0",
      "total_debt": "0.00"
    },
    "period": {
      "start": "2026-01-16",
      "end": "2026-02-15"
    }
  }
}
```

---

## Complete Testing Workflow

### Step 1: Login as Admin

```bash
curl -X POST http://localhost:5051/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"owner","password":"Admin123!"}'
```

Copy the `accessToken`.

### Step 2: View Dashboard

```bash
curl -X GET http://localhost:5051/api/v1/admin/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 3: View All Requests

```bash
curl -X GET http://localhost:5051/api/v1/admin/requests \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 4: View Pending Requests Only

```bash
curl -X GET "http://localhost:5051/api/v1/admin/requests?status=pending" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 5: Assign Worker to Request

```bash
curl -X POST http://localhost:5051/api/v1/admin/requests/1/assign \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"worker_id": 1}'
```

### Step 6: View All Deliveries

```bash
curl -X GET http://localhost:5051/api/v1/admin/deliveries \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 7: View Today's Deliveries

```bash
curl -X GET "http://localhost:5051/api/v1/admin/deliveries?date=2026-02-15" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 8: View All Users

```bash
curl -X GET http://localhost:5051/api/v1/admin/users \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 9: Create New Client

```bash
curl -X POST http://localhost:5051/api/v1/admin/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "phone_number": "+1234567999",
    "password": "Password123!",
    "role": "client",
    "full_name": "John Doe",
    "address": "456 Oak Street",
    "latitude": 31.95,
    "longitude": 35.93,
    "subscription_type": "coupon_book"
  }'
```

### Step 10: Get Analytics

```bash
curl -X GET http://localhost:5051/api/v1/admin/analytics/overview \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Testing in Postman

### Collection: "Einhod - Admin Dashboard"

1. **Login as Admin**
   - POST `{{base_url}}/auth/login`
   - Body: `{"username":"owner","password":"Admin123!"}`

2. **Dashboard Overview**
   - GET `{{base_url}}/admin/dashboard`

3. **All Requests**
   - GET `{{base_url}}/admin/requests`

4. **Pending Requests**
   - GET `{{base_url}}/admin/requests?status=pending`

5. **Urgent Requests**
   - GET `{{base_url}}/admin/requests?priority=urgent`

6. **Assign Worker**
   - POST `{{base_url}}/admin/requests/1/assign`
   - Body: `{"worker_id": 1}`

7. **All Deliveries**
   - GET `{{base_url}}/admin/deliveries`

8. **Today's Deliveries**
   - GET `{{base_url}}/admin/deliveries?date=2026-02-15`

9. **All Users**
   - GET `{{base_url}}/admin/users`

10. **Create User**
    - POST `{{base_url}}/admin/users`
    - Body: See examples above

11. **Toggle User Status**
    - PUT `{{base_url}}/admin/users/3/toggle-active`

12. **Analytics**
    - GET `{{base_url}}/admin/analytics/overview`

---

## Common Errors

### 403 Forbidden
```json
{
  "success": false,
  "message": "You do not have permission to access this resource"
}
```
**Solution:** Must be logged in as administrator or owner.

### 400 - Can't Deactivate Self
```json
{
  "success": false,
  "message": "Cannot deactivate your own account"
}
```
**Solution:** Use a different admin account to deactivate.

### 400 - Username Exists
```json
{
  "success": false,
  "message": "Username or phone number already exists"
}
```
**Solution:** Use unique username and phone number.

---

## Business Rules

1. **Admin/Owner Only**: All endpoints require administrator or owner role
2. **Self-Protection**: Cannot deactivate own account
3. **Auto-Profile Creation**: Profiles created automatically with users
4. **Default Subscription**: Clients get 1 year, 100 coupons
5. **Secure Passwords**: Automatically hashed with bcrypt
6. **Analytics Period**: Defaults to last 30 days if not specified

---

## Testing Checklist

- [ ] Login as owner
- [ ] View dashboard - should show all metrics
- [ ] View all requests - should list requests
- [ ] Filter requests by status
- [ ] Assign worker to request
- [ ] View all deliveries
- [ ] Filter deliveries by date
- [ ] View all users
- [ ] Search users by username
- [ ] Create new client user
- [ ] Create new worker user
- [ ] Toggle user active/inactive
- [ ] View analytics overview
- [ ] Filter analytics by date range

---

**Status:** ✅ COMPLETE AND READY TO TEST
**Endpoints:** 8 fully functional APIs
**Features:** Dashboard, requests, deliveries, users, analytics
**Next Feature:** GPS Tracking or Payment Processing
