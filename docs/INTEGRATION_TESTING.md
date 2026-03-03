# Backend Integration Testing Guide

## 🎯 Overview

Test all 18 backend endpoints with proper authentication and localization.

## 🔧 Setup

### 1. Start Backend
```bash
cd /home/eito_new/Downloads/einhod-longterm
npm run dev
```

### 2. Get Access Token
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "owner",
    "password": "Admin123!"
  }'
```

Save the `accessToken` from response.

### 3. Set Environment Variable
```bash
export TOKEN="your_access_token_here"
```

## 📋 Endpoint Tests

### Worker Endpoints (8)

#### 1. Get Worker Profile
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/workers/profile
```
**Expected:** 200, worker profile data

#### 2. Update Worker Profile
```bash
curl -X PUT http://localhost:3000/api/v1/workers/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+1234567890"}'
```
**Expected:** 200, success message

#### 3. Get Shifts
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/workers/shifts
```
**Expected:** 200, shifts array

#### 4. Start Shift
```bash
curl -X POST http://localhost:3000/api/v1/workers/shifts/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expected:** 200, shift started

#### 5. Get Current Shift
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/workers/shifts/current
```
**Expected:** 200, current shift data

#### 6. End Shift
```bash
curl -X POST http://localhost:3000/api/v1/workers/shifts/end \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expected:** 200, shift ended

#### 7. Get Earnings
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/workers/earnings
```
**Expected:** 200, earnings summary

#### 8. Load Inventory
```bash
curl -X POST http://localhost:3000/api/v1/workers/inventory/load \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"gallons": 100}'
```
**Expected:** 200, inventory loaded

---

### Client Endpoints (3)

#### 9. Get Payment History
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/clients/payments
```
**Expected:** 200, payments array

#### 10. Request Dispenser
```bash
curl -X POST http://localhost:3000/api/v1/clients/dispensers/request \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notes": "Need new dispenser"}'
```
**Expected:** 200, request created

---

### Admin Endpoints (7)

#### 11. Approve Expense
```bash
curl -X PATCH http://localhost:3000/api/v1/admin/expenses/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "approve"}'
```
**Expected:** 200, expense approved

#### 12. Reject Expense
```bash
curl -X PATCH http://localhost:3000/api/v1/admin/expenses/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "reject", "reason": "Invalid receipt"}'
```
**Expected:** 200, expense rejected

#### 13. Revenue Report
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/admin/reports/revenue?start_date=2024-01-01&end_date=2024-12-31"
```
**Expected:** 200, revenue data

#### 14. Clients Report
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/admin/reports/clients
```
**Expected:** 200, clients statistics

#### 15. Workers Report
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/admin/reports/workers
```
**Expected:** 200, workers statistics

#### 16. Inventory Report
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/admin/reports/inventory
```
**Expected:** 200, inventory data

#### 17. Assign Dispenser
```bash
curl -X POST http://localhost:3000/api/v1/admin/dispensers/assign \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dispenser_id": 1, "client_id": 2}'
```
**Expected:** 200, dispenser assigned

#### 18. Unassign Dispenser
```bash
curl -X POST http://localhost:3000/api/v1/admin/dispensers/unassign \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dispenser_id": 1}'
```
**Expected:** 200, dispenser unassigned

---

## 🌍 Localization Tests

### Test English (Default)
```bash
curl -H "Authorization: Bearer $TOKEN" \
  -H "Accept-Language: en" \
  http://localhost:3000/api/v1/workers/profile
```

### Test Arabic
```bash
curl -H "Authorization: Bearer $TOKEN" \
  -H "Accept-Language: ar" \
  http://localhost:3000/api/v1/workers/profile
```

**Expected:** Error messages in respective languages

---

## 🧪 Error Scenario Tests

### 1. Invalid Token
```bash
curl -H "Authorization: Bearer invalid_token" \
  http://localhost:3000/api/v1/workers/profile
```
**Expected:** 401 Unauthorized

### 2. Missing Required Field
```bash
curl -X POST http://localhost:3000/api/v1/workers/inventory/load \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expected:** 400 Bad Request

### 3. Not Found
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/admin/expenses/99999
```
**Expected:** 404 Not Found

### 4. Capacity Exceeded
```bash
curl -X POST http://localhost:3000/api/v1/workers/inventory/load \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"gallons": 999999}'
```
**Expected:** 400 Bad Request, capacity error

---

## ✅ Testing Checklist

### Functional Tests
- [ ] All 18 endpoints return 200 on success
- [ ] All endpoints require authentication
- [ ] All endpoints return proper JSON
- [ ] All endpoints handle errors gracefully

### Localization Tests
- [ ] English responses work
- [ ] Arabic responses work
- [ ] Default to English if unsupported language

### Error Handling Tests
- [ ] 401 for invalid/missing token
- [ ] 400 for validation errors
- [ ] 404 for not found resources
- [ ] 500 for server errors (with proper logging)

### Data Validation Tests
- [ ] Required fields validated
- [ ] Data types validated
- [ ] Business logic validated (capacity, etc.)
- [ ] SQL injection prevented (parameterized queries)

---

## 📊 Expected Results Summary

| Endpoint | Method | Auth | Status | Response |
|----------|--------|------|--------|----------|
| /workers/profile | GET | ✅ | 200 | Profile data |
| /workers/profile | PUT | ✅ | 200 | Success message |
| /workers/shifts | GET | ✅ | 200 | Shifts array |
| /workers/shifts/start | POST | ✅ | 200 | Shift started |
| /workers/shifts/end | POST | ✅ | 200 | Shift ended |
| /workers/shifts/current | GET | ✅ | 200 | Current shift |
| /workers/earnings | GET | ✅ | 200 | Earnings data |
| /workers/inventory/load | POST | ✅ | 200 | Inventory loaded |
| /clients/payments | GET | ✅ | 200 | Payments array |
| /clients/dispensers/request | POST | ✅ | 200 | Request created |
| /admin/expenses/:id | PATCH | ✅ | 200 | Expense updated |
| /admin/reports/revenue | GET | ✅ | 200 | Revenue data |
| /admin/reports/clients | GET | ✅ | 200 | Clients stats |
| /admin/reports/workers | GET | ✅ | 200 | Workers stats |
| /admin/reports/inventory | GET | ✅ | 200 | Inventory data |
| /admin/dispensers/assign | POST | ✅ | 200 | Dispenser assigned |
| /admin/dispensers/unassign | POST | ✅ | 200 | Dispenser unassigned |

---

## 🚀 Automated Testing Script

```bash
#!/bin/bash
# Save as test_api.sh

BASE_URL="http://localhost:3000/api/v1"

# Login and get token
echo "🔐 Logging in..."
TOKEN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"owner","password":"Admin123!"}' \
  | jq -r '.data.accessToken')

echo "✅ Token: ${TOKEN:0:20}..."

# Test each endpoint
echo ""
echo "🧪 Testing Worker Endpoints..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/workers/profile | jq '.success'
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/workers/shifts | jq '.success'
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/workers/earnings | jq '.success'

echo ""
echo "🧪 Testing Client Endpoints..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/clients/payments | jq '.success'

echo ""
echo "🧪 Testing Admin Endpoints..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/admin/reports/revenue | jq '.success'
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/admin/reports/clients | jq '.success'
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/admin/reports/workers | jq '.success'
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/admin/reports/inventory | jq '.success'

echo ""
echo "✅ All tests complete!"
```

Run with:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

**All endpoints should return `"success": true`** ✅
