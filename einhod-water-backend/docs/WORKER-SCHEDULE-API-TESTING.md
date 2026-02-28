# Worker Schedule & Deliveries API Testing Guide

Complete guide to test all worker delivery management endpoints.

## Overview

The worker system allows delivery workers to:
- 📋 View daily delivery schedule (Main List)
- 🚨 View on-demand requests (Secondary List)  
- ✅ Start and complete deliveries
- 📦 Accept and complete requests
- 🚗 Update vehicle inventory
- 📍 Toggle GPS sharing

---

## Test Account

**Username:** `testworker`  
**Password:** `Worker123!`  
**Role:** delivery_worker

---

## API Endpoints

### 1. Get Worker Profile

**Endpoint:** `GET /api/v1/workers/profile`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 4,
    "username": "testworker",
    "email": "worker@test.com",
    "phone_number": "+1234567892",
    "profile_id": 1,
    "full_name": "Ahmed Ali",
    "worker_type": "delivery",
    "hire_date": "2023-01-15",
    "current_salary": "2000.00",
    "debt_advances": "0.00",
    "vehicle_current_gallons": 50,
    "gps_sharing_enabled": false,
    "is_dual_role": false
  }
}
```

---

### 2. Get Main Schedule (Today's Deliveries)

**Endpoint:** `GET /api/v1/workers/schedule/main`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `date` (optional): YYYY-MM-DD format, defaults to today

**Examples:**
```
GET /api/v1/workers/schedule/main
GET /api/v1/workers/schedule/main?date=2026-02-16
```

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2026-02-15",
    "deliveries": [
      {
        "id": 11,
        "delivery_date": "2026-02-15",
        "scheduled_time": "09:00:00",
        "scheduled_gallons": 20,
        "status": "pending",
        "notes": null,
        "client_name": "John Doe",
        "client_address": "123 Main Street, City Center, Apartment 4B",
        "latitude": "31.95220000",
        "longitude": "35.93320000",
        "client_phone": "+1234567891",
        "remaining_coupons": 85,
        "subscription_type": "coupon_book"
      },
      {
        "id": 12,
        "delivery_date": "2026-02-15",
        "scheduled_time": "14:00:00",
        "scheduled_gallons": 20,
        "status": "pending",
        "notes": null,
        "client_name": "John Doe",
        "client_address": "123 Main Street, City Center, Apartment 4B",
        "latitude": "31.95220000",
        "longitude": "35.93320000",
        "client_phone": "+1234567891",
        "remaining_coupons": 85,
        "subscription_type": "coupon_book"
      },
      {
        "id": 13,
        "delivery_date": "2026-02-15",
        "scheduled_time": "16:30:00",
        "scheduled_gallons": 20,
        "status": "pending",
        "notes": null,
        "client_name": "John Doe",
        "client_address": "123 Main Street, City Center, Apartment 4B",
        "latitude": "31.95220000",
        "longitude": "35.93320000",
        "client_phone": "+1234567891",
        "remaining_coupons": 85,
        "subscription_type": "coupon_book"
      }
    ],
    "total": 3
  }
}
```

---

### 3. Get Secondary List (On-Demand Requests)

**Endpoint:** `GET /api/v1/workers/schedule/secondary`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
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
        "client_address": "123 Main Street, City Center, Apartment 4B",
        "latitude": "31.95220000",
        "longitude": "35.93320000",
        "client_phone": "+1234567891",
        "remaining_coupons": 85,
        "subscription_type": "coupon_book",
        "assigned_to_me": false
      }
    ],
    "total": 1,
    "urgent_count": 1,
    "assigned_to_me": 0
  }
}
```

**Sorted by:**
1. Priority (urgent → mid_urgent → non_urgent)
2. Request date (oldest first)

---

### 4. Start Delivery

**Endpoint:** `POST /api/v1/workers/deliveries/:id/start`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Example:**
```
POST /api/v1/workers/deliveries/11/start
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery marked as in progress"
}
```

**Rules:**
- Can only start deliveries assigned to you
- Delivery must be in "pending" status

---

### 5. Complete Delivery (Main List)

**Endpoint:** `POST /api/v1/workers/deliveries/:id/complete`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "gallons_delivered": 20,
  "delivery_latitude": 31.9522,
  "delivery_longitude": 35.9332,
  "notes": "Delivered successfully to apartment 4B",
  "photo_url": "https://example.com/photo.jpg"
}
```

**Fields:**
- `gallons_delivered` (required): 1-500 gallons
- `delivery_latitude` (optional): GPS latitude
- `delivery_longitude` (optional): GPS longitude
- `notes` (optional): Delivery notes
- `photo_url` (optional): Photo proof URL

**Response:**
```json
{
  "success": true,
  "message": "Delivery completed successfully"
}
```

**What happens:**
- ✅ Marks delivery as completed
- ✅ Deducts coupons from client (if coupon book)
- ✅ Updates client's monthly usage
- ✅ Sends notification to client
- ✅ Records GPS location

---

### 6. Accept Request (Secondary List)

**Endpoint:** `POST /api/v1/workers/requests/:id/accept`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Example:**
```
POST /api/v1/workers/requests/1/accept
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery request accepted"
}
```

**What happens:**
- ✅ Assigns request to you
- ✅ Changes status to "in_progress"
- ✅ Request appears in your secondary list

---

### 7. Complete Request (Secondary List)

**Endpoint:** `POST /api/v1/workers/requests/:id/complete`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "gallons_delivered": 40,
  "delivery_latitude": 31.9522,
  "delivery_longitude": 35.9332,
  "notes": "Delivered as requested",
  "photo_url": "https://example.com/photo.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery request completed successfully"
}
```

**What happens:**
- ✅ Creates a new delivery record
- ✅ Marks request as completed
- ✅ Deducts coupons from client
- ✅ Updates client's usage
- ✅ Sends notification to client

---

### 8. Update Vehicle Inventory

**Endpoint:** `PUT /api/v1/workers/vehicle/inventory`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "current_gallons": 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Vehicle inventory updated",
  "data": {
    "current_gallons": 100
  }
}
```

**Use cases:**
- After loading vehicle at station
- After completing deliveries
- When running low (system alerts at <10 gallons)

---

### 9. Toggle GPS Sharing

**Endpoint:** `PUT /api/v1/workers/gps/toggle`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{
  "enabled": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "GPS sharing enabled",
  "data": {
    "gps_sharing_enabled": true
  }
}
```

**Privacy:**
- Workers control when GPS is shared
- Only admins can see location when enabled
- Can turn off anytime

---

## Complete Testing Workflow

### Step 1: Login as Worker

```bash
curl -X POST http://localhost:5051/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testworker","password":"Worker123!"}'
```

Copy the `accessToken`.

### Step 2: View Profile

```bash
curl -X GET http://localhost:5051/api/v1/workers/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 3: Check Today's Schedule

```bash
curl -X GET http://localhost:5051/api/v1/workers/schedule/main \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Should show 3 scheduled deliveries.

### Step 4: Check Secondary List

```bash
curl -X GET http://localhost:5051/api/v1/workers/schedule/secondary \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Should show the urgent request created by testclient.

### Step 5: Start First Delivery

```bash
curl -X POST http://localhost:5051/api/v1/workers/deliveries/11/start \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 6: Complete First Delivery

```bash
curl -X POST http://localhost:5051/api/v1/workers/deliveries/11/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "gallons_delivered": 20,
    "delivery_latitude": 31.9522,
    "delivery_longitude": 35.9332,
    "notes": "Delivered successfully"
  }'
```

### Step 7: Accept Urgent Request

```bash
curl -X POST http://localhost:5051/api/v1/workers/requests/1/accept \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 8: Complete the Request

```bash
curl -X POST http://localhost:5051/api/v1/workers/requests/1/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "gallons_delivered": 40,
    "delivery_latitude": 31.9522,
    "delivery_longitude": 35.9332,
    "notes": "Urgent delivery completed"
  }'
```

### Step 9: Update Vehicle Inventory

```bash
curl -X PUT http://localhost:5051/api/v1/workers/vehicle/inventory \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"current_gallons": 30}'
```

### Step 10: Enable GPS Sharing

```bash
curl -X PUT http://localhost:5051/api/v1/workers/gps/toggle \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true}'
```

---

## Testing in Postman

### Collection: "Einhod - Worker Schedule"

1. **Login as Worker**
   - POST `{{base_url}}/auth/login`
   - Body: `{"username":"testworker","password":"Worker123!"}`

2. **Get Profile**
   - GET `{{base_url}}/workers/profile`

3. **Get Main Schedule**
   - GET `{{base_url}}/workers/schedule/main`

4. **Get Secondary List**
   - GET `{{base_url}}/workers/schedule/secondary`

5. **Start Delivery**
   - POST `{{base_url}}/workers/deliveries/11/start`

6. **Complete Delivery**
   - POST `{{base_url}}/workers/deliveries/11/complete`
   - Body:
     ```json
     {
       "gallons_delivered": 20,
       "delivery_latitude": 31.9522,
       "delivery_longitude": 35.9332,
       "notes": "Done"
     }
     ```

7. **Accept Request**
   - POST `{{base_url}}/workers/requests/1/accept`

8. **Complete Request**
   - POST `{{base_url}}/workers/requests/1/complete`
   - Body: Same as complete delivery

9. **Update Inventory**
   - PUT `{{base_url}}/workers/vehicle/inventory`
   - Body: `{"current_gallons": 100}`

10. **Toggle GPS**
    - PUT `{{base_url}}/workers/gps/toggle`
    - Body: `{"enabled": true}`

---

## Common Errors

### 404 - Delivery Not Found
```json
{
  "success": false,
  "message": "Delivery not found or not assigned to you"
}
```
**Solution:** Check delivery ID and ensure it's assigned to you.

### 400 - Wrong Status
```json
{
  "success": false,
  "message": "Delivery is not in pending status"
}
```
**Solution:** Can only start pending deliveries.

### 400 - Already Assigned
```json
{
  "success": false,
  "message": "Request is already assigned to another worker"
}
```
**Solution:** Another worker already accepted this request.

---

## Business Rules

1. **Main List:** Scheduled deliveries assigned by admin
2. **Secondary List:** On-demand requests sorted by priority
3. **Coupon Deduction:** Automatic when delivery completes (20 gallons = 1 coupon)
4. **Usage Tracking:** Updates client's monthly usage
5. **Notifications:** Auto-sent to clients on completion
6. **Inventory Alert:** System warns when vehicle <10 gallons
7. **GPS Privacy:** Workers control GPS sharing

---

## Testing Checklist

- [ ] Login as testworker
- [ ] Get worker profile - should show Ahmed Ali
- [ ] View main schedule - should show 3 deliveries
- [ ] View secondary list - should show urgent request
- [ ] Start a delivery - status changes to in_progress
- [ ] Complete delivery - should succeed
- [ ] Accept a request - should assign to you
- [ ] Complete request - should create delivery record
- [ ] Update vehicle inventory - should update
- [ ] Toggle GPS on - should enable
- [ ] Toggle GPS off - should disable

---

**Status:** ✅ COMPLETE AND READY TO TEST
**Endpoints:** 9 fully functional APIs
**Next Feature:** GPS Tracking or Payment Processing
