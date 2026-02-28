# Client Profile API Testing Guide

Complete guide to test all client profile management endpoints.

## Setup

1. **Start your server:**
```bash
cd /home/eito/Downloads/einhod-longterm/einhod-water-backend
npm run dev
```

2. **Seed test data:**
```bash
node scripts/seed-test-data.js
```

This creates:
- Test client: `testclient` / `Client123!`
- Test worker: `testworker` / `Worker123!`
- Sample deliveries, assets, and payment history

## Test Account

**Username:** `testclient`  
**Password:** `Client123!`  
**Role:** client

---

## API Endpoints

### 1. Login (Get Access Token)

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "username": "testclient",
  "password": "Client123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 2,
      "username": "testclient",
      "role": "client"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "..."
  }
}
```

**Copy the `accessToken`** - you'll need it for all other requests!

---

### 2. Get Client Profile

**Endpoint:** `GET /api/v1/clients/profile`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 2,
    "username": "testclient",
    "email": "client@test.com",
    "phone_number": "+1234567891",
    "profile_id": 1,
    "full_name": "John Doe",
    "address": "123 Main Street, City Center, Apartment 4B",
    "latitude": "31.95220000",
    "longitude": "35.93320000",
    "subscription_type": "coupon_book",
    "subscription_start_date": "2024-01-01",
    "subscription_end_date": "2024-12-31",
    "subscription_expiry_date": "2026-03-17",
    "remaining_coupons": 85,
    "monthly_usage_gallons": "450.50",
    "current_debt": "0.00",
    "subscription_status": "active"
  }
}
```

---

### 3. Update Profile

**Endpoint:** `PUT /api/v1/clients/profile`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json
```

**Request Body (all fields optional):**
```json
{
  "full_name": "John Smith",
  "address": "456 New Street, Downtown",
  "latitude": 31.9500,
  "longitude": 35.9400,
  "email": "newemail@test.com",
  "phone_number": "+1234567899",
  "preferred_language": "ar",
  "proximity_notifications_enabled": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user_id": 2,
    "username": "testclient",
    "email": "newemail@test.com",
    "phone_number": "+1234567899",
    "full_name": "John Smith",
    "address": "456 New Street, Downtown",
    "latitude": "31.95000000",
    "longitude": "35.94000000",
    "preferred_language": "ar",
    "proximity_notifications_enabled": false
  }
}
```

---

### 4. Get Subscription Details

**Endpoint:** `GET /api/v1/clients/subscription`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscription_type": "coupon_book",
    "subscription_start_date": "2024-01-01",
    "subscription_end_date": "2024-12-31",
    "subscription_expiry_date": "2026-03-17",
    "remaining_coupons": 85,
    "monthly_usage_gallons": "450.50",
    "current_debt": "0.00",
    "status": "active",
    "days_remaining": 30
  }
}
```

---

### 5. Get Usage History

**Endpoint:** `GET /api/v1/clients/usage?months=6`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Query Parameters:**
- `months` (optional): Number of months to look back (default: 6, max: 24)

**Response:**
```json
{
  "success": true,
  "data": {
    "monthly_usage": [
      {
        "month": "2026-02-01T00:00:00.000Z",
        "delivery_count": "3",
        "total_gallons": "60",
        "avg_gallons_per_delivery": "20.0000000000000000"
      },
      {
        "month": "2026-01-01T00:00:00.000Z",
        "delivery_count": "2",
        "total_gallons": "40",
        "avg_gallons_per_delivery": "20.0000000000000000"
      }
    ],
    "recent_deliveries": [
      {
        "id": 5,
        "delivery_date": "2026-02-08",
        "actual_delivery_time": "2026-02-08T10:00:00.000Z",
        "gallons_delivered": 20,
        "status": "completed",
        "worker_name": "Ahmed Ali"
      }
    ],
    "statistics": {
      "total_deliveries": "5",
      "total_gallons": "100",
      "avg_gallons": "20.0000000000000000",
      "last_delivery_date": "2026-02-08"
    }
  }
}
```

---

### 6. Get Assets

**Endpoint:** `GET /api/v1/clients/assets`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "asset_type": "dispenser",
      "quantity": 1,
      "assigned_date": "2024-01-15",
      "returned_date": null,
      "serial_number": "DSP-2024-001",
      "dispenser_type": "touch",
      "dispenser_status": "used",
      "image_url": null
    }
  ]
}
```

---

### 7. Get Debt Information

**Endpoint:** `GET /api/v1/clients/debt`

**Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "current_debt": 0,
    "subscription_type": "coupon_book",
    "recent_payments": [
      {
        "id": 1,
        "amount": "150.00",
        "payment_method": "cash",
        "payment_status": "completed",
        "payment_date": "2026-01-31T00:00:00.000Z",
        "description": "Subscription renewal"
      },
      {
        "id": 2,
        "amount": "200.00",
        "payment_method": "credit_card",
        "payment_status": "completed",
        "payment_date": "2026-01-01T00:00:00.000Z",
        "description": "Coupon book purchase"
      }
    ]
  }
}
```

---

## Testing with Postman

### Step-by-Step Guide

1. **Create a new Collection** in Postman called "Einhod Water - Client"

2. **Add Environment Variables:**
   - Click "Environments" → "Create Environment"
   - Name: "Einhod Local"
   - Variables:
     - `base_url` = `http://localhost:3000/api/v1`
     - `access_token` = (leave empty for now)

3. **Create Login Request:**
   - Method: POST
   - URL: `{{base_url}}/auth/login`
   - Body → raw → JSON:
     ```json
     {
       "username": "testclient",
       "password": "Client123!"
     }
     ```
   - Send it
   - **Copy the access token** from response

4. **Save Token to Environment:**
   - Go to Environments → Einhod Local
   - Set `access_token` to the token you copied

5. **Create Profile Request:**
   - Method: GET
   - URL: `{{base_url}}/clients/profile`
   - Headers:
     - Key: `Authorization`
     - Value: `Bearer {{access_token}}`
   - Send it!

6. **Repeat for all other endpoints**

---

## Testing with cURL

### Get Profile
```bash
curl -X GET http://localhost:3000/api/v1/clients/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Update Profile
```bash
curl -X PUT http://localhost:3000/api/v1/clients/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Updated Name",
    "address": "New Address"
  }'
```

### Get Usage History
```bash
curl -X GET "http://localhost:3000/api/v1/clients/usage?months=3" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Common Errors

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Access token required"
}
```
**Solution:** Add Authorization header with Bearer token

### 403 Forbidden
```json
{
  "success": false,
  "message": "You do not have permission to access this resource"
}
```
**Solution:** Make sure you're logged in as a client user

### 400 Validation Error
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "latitude",
      "message": "Latitude must be between -90 and 90"
    }
  ]
}
```
**Solution:** Fix the invalid field value

---

## Next Steps

✅ Client Profile Management (COMPLETE)

**What to build next:**
- 📝 Delivery Request System
- 📝 Worker Schedule Management
- 📝 GPS Tracking
- 📝 Payment Processing

Choose your next feature and I'll build it for you!

---

**Built by:** Einhod Pure Water Development Team  
**Date:** February 15, 2026
