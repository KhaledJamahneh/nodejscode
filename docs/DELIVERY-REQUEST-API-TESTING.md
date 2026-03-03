# Delivery Request System API Testing Guide

Complete guide to test all delivery request endpoints.

## Overview

The delivery request system allows clients to:
- 📝 Submit water delivery requests with priority levels
- 📋 View all their requests
- ✏️ Update pending requests
- ❌ Cancel pending requests
- 📜 View delivery history

## Priority Levels

1. **urgent** - Needs water ASAP (appears first in worker's list)
2. **mid_urgent** - Moderately urgent
3. **non_urgent** - Standard delivery (default)

---

## API Endpoints

### 1. Create Delivery Request

**Endpoint:** `POST /api/v1/deliveries/request`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "requested_gallons": 40,
  "priority": "urgent",
  "notes": "Please deliver before 3 PM. Building entrance code: 1234"
}
```

**Fields:**
- `requested_gallons` (required): 1-500 gallons
- `priority` (optional): "urgent", "mid_urgent", or "non_urgent" (default: "non_urgent")
- `notes` (optional): Additional instructions (max 500 chars)

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Delivery request submitted successfully",
  "data": {
    "id": 1,
    "client_id": 1,
    "priority": "urgent",
    "requested_gallons": 40,
    "request_date": "2026-02-15T20:30:00.000Z",
    "status": "pending",
    "notes": "Please deliver before 3 PM. Building entrance code: 1234"
  }
}
```

**Validation:**
- Maximum 3 pending requests per client
- For coupon book users: checks sufficient coupons
- Gallons must be 1-500

---

### 2. Get All Requests

**Endpoint:** `GET /api/v1/deliveries/requests`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `status` (optional): "pending", "in_progress", "completed", "cancelled"
- `limit` (optional): 1-100, default: 20
- `offset` (optional): For pagination, default: 0

**Examples:**
```
GET /api/v1/deliveries/requests
GET /api/v1/deliveries/requests?status=pending
GET /api/v1/deliveries/requests?limit=10&offset=0
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "id": 3,
        "priority": "urgent",
        "requested_gallons": 40,
        "request_date": "2026-02-15T20:30:00.000Z",
        "status": "pending",
        "notes": "Please deliver before 3 PM",
        "created_at": "2026-02-15T20:30:00.000Z",
        "updated_at": "2026-02-15T20:30:00.000Z",
        "assigned_worker_name": null,
        "worker_phone": null
      },
      {
        "id": 2,
        "priority": "mid_urgent",
        "requested_gallons": 20,
        "request_date": "2026-02-14T10:00:00.000Z",
        "status": "in_progress",
        "notes": null,
        "created_at": "2026-02-14T10:00:00.000Z",
        "updated_at": "2026-02-14T11:00:00.000Z",
        "assigned_worker_name": "Ahmed Ali",
        "worker_phone": "+1234567892"
      }
    ],
    "pagination": {
      "total": 5,
      "limit": 20,
      "offset": 0,
      "has_more": false
    }
  }
}
```

---

### 3. Get Specific Request

**Endpoint:** `GET /api/v1/deliveries/requests/:id`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Example:**
```
GET /api/v1/deliveries/requests/3
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "priority": "urgent",
    "requested_gallons": 40,
    "request_date": "2026-02-15T20:30:00.000Z",
    "status": "pending",
    "notes": "Please deliver before 3 PM",
    "created_at": "2026-02-15T20:30:00.000Z",
    "updated_at": "2026-02-15T20:30:00.000Z",
    "assigned_worker_name": "Ahmed Ali",
    "worker_phone": "+1234567892",
    "worker_email": "worker@test.com"
  }
}
```

---

### 4. Update Request

**Endpoint:** `PATCH /api/v1/deliveries/requests/:id`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body (all fields optional):**
```json
{
  "priority": "mid_urgent",
  "requested_gallons": 60,
  "notes": "Updated notes: Use back entrance"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery request updated successfully",
  "data": {
    "id": 3,
    "client_id": 1,
    "priority": "mid_urgent",
    "requested_gallons": 60,
    "request_date": "2026-02-15T20:30:00.000Z",
    "status": "pending",
    "notes": "Updated notes: Use back entrance",
    "assigned_worker_id": null,
    "created_at": "2026-02-15T20:30:00.000Z",
    "updated_at": "2026-02-15T20:45:00.000Z"
  }
}
```

**Rules:**
- Can only update requests with status "pending"
- Cannot update assigned or completed requests

---

### 5. Cancel Request

**Endpoint:** `DELETE /api/v1/deliveries/requests/:id`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Example:**
```
DELETE /api/v1/deliveries/requests/3
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery request cancelled successfully"
}
```

**Rules:**
- Can only cancel requests with status "pending"
- Creates a notification for the client

---

### 6. Get Delivery History

**Endpoint:** `GET /api/v1/deliveries/history`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `limit` (optional): 1-100, default: 20
- `offset` (optional): For pagination, default: 0
- `start_date` (optional): ISO 8601 date (e.g., "2026-01-01")
- `end_date` (optional): ISO 8601 date

**Examples:**
```
GET /api/v1/deliveries/history
GET /api/v1/deliveries/history?limit=10
GET /api/v1/deliveries/history?start_date=2026-01-01&end_date=2026-02-01
```

**Response:**
```json
{
  "success": true,
  "data": {
    "deliveries": [
      {
        "id": 15,
        "delivery_date": "2026-02-14",
        "actual_delivery_time": "2026-02-14T14:30:00.000Z",
        "gallons_delivered": 20,
        "status": "completed",
        "notes": "Delivered successfully",
        "photo_url": null,
        "worker_name": "Ahmed Ali",
        "worker_phone": "+1234567892"
      },
      {
        "id": 14,
        "delivery_date": "2026-02-07",
        "actual_delivery_time": "2026-02-07T10:15:00.000Z",
        "gallons_delivered": 20,
        "status": "completed",
        "notes": null,
        "photo_url": null,
        "worker_name": "Ahmed Ali",
        "worker_phone": "+1234567892"
      }
    ],
    "pagination": {
      "total": 12,
      "limit": 20,
      "offset": 0,
      "has_more": false
    }
  }
}
```

---

## Complete Testing Workflow

### Step 1: Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testclient","password":"Client123!"}'
```

Copy the `accessToken`.

### Step 2: Create Urgent Request
```bash
curl -X POST http://localhost:3000/api/v1/deliveries/request \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requested_gallons": 40,
    "priority": "urgent",
    "notes": "Need water ASAP!"
  }'
```

### Step 3: Create Normal Request
```bash
curl -X POST http://localhost:3000/api/v1/deliveries/request \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requested_gallons": 20,
    "priority": "non_urgent"
  }'
```

### Step 4: View All Requests
```bash
curl -X GET http://localhost:3000/api/v1/deliveries/requests \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 5: View Only Pending
```bash
curl -X GET "http://localhost:3000/api/v1/deliveries/requests?status=pending" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 6: Update a Request
```bash
curl -X PATCH http://localhost:3000/api/v1/deliveries/requests/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "priority": "mid_urgent",
    "notes": "Changed to mid-urgent"
  }'
```

### Step 7: Cancel a Request
```bash
curl -X DELETE http://localhost:3000/api/v1/deliveries/requests/2 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 8: View Delivery History
```bash
curl -X GET http://localhost:3000/api/v1/deliveries/history \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Testing in Postman

### Collection Setup

1. **Create Collection:** "Einhod - Delivery Requests"

2. **Add Requests:**

   **Create Request:**
   - Name: "Create Urgent Delivery"
   - Method: POST
   - URL: `{{base_url}}/deliveries/request`
   - Headers: `Authorization: Bearer {{access_token}}`
   - Body:
     ```json
     {
       "requested_gallons": 40,
       "priority": "urgent",
       "notes": "Need ASAP"
     }
     ```

   **Get All Requests:**
   - Name: "Get All Requests"
   - Method: GET
   - URL: `{{base_url}}/deliveries/requests`
   
   **Get Pending Only:**
   - Name: "Get Pending Requests"
   - Method: GET
   - URL: `{{base_url}}/deliveries/requests?status=pending`
   
   **Update Request:**
   - Name: "Update Request"
   - Method: PATCH
   - URL: `{{base_url}}/deliveries/requests/1`
   - Body:
     ```json
     {
       "priority": "mid_urgent"
     }
     ```
   
   **Cancel Request:**
   - Name: "Cancel Request"
   - Method: DELETE
   - URL: `{{base_url}}/deliveries/requests/1`

---

## Common Errors

### 400 - Too Many Pending Requests
```json
{
  "success": false,
  "message": "You already have 3 pending requests. Please wait for them to be processed."
}
```
**Solution:** Wait for existing requests to be completed or cancel some.

### 400 - Insufficient Coupons
```json
{
  "success": false,
  "message": "Insufficient coupons. You need 2 coupons but only have 1.",
  "data": {
    "coupons_needed": 2,
    "coupons_available": 1
  }
}
```
**Solution:** Renew subscription or request fewer gallons.

### 400 - Can Only Update Pending
```json
{
  "success": false,
  "message": "Can only update pending requests"
}
```
**Solution:** Request is already assigned or completed.

### 404 - Request Not Found
```json
{
  "success": false,
  "message": "Delivery request not found"
}
```
**Solution:** Check the request ID or ensure it belongs to your account.

---

## Business Rules

1. **Maximum Pending Requests:** 3 per client
2. **Coupon Validation:** For coupon book users, system checks sufficient coupons
3. **Coupon Calculation:** 20 gallons = 1 coupon
4. **Update/Cancel:** Only pending requests can be modified
5. **Priority Order:** Urgent → Mid-Urgent → Non-Urgent
6. **Notifications:** Created on submit and cancel

---

## Testing Checklist

- [ ] Create urgent request - should succeed
- [ ] Create normal request - should succeed
- [ ] Create 4th request - should fail (max 3 pending)
- [ ] Get all requests - should show all
- [ ] Get pending only - should filter
- [ ] Get specific request by ID - should return details
- [ ] Update pending request - should succeed
- [ ] Update completed request - should fail
- [ ] Cancel pending request - should succeed
- [ ] Cancel completed request - should fail
- [ ] View delivery history - should show past deliveries

---

**Status:** ✅ COMPLETE AND READY TO TEST
**Endpoints:** 6 fully functional APIs
**Next Feature:** Worker Schedule or GPS Tracking
