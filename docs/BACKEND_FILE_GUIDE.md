# Backend File Structure Guide

Complete explanation of every file in the Node.js backend.

---

## 📂 Root Files

### `package.json`
- Defines project dependencies (Express, PostgreSQL, JWT, bcrypt, etc.)
- Contains npm scripts: `start`, `dev`, `test`, `db:setup`, `db:seed`
- Specifies Node.js version requirements (>=18.0.0)

### `.env`
- Environment variables (DATABASE_URL, JWT_SECRET, PORT, etc.)
- **Never commit this file** - contains sensitive credentials

### `.env.example`
- Template for environment variables
- Safe to commit - shows required variables without actual values

### `jest.config.js`
- Jest testing framework configuration
- Sets up test environment and coverage reporting

---

## 📂 src/

### `server.js` - **Entry Point**
- Initializes Express app
- Configures middleware (CORS, helmet, rate limiting)
- Registers all routes
- Starts HTTP server
- Handles graceful shutdown

---

## 📂 src/config/

### `database.js`
- PostgreSQL connection pool setup
- Database configuration from environment variables
- Connection error handling
- Exports `pool` for queries throughout the app

---

## 📂 src/middleware/

### `auth.middleware.js`
- **JWT token verification** - validates tokens from Authorization header
- **Role-based access control** - checks if user has required role(s)
- Attaches `req.user` with decoded token data (userId, role)

### `validation.middleware.js`
- Express-validator integration
- Validates and sanitizes request data
- Returns 400 errors for invalid input

---

## 📂 src/utils/

### `logger.js`
- Winston logger configuration
- Logs to console and files (combined.log, error.log)
- Different log levels (info, warn, error)

### `roles.js`
- Defines user roles: Owner, Administrator, Delivery Worker, Onsite Worker, Client
- Role hierarchy and permissions
- Helper functions for role checking

### `i18n.js`
- Internationalization (Arabic/English)
- Translates notification messages
- Language detection from request headers

### `state-machine.js`
- Delivery request state transitions
- Valid states: pending → assigned → in_progress → completed/cancelled
- Prevents invalid state changes

---

## 📂 src/routes/

Routes define API endpoints and connect them to controllers.

### `auth.routes.js`
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT token
- `GET /api/auth/profile` - Get current user profile
- `PUT /api/auth/profile` - Update profile

### `admin.routes.js`
- **User Management**: CRUD operations for all users
- **Dashboard Stats**: Revenue, deliveries, clients, workers
- **Inventory**: Manage gallons stock, coupon books
- **Expenses**: Track worker expenses
- **Reports**: Financial and operational reports
- **Settings**: System configuration

### `client.routes.js`
- `GET /api/clients/profile` - Get client profile
- `PUT /api/clients/profile` - Update profile
- `GET /api/clients/deliveries` - Delivery history
- `GET /api/clients/balance` - Account balance and gallons
- `POST /api/clients/delivery-request` - Request water delivery

### `worker.routes.js`
- `GET /api/workers/profile` - Worker profile
- `GET /api/workers/schedule` - Today's delivery schedule
- `GET /api/workers/deliveries` - Assigned deliveries
- `PUT /api/workers/deliveries/:id/status` - Update delivery status
- `POST /api/workers/location` - Update GPS location
- `GET /api/workers/stats` - Performance statistics
- `POST /api/workers/expenses` - Submit expense claims

### `delivery.routes.js`
- `POST /api/deliveries` - Create delivery request
- `GET /api/deliveries/:id` - Get delivery details
- `PUT /api/deliveries/:id` - Update delivery
- `DELETE /api/deliveries/:id` - Cancel delivery
- `PUT /api/deliveries/:id/assign` - Assign to worker
- `PUT /api/deliveries/:id/complete` - Mark completed

### `schedule.routes.js`
- `GET /api/schedules` - Get scheduled deliveries
- `POST /api/schedules` - Create recurring schedule
- `PUT /api/schedules/:id` - Update schedule
- `DELETE /api/schedules/:id` - Delete schedule

### `shifts.routes.js`
- `GET /api/shifts` - Get worker shifts
- `POST /api/shifts` - Create shift
- `PUT /api/shifts/:id` - Update shift
- `DELETE /api/shifts/:id` - Delete shift

### `location.routes.js`
- `POST /api/location/update` - Update worker GPS location
- `GET /api/location/workers` - Get all worker locations
- `GET /api/location/worker/:id` - Get specific worker location

### `payment.routes.js`
- `POST /api/payments` - Record payment
- `GET /api/payments/:id` - Get payment details
- `GET /api/payments/client/:clientId` - Client payment history

### `coupon-sizes.routes.js`
- `GET /api/coupon-sizes` - List coupon book sizes
- `POST /api/coupon-sizes` - Create coupon size
- `PUT /api/coupon-sizes/:id` - Update coupon size
- `DELETE /api/coupon-sizes/:id` - Delete coupon size

### `notifications.routes.js` & `notification.routes.js`
- `GET /api/notifications` - Get user notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `DELETE /api/notifications/:id` - Delete notification

### `gps.routes.js`
- GPS tracking endpoints (legacy, merged into location.routes.js)

---

## 📂 src/controllers/

Controllers contain business logic for each route.

### `auth.controller.js`
**What it does:**
- User registration with password hashing (bcrypt)
- Login with JWT token generation
- Profile retrieval and updates
- Password validation

**Key functions:**
- `register()` - Creates new user, hashes password
- `login()` - Validates credentials, returns JWT
- `getProfile()` - Returns user data
- `updateProfile()` - Updates user info

### `admin.controller.js` (Largest file - 100KB)
**What it does:**
- Complete admin dashboard functionality
- User management (CRUD for all roles)
- Inventory management (gallons, coupons)
- Financial reports and analytics
- System-wide statistics

**Key functions:**
- `getDashboardStats()` - Overview metrics
- `getUsers()`, `createUser()`, `updateUser()`, `deleteUser()`
- `getInventory()`, `updateInventory()`
- `getRevenue()`, `getExpenses()`
- `getDeliveryReports()`
- `manageWorkerShifts()`

### `client.controller.js`
**What it does:**
- Client profile management
- Delivery request creation
- Balance and gallon tracking
- Payment history

**Key functions:**
- `getProfile()` - Client details with balance
- `createDeliveryRequest()` - Request water delivery
- `getDeliveries()` - Delivery history
- `getBalance()` - Account balance and gallons on hand

### `worker.controller.js` (46KB)
**What it does:**
- Worker daily operations
- Delivery assignment and completion
- GPS location tracking
- Performance statistics
- Expense submission

**Key functions:**
- `getSchedule()` - Today's assigned deliveries
- `updateDeliveryStatus()` - Change delivery state
- `completeDelivery()` - Mark delivery done, update inventory
- `submitExpense()` - Submit expense claim
- `getStats()` - Worker performance metrics

### `delivery.controller.js`
**What it does:**
- Delivery lifecycle management
- State transitions (pending → assigned → in_progress → completed)
- Worker assignment
- Inventory updates on completion

**Key functions:**
- `createDelivery()` - Create new delivery request
- `assignDelivery()` - Assign to worker
- `updateStatus()` - Change delivery state
- `completeDelivery()` - Finalize delivery, update client balance

### `schedule.controller.js`
**What it does:**
- Recurring delivery schedules
- Auto-generation of scheduled deliveries
- Schedule management (daily, weekly, monthly)

**Key functions:**
- `createSchedule()` - Set up recurring delivery
- `getSchedules()` - List all schedules
- `generateScheduledDeliveries()` - Create deliveries from schedules

### `shifts.controller.js`
**What it does:**
- Worker shift management
- Shift scheduling and tracking
- Leave management

**Key functions:**
- `createShift()` - Schedule worker shift
- `getShifts()` - Get shifts by date/worker
- `updateShift()` - Modify shift
- `deleteShift()` - Remove shift

### `location.controller.js`
**What it does:**
- Real-time GPS tracking
- Worker location updates
- Location history

**Key functions:**
- `updateLocation()` - Store worker GPS coordinates
- `getWorkerLocation()` - Get current location
- `getAllWorkerLocations()` - Map view of all workers

### `payment.controller.js`
**What it does:**
- Payment recording
- Payment method tracking (cash, coupon, credit)
- Payment history

**Key functions:**
- `recordPayment()` - Log payment transaction
- `getPaymentHistory()` - Client payment records

### `revenue.controller.js`
**What it does:**
- Revenue calculations
- Financial reporting
- Profit/loss analysis

**Key functions:**
- `getRevenue()` - Calculate total revenue
- `getRevenueByPeriod()` - Daily/weekly/monthly revenue

### `coupon-sizes.controller.js`
**What it does:**
- Coupon book configuration
- Pricing and gallon amounts
- Stock management

**Key functions:**
- `getCouponSizes()` - List available sizes
- `createCouponSize()` - Add new size
- `updateCouponSize()` - Modify size/price

### `notifications.controller.js`
**What it does:**
- Notification delivery
- Read/unread status
- Notification history

**Key functions:**
- `getNotifications()` - User notifications
- `markAsRead()` - Update read status
- `deleteNotification()` - Remove notification

---

## 📂 src/services/

Background services and shared functionality.

### `notification.service.js`
**What it does:**
- Creates notifications for users
- Sends notifications on events (delivery assigned, completed, etc.)
- Multi-language support

**Key functions:**
- `createNotification()` - Insert notification into database
- `notifyUser()` - Send notification to specific user

### `cron.service.js`
**What it does:**
- Scheduled background tasks
- Auto-generates scheduled deliveries
- Cleanup old data

**Key functions:**
- `startCronJobs()` - Initialize scheduled tasks
- Runs daily to create deliveries from schedules

---

## 📂 src/__tests__/

### `auth.test.js`
- Unit tests for authentication
- Tests registration, login, JWT validation
- Uses Jest and Supertest

---

## 📂 database/

### `schema.sql`
- Complete database schema with PostGIS
- All tables: users, clients, deliveries, schedules, etc.
- Indexes and constraints

### `schema-no-postgis.sql`
- Schema without PostGIS extension
- For databases that don't support PostGIS

---

## 📂 migrations/

SQL migration files for database changes:

- `add_work_shifts_and_leaves.sql` - Shift management tables
- `add_coupon_book_size.sql` - Coupon size field
- `add_scheduled_deliveries.sql` - Recurring delivery system
- `add_location_tracking.sql` - GPS tracking tables
- `add_worker_expenses.sql` - Expense tracking
- `create_notifications_system.sql` - Notification tables
- `fix_all_logical_issues.sql` - Bug fixes for business logic

---

## 📂 scripts/

Utility scripts for database operations:

### `seed_test_data.js`
- Populates database with test data
- Creates sample users, clients, deliveries

### `seed_historical_data.js`
- Generates historical data for testing reports

### `verify_gallons_on_hand.js`
- Validates gallon inventory calculations

### `business_logic_*.js`
- Test scenarios for complex business logic

---

## 🔄 Request Flow Example

**Client requests water delivery:**

1. **Client App** → `POST /api/deliveries`
2. **Route** (`delivery.routes.js`) → validates auth token
3. **Middleware** (`auth.middleware.js`) → verifies JWT, checks role
4. **Controller** (`delivery.controller.js`) → `createDelivery()`
5. **Database** → INSERT into deliveries table
6. **Service** (`notification.service.js`) → notify admins
7. **Response** → Return delivery ID to client

**Admin assigns delivery to worker:**

1. **Admin App** → `PUT /api/deliveries/:id/assign`
2. **Route** → validates admin role
3. **Controller** → `assignDelivery()`
4. **Database** → UPDATE delivery, set worker_id
5. **Service** → notify worker
6. **Response** → Success

**Worker completes delivery:**

1. **Worker App** → `PUT /api/deliveries/:id/complete`
2. **Controller** → `completeDelivery()`
3. **Database** → 
   - UPDATE delivery status = 'completed'
   - UPDATE client gallons_on_hand
   - UPDATE worker stats
4. **Service** → notify client
5. **Response** → Success

---

## 🔐 Security Features

- **JWT Authentication** - All routes protected except login/register
- **Password Hashing** - bcrypt with salt rounds
- **Role-Based Access** - Middleware checks user permissions
- **Rate Limiting** - Prevents brute force attacks
- **Input Validation** - Sanitizes all user input
- **SQL Injection Protection** - Parameterized queries
- **CORS** - Configured for frontend domain only

---

## 📊 Database Tables

**Core Tables:**
- `users` - All system users (admins, workers, clients)
- `clients` - Client-specific data (balance, gallons)
- `deliveries` - Delivery requests and history
- `scheduled_deliveries` - Recurring delivery schedules
- `work_shifts` - Worker shift schedules
- `worker_expenses` - Expense claims
- `coupon_sizes` - Coupon book configurations
- `notifications` - User notifications
- `location_tracking` - GPS coordinates history

---

## 🚀 Key Business Logic

### Gallon Tracking
- Client has `gallons_on_hand` (current balance)
- Delivery adds gallons when completed
- System tracks reserved gallons for pending deliveries

### Payment Methods
- **Cash** - Direct payment
- **Coupon** - Pre-paid coupon books
- **Credit** - Pay later (tracked in balance)

### Delivery States
```
pending → assigned → in_progress → completed
                                 → cancelled
```

### Scheduled Deliveries
- Cron job runs daily
- Generates deliveries from schedules
- Supports daily, weekly, monthly frequencies

---

## 📝 Environment Variables

Required in `.env`:

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=your-secret-key
PORT=3000
NODE_ENV=production
FRONTEND_URL=https://your-app.com
```

---

## 🧪 Testing

Run tests:
```bash
npm test                    # All tests
npm test -- auth.test.js    # Specific test
./run-auth-tests.sh         # Auth tests only
```

---

## 📦 Main Dependencies

- **express** - Web framework
- **pg** - PostgreSQL client
- **jsonwebtoken** - JWT authentication
- **bcrypt** - Password hashing
- **cors** - Cross-origin requests
- **helmet** - Security headers
- **winston** - Logging
- **express-validator** - Input validation
- **node-cron** - Scheduled tasks

---

## 🎯 Summary

**Entry Point:** `src/server.js`
**Database:** `src/config/database.js`
**Auth:** `src/middleware/auth.middleware.js`
**Routes:** `src/routes/*.routes.js` (define endpoints)
**Controllers:** `src/controllers/*.controller.js` (business logic)
**Services:** `src/services/*.service.js` (background tasks)
**Utils:** `src/utils/*.js` (helpers)

The backend follows **MVC pattern**:
- **Routes** define endpoints
- **Controllers** handle business logic
- **Database** is the model layer
- Middleware handles cross-cutting concerns (auth, validation)
