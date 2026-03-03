# 🧪 Comprehensive Test Scenarios for Einhod Pure Water Management System

This document outlines a detailed suite of test scenarios designed to thoroughly verify the functionality, security, performance, and user experience of the Einhod Pure Water Management System. It covers both the Flutter frontend and the Node.js backend, including database interactions and crucial edge cases.

---

## 1. User Authentication and Authorization Test Scenarios

These scenarios focus on login, registration, role-based access, and security features across all user roles (owner, administrator, delivery_worker, onsite_worker, client).

*   **Standard Login Flow**: A client user enters valid credentials (username/password) via the Flutter app. Verify JWT token issuance, role embedding ('client' in roles array), and redirection to /client/home. Check haptic feedback on successful login and confetti animation for first-time login celebration.

*   **Multi-Role Login**: An owner with multiple roles (owner, administrator) logs in. Ensure the frontend router prioritizes the highest role (owner) and redirects to /admin/home, while backend `authorizeRoles` allows access to both admin and owner endpoints.

*   **Invalid Credentials**: Attempt login with incorrect password. Expect 401 Unauthorized response, error notification with shimmer effect on login screen, and rate-limiting after 5 failed attempts (`express-rate-limit` triggers 429 Too Many Requests).

*   **Password Reset via Verification Code**: User requests password reset; backend generates 6-digit code (in-memory Map), logs it (`winston info`), and simulates SMS. User enters code and new password. Test expiry (e.g., code invalid after 5 minutes) and `bcrypt` hashing of new password.

*   **JWT Refresh**: With a valid refresh token, request new access token. Simulate token expiry and auto-refresh via `AuthService` in Flutter. Edge case: Revoke refresh token (in-memory Set deletion) and ensure 401 on refresh attempt.

*   **Role-Based Access Denial**: A `delivery_worker` attempts to access admin-only endpoint (e.g., `/admin/users`). Backend middleware rejects with 403 Forbidden. Frontend attempts navigation to `/admin/home`; router redirects back to `/worker/home` with error toast.

*   **Creative Scenario: Role Escalation Attempt**: A client uses developer tools to tamper with JWT roles array in local storage. Backend verifies JWT signature and rejects tampered token (401). Add glassmorphism overlay warning in app: "Security breach detected – logging out."

*   **Session Persistence**: Login on mobile, close app, reopen. `Shared_preferences` restores session; verify `geolocator` access for client location if `gps_sharing_enabled`.

*   **Bilingual Login**: Switch to Arabic locale; ensure RTL layout, translated error messages (e.g., "كلمة المرور غير صحيحة"), and correct input validation for Arabic characters.

---

## 2. Client Profile and Subscription Management Test Scenarios

Focus on client-specific features like profile updates, coupon books, and subscriptions.

*   **Profile Creation and Update**: New client registers; backend inserts into `users` and `client_profiles` tables transactionally. Update address with geocode:lat,long; verify PostGIS `GEOGRAPHY(POINT,4326)` storage and frontend map integration via `geocoding`.

*   **Subscription Purchase**: Client buys a coupon book (e.g., size=10, price=50, bonus_gallons=2). Test payment transaction insert into `payments` table, update `remaining_coupons`, and notification send via `notification.service.js`.

*   **Coupon Redemption**: During delivery, redeem coupons; update `client_profiles.remaining_coupons` atomically. Edge case: Attempt redemption with 0 coupons; expect 400 Bad Request and AI-powered suggestion for repurchase via `AIPredictionService`.

*   **Debt Management**: Accumulate `current_debt` over deliveries without payment. Admin views analytics dashboard; verify `fl_chart` rendering of debt trends. Client pays via `payment_method='cash'`; reset debt.

*   **Creative Scenario: Predictive Subscription Renewal**: Using past deliveries data, AI predicts next renewal (`SmartDeliverySuggestion`). Test with mocked data: If usage high, suggest upsell; trigger confetti on auto-renewal acceptance.

*   **Localization Edge Case**: Arabic client updates `full_name` with diacritics; ensure PostgreSQL utf8 handling and Flutter display without distortion.

---

## 3. Delivery Request and Tracking Test Scenarios

Cover end-to-end delivery workflows, including requests, assignments, tracking, and completions.

*   **Request Creation**: Client submits `delivery_requests` with `priority='high'`, `requested_gallons=20`. Backend validates via `express-validator`, assigns to nearest `delivery_worker` using PostGIS `ST_Distance` query.

*   **Worker Assignment and Scheduling**: Admin assigns via `scheduled_deliveries`. Test `node-cron` job for daily schedule generation; verify `worker_profiles.vehicle_current_gallons` update.

*   **Real-Time GPS Tracking**: `Delivery_worker` enables `gps_sharing_enabled`; app polls `geolocator` and updates `worker_locations` table. Client views live map; simulate movement with mocked coordinates.

*   **Delivery Completion**: Worker marks delivery complete, inputs `gallons_delivered` and `empty_gallons_returned`. Transaction: Update `deliveries` table, `client_profiles.remaining_coupons/debt`, and send notification. Frontend: Liquid loading animation during submit, followed by confetti.

*   **State Machine Enforcement**: Attempt invalid status transition (e.g., from 'pending' to 'completed' without 'in_progress'). `state-machine.js` rejects; log warn via `winston`.

*   **Edge Case: Failed Delivery**: Worker reports issue (e.g., no access); `status='failed'`. Trigger admin notification and client reschedule suggestion via AI.

*   **Creative Scenario: Multi-Delivery Route Optimization**: For multiple requests, use PostGIS to calculate optimal route (e.g., nearest neighbor). Simulate with 5 clients; verify reduced total distance and worker expense tracking.

*   **Offline Handling**: Client submits request offline; `dio` retries on reconnect. Verify `shared_preferences` caching and sync on online.

---

## 4. Worker Management and Operations Test Scenarios

Scenarios for `delivery_workers` and `onsite_workers`, including shifts, expenses, and leaves.

*   **Shift Scheduling**: Admin creates shifts via `schedule.controller.js`. Worker views in `/worker/home`; accept/reject with haptic feedback.

*   **Expense Submission**: Worker submits expense (e.g., fuel) with `expense_payment_method='credit'`. Backend inserts into `worker_expenses`, admin approves/rejects. Test status ENUM transitions.

*   **Leave Request**: Worker requests leave; admin approves. `node-cron` adjusts schedules automatically, reassigning deliveries.

*   **Vehicle Inventory Update**: `Delivery_worker` refills at `filling_stations`; update `vehicle_current_gallons` transactionally. Edge case: Overfill attempt; validate against max capacity.

*   **Creative Scenario: Gamified Worker Performance**: Track deliveries completed; if streak >5, trigger confetti and bonus notification. Use `fl_chart` for personal dashboard showing efficiency metrics.

*   **Onsite Worker Specific**: Manage `dispensers` table; update `dispenser_status='empty'`. Test integration with `station_status` for refill alerts.

---

## 5. Admin and Owner Oversight Test Scenarios

Administrative features like analytics, user management, and system configurations.

*   **User Management**: Admin creates new `delivery_worker`; transactionally insert `users` and `worker_profiles`. Deactivate user (`is_active=false`); ensure no login possible.

*   **Analytics Dashboard**: Load data from multiple tables (`deliveries`, `payments`); render `fl_chart` graphs. Test filters: By date range, role, or geocode.

*   **Coupon Size Configuration**: Owner updates `coupon_sizes`; verify propagation to client subscription options.

*   **Notification Broadcast**: Admin sends broadcast via `notification.routes.js`; all clients receive via `flutter_local_notifications`.

*   **Edge Case: Data Export**: Admin exports CSV of deliveries; use `pg` query to fetch, `axios` to send (if integrated). Verify Arabic character encoding.

*   **Creative Scenario: AI-Driven Insights**: Analyze usage patterns; predict shortages (e.g., low `vehicle_gallons` across workers). Dashboard shows predictive alerts with shimmer loading.

---

## 6. System-Wide Integration and Performance Test Scenarios

Cross-feature, security, and non-functional tests.

*   **End-to-End Bilingual Flow**: Entire delivery cycle in Arabic: Request, track, complete. Verify RTL, translations, and PostGIS handling of Arabic addresses.

*   **Security: SQL Injection Attempt**: Send malicious input (e.g., `' OR 1=1 --`) in username. `pg` parameterized queries reject; log error.

*   **Rate Limiting and DDoS Simulation**: Flood login endpoint; `express-rate-limit` blocks after threshold. Test behind proxy (`trust proxy` enabled).

*   **Transaction Atomicity**: Simulate DB failure mid-transaction (e.g., delivery completion); ensure rollback via `pg` transaction.

*   **Performance: High Load**: Simulate 100 concurrent delivery requests; monitor PostgreSQL pool exhaustion and `node-cron` delays.

*   **Creative Scenario: Disaster Recovery Simulation**: Worker loses GPS signal; fallback to last known location. Admin overrides with manual entry; trigger haptic alert for worker.

*   **Accessibility Testing**: Ensure glassmorphism elements have sufficient contrast; test screen reader compatibility for notifications.

*   **Mobile-Web Consistency**: Test same flow on Android APK vs. web; verify responsive design and `cached_network_image` loading.

---

## 7. Edge and Error Handling Test Scenarios

Uncommon or failure-prone situations.

*   **Network Failure**: API call fails (`dio` timeout); app shows skeleton shimmer and retry button.

*   **Invalid Geolocation**: Client enters impossible lat/long (e.g., 999); `geocoding` rejects, frontend error with animation.

*   **Concurrent Updates**: Two admins update same client debt; use PostgreSQL row locking to prevent race conditions.

*   **Data Migration**: Seed DB with `npm run db:seed`; verify all ENUMs and PostGIS extensions.

*   **Creative Scenario: Time Travel Testing**: Use `node-cron` to simulate future dates; test expiry of subscriptions, JWTs, and verification codes.

*   **Zero-Data State**: New install; admin dashboard shows empty states with motivational animations (e.g., water droplet filling up).
