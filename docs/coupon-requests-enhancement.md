# Coupon Requests Enhancement - Changes Summary

## Date: 2026-03-01

Coupon book requests now display like water delivery requests with worker assignment and client grouping.

## Database Changes

### Migration File Created
- `migrations/add_worker_to_coupon_requests.sql` - Adds worker assignment to coupon requests

### Schema Changes
1. **coupon_book_requests table**: 
   - Added `assigned_worker_id` column (references worker_profiles)
   - Added index on `assigned_worker_id`
   - Updated status enum to include 'assigned'

## Backend Changes (Node.js)

### Controllers Modified

**admin.controller.js:**
- `getAllCouponBookRequests()` - Enhanced query to include:
  - `assigned_worker_id`
  - `client_id`, `client_phone`
  - `home_latitude`, `home_longitude`
  - `worker_name` (from LEFT JOIN)
- `assignCouponBookWorker()` - NEW function to assign worker to coupon request
- Exported `assignCouponBookWorker` in module.exports

### Routes Added

**admin.routes.js:**
- `PATCH /api/v1/admin/coupon-book-requests/:id/assign` - Assign worker to coupon request
  - Validates `worker_id` as integer
  - Updates status to 'assigned'

## Frontend Changes (Flutter)

### Screens Modified

**admin_requests_screen.dart:**
- Completely rebuilt coupon requests view with:
  - **Client Grouping**: Groups multiple coupon requests by client_id
  - **Assign Worker Button**: Shows for unassigned requests
  - **Worker Assignment Dialog**: Lists available delivery workers
  - **Assigned Status Display**: Shows assigned worker name
  - Individual request items within each client group
  - Phone icon for client contact

### Services Modified

**admin_service.dart:**
- Added `assignCouponBookWorker(int requestId, int workerId)` method

### Providers Added

**users_provider.dart:**
- Added `availableWorkersProvider` - Fetches active delivery workers for assignment

## UI Features

### Coupon Request Display
- Grouped by client (like water requests)
- Shows client name, address, phone
- Lists all coupon requests for that client
- Each request shows: book size, type (physical/electronic), status, price
- Color-coded status indicators

### Worker Assignment
- "Assign Worker" button appears for unassigned requests
- Dialog shows list of available delivery workers
- Assigns worker to all requests from that client
- Shows green confirmation when worker is assigned

### Status Flow
1. `pending` → Initial state (orange)
2. `approved` → Auto-approved (green)
3. `assigned` → Worker assigned (green)
4. `completed` → Delivered (blue)
5. `cancelled` → Cancelled (gray)

## Migration Steps

To apply these changes to production:

1. Run the migration SQL:
   ```bash
   psql $DATABASE_URL -f migrations/add_worker_to_coupon_requests.sql
   ```

2. Deploy backend changes

3. Rebuild and deploy Flutter APK

## Testing Required

1. ✅ View coupon requests grouped by client
2. ✅ Assign worker to coupon requests
3. ✅ View assigned worker name
4. ✅ Multiple requests from same client grouped together
5. ✅ Worker assignment updates status to 'assigned'
