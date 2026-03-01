# Deep Comprehensive Business Logic Test Scenarios - Einhod Water

This document outlines advanced test scenarios for the Einhod Water application, focusing on edge cases, race conditions, and strict business rule enforcement.

## 1. Subscription & Credit Management

### Scenario 1.1: Cash Subscription Credit Limit "Hard Stop"
- **Context**: Cash clients have a configurable debt limit (default: ₪10,000).
- **Setup**: 
    - Set a client's `subscription_type` to `cash`.
    - Set `current_debt` to ₪9,950.
    - Set `system_config.debt_limit_ils` to 10,000.
- **Action**: Client attempts to place a delivery request for 100 gallons.
- **Expectation**: Request rejected with status `403 Forbidden` and message "Credit limit reached".
- **Action**: Client records a payment of ₪500.
- **Expectation**: `current_debt` becomes ₪9,450.
- **Action**: Client attempts the same delivery request again.
- **Expectation**: Request accepted (status `201 Created`).

### Scenario 1.2: Cash Subscription Grace Period
- **Context**: Cash subscriptions have a grace period (default: 10 days) after the `subscription_expiry_date`.
- **Setup**:
    - Set `subscription_type` to `cash`.
    - Set `subscription_expiry_date` to 5 days ago.
- **Action**: Client attempts to place a delivery request.
- **Expectation**: Request accepted (within grace period).
- **Setup**:
    - Set `subscription_expiry_date` to 15 days ago.
- **Action**: Client attempts to place a delivery request.
- **Expectation**: Request rejected with status `403 Forbidden` and message "Your subscription has expired".

### Scenario 1.3: Coupon Book Bonus & Exhaustion
- **Context**: Purchasing large coupon books gives bonus gallons.
- **Setup**:
    - Client purchases 500-gallon book (bonus: 50 gallons).
    - Verify `remaining_coupons` = 500, `bonus_gallons` = 50.
- **Action**: Complete a delivery of 520 gallons.
- **Expectation**: 
    - `remaining_coupons` becomes 0.
    - `bonus_gallons` becomes 30.
    - `current_debt` remains 0.
- **Action**: Complete another delivery of 40 gallons.
- **Expectation**: 
    - `remaining_coupons` remains 0.
    - `bonus_gallons` becomes 0.
    - Request rejected or debt increased? (Need to verify: Coupon clients usually can't have debt).
    - *Code Check*: `delivery.controller.js` suggests coupon clients MUST use coupons. If they have 0 coupons/bonus, they should be blocked.

## 2. Delivery Lifecycle & Inventory

### Scenario 2.1: Worker Vehicle Inventory Lock
- **Context**: Workers cannot deliver more than they have in their vehicle.
- **Setup**:
    - Worker A has `vehicle_current_gallons` = 100.
    - Delivery request for 150 gallons is assigned to Worker A.
- **Action**: Worker A attempts to "complete" the delivery with 150 gallons.
- **Expectation**: Rejected with status `400 Bad Request` or custom error "Insufficient inventory".
- **Action**: Worker A updates inventory to 500 gallons (refill).
- **Action**: Worker A attempts to "complete" again.
- **Expectation**: Success. `vehicle_current_gallons` becomes 350.

### Scenario 2.2: Concurrent Delivery Acceptance (Race Condition)
- **Context**: Multiple workers might try to accept the same "pending" delivery.
- **Setup**:
    - Delivery request ID 100 is "pending".
    - Worker A and Worker B both send `acceptDelivery` requests simultaneously.
- **Expectation**: 
    - One worker succeeds (status `200`).
    - The other worker fails with status `400` and message "Delivery request is already assigned".

### Scenario 2.3: Delivery Cancellation Mid-Progress
- **Context**: A client cancels a delivery that a worker has already started.
- **Setup**:
    - Delivery is "in_progress" (assigned to Worker A).
- **Action**: Client cancels the delivery.
- **Action**: Worker A attempts to "complete" the delivery.
- **Expectation**: Rejected because the delivery is no longer "in_progress".

## 3. Worker Logistics

### Scenario 3.1: Vehicle Capacity Constraint
- **Context**: `vehicle_current_gallons` cannot exceed `vehicle_capacity`.
- **Setup**:
    - Worker A has `vehicle_capacity` = 1000.
- **Action**: Worker A (or Admin) attempts to set `vehicle_current_gallons` to 1200.
- **Expectation**: Rejected by database constraint or API validation.

### Scenario 3.2: Empty Gallons Logic
- **Context**: Clients return empty containers, which should be tracked.
- **Setup**:
    - Client has `gallons_on_hand` = 100 (from previous deliveries).
- **Action**: Worker completes 50-gallon delivery, client returns 20 empty gallons.
- **Expectation**: 
    - `gallons_on_hand` = 100 + 50 - 20 = 130.
    - Verify `empty_gallons_returned` is logged in the delivery record.

## 4. Security & Multi-Device

### Scenario 4.1: Token Blacklisting on Logout
- **Action**: User logs in (Token A), then logs out.
- **Expectation**: Token A is blacklisted and cannot be used for any subsequent requests.

### Scenario 4.2: Role Isolation
- **Action**: Worker attempts to access `/api/v1/admin/dashboard`.
- **Expectation**: Status `403 Forbidden`.
- **Action**: Client attempts to access `/api/v1/workers/deliveries`.
- **Expectation**: Status `403 Forbidden`.
