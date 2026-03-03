# 📘 EINHOD PURE WATER - COMPLETE PROJECT DOCUMENTATION

**Project Name:** Einhod Pure Water Delivery Management System  
**Version:** 1.0.0  
**Last Updated:** 2026-02-28  
**Status:** ✅ Production Ready (93% Security Tested)

---

## 📋 TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Database Schema](#4-database-schema)
5. [API Endpoints](#5-api-endpoints)
6. [Security Features](#6-security-features)
7. [Business Logic](#7-business-logic)
8. [Testing & Quality Assurance](#8-testing--quality-assurance)
9. [Deployment Guide](#9-deployment-guide)
10. [Known Issues & Roadmap](#10-known-issues--roadmap)

---

## 1. PROJECT OVERVIEW

### 1.1 Purpose

Einhod Pure Water is a comprehensive water delivery management system designed for a water distribution company operating in Israel. The system manages the complete lifecycle of water delivery operations including:

- Customer subscription management (coupon-based and cash)
- Real-time delivery tracking with GPS
- Worker schedule and inventory management
- Payment processing and debt tracking
- Dispenser rental and maintenance
- Business analytics and reporting

### 1.2 Target Users

The system serves **5 distinct user roles**:

1. **Client** - Water delivery customers
   - Request deliveries
   - Track orders in real-time
   - Manage subscriptions and payments
   - View delivery history

2. **Delivery Worker** - Field workers delivering water
   - View assigned deliveries
   - Update delivery status with GPS and photos
   - Manage vehicle inventory
   - Track earnings and advances

3. **On-Site Worker** - Station-based workers
   - Manage dispenser inventory
   - Process coupon book sales
   - Handle customer walk-ins
   - Track station operations

4. **Administrator** - Office staff
   - Manage users and profiles
   - Approve expenses
   - Generate reports
   - Handle customer support

5. **Owner** - Business owner
   - Full system access
   - Financial analytics
   - Strategic reporting
   - System configuration

### 1.3 Key Features

#### Customer Management
- ✅ Dual subscription types (coupon book / cash)
- ✅ Automatic subscription expiry tracking
- ✅ Credit limit enforcement (₪10,000 max debt)
- ✅ Bonus gallons for large coupon purchases
- ✅ Monthly usage tracking with automatic reset
- ✅ Proximity notifications when worker nearby

#### Delivery Operations
- ✅ Priority-based delivery queue (urgent/mid/non-urgent)
- ✅ Real-time GPS tracking
- ✅ Photo verification mandatory
- ✅ State machine for delivery status
- ✅ Inventory management with race condition protection
- ✅ Empty gallon return tracking

#### Payment System
- ✅ Multiple payment methods (cash/credit/bank transfer)
- ✅ Coupon deduction with concurrency locks
- ✅ Debt tracking and payment history
- ✅ Price rounding to 2 decimal places
- ✅ Payment notifications

#### Worker Management
- ✅ Shift scheduling
- ✅ Vehicle inventory tracking
- ✅ Salary advances tracking
- ✅ Expense submission and approval
- ✅ Performance analytics

#### Business Intelligence
- ✅ Real-time dashboard analytics
- ✅ Revenue tracking
- ✅ Client statistics
- ✅ Worker performance metrics
- ✅ Inventory reports

### 1.4 Business Model

**Subscription Types:**

1. **Coupon Book Subscription**
   - Customer purchases coupon books (100-500 pages)
   - Each coupon = 20 gallons of water
   - Bonus gallons for larger purchases
   - No debt accumulation (prepaid)

2. **Cash Subscription**
   - Pay per delivery
   - Credit limit: ₪10,000
   - Flexible payment schedule
   - Debt tracking

**Pricing:**
- Coupon books: ₪0.30-0.50 per page (volume discounts)
- Cash deliveries: Variable pricing per gallon
- Dispenser rental: Tracked separately

---

## 2. SYSTEM ARCHITECTURE

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT APPLICATIONS                      │
├─────────────────────────────────────────────────────────────┤
│  Flutter Mobile App (Android/iOS)  │  Web Dashboard (Admin) │
└─────────────────┬───────────────────┴────────────────────────┘
                  │
                  │ HTTPS/REST API
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                   EXPRESS.JS API SERVER                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth Layer   │  │ Rate Limiter │  │  Validation  │      │
│  │ (JWT)        │  │ (100/15min)  │  │  Middleware  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              BUSINESS LOGIC LAYER                     │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ • Auth Controller      • Delivery Controller         │  │
│  │ • Client Controller    • Worker Controller           │  │
│  │ • Admin Controller     • Payment Controller          │  │
│  │ • Notification Service • Location Service            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              DATA ACCESS LAYER                        │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ • Transaction Manager  • Connection Pool (max 20)    │  │
│  │ • Query Builder        • Row-level Locking           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  │ PostgreSQL Protocol
                  │
┌─────────────────▼───────────────────────────────────────────┐
│              POSTGRESQL 14+ DATABASE                         │
├─────────────────────────────────────────────────────────────┤
│  • PostGIS Extension (GPS)    • 20+ Tables                  │
│  • Row-level Locking          • Triggers & Constraints      │
│  • ACID Transactions          • Indexes for Performance     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   BACKGROUND SERVICES                        │
├─────────────────────────────────────────────────────────────┤
│  • Cron Jobs (Monthly Reset, Cleanup)                       │
│  • Notification Triggers (5 triggers)                       │
│  • Logging Service (Winston)                                │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Choices & Rationale

**Backend: Node.js + Express.js**
- ✅ Fast development cycle
- ✅ Large ecosystem (npm packages)
- ✅ Excellent for I/O-heavy operations
- ✅ JSON-native (perfect for REST APIs)
- ✅ Easy deployment

**Database: PostgreSQL + PostGIS**
- ✅ ACID compliance (critical for financial data)
- ✅ PostGIS for GPS calculations
- ✅ Row-level locking (race condition protection)
- ✅ Mature and stable
- ✅ Excellent performance

**Authentication: JWT (JSON Web Tokens)**
- ✅ Stateless authentication
- ✅ Mobile-friendly
- ✅ Scalable
- ✅ Industry standard

**Mobile: Flutter**
- ✅ Single codebase for Android/iOS
- ✅ Native performance
- ✅ Beautiful UI
- ✅ Hot reload for fast development

### 2.3 File Structure

```
einhod-longterm/
├── einhod-water-backend/          # Node.js API Server
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js        # DB connection pool
│   │   ├── controllers/           # Business logic (12 files)
│   │   │   ├── auth.controller.js
│   │   │   ├── client.controller.js
│   │   │   ├── delivery.controller.js
│   │   │   ├── worker.controller.js
│   │   │   ├── admin.controller.js
│   │   │   ├── payment.controller.js
│   │   │   ├── notifications.controller.js
│   │   │   ├── location.controller.js
│   │   │   ├── schedule.controller.js
│   │   │   ├── shifts.controller.js
│   │   │   ├── revenue.controller.js
│   │   │   └── coupon-sizes.controller.js
│   │   ├── middleware/
│   │   │   ├── auth.middleware.js # JWT verification
│   │   │   └── validation.middleware.js
│   │   ├── routes/                # API endpoints (10 files)
│   │   ├── services/
│   │   │   └── cron.service.js    # Background jobs
│   │   ├── utils/
│   │   │   ├── logger.js          # Winston logging
│   │   │   └── state-machine.js   # Delivery states
│   │   └── server.js              # Entry point
│   ├── database/
│   │   └── schema.sql             # Complete DB schema (847 lines)
│   ├── migrations/                # DB migrations (8 files)
│   ├── logs/                      # Application logs
│   ├── .env                       # Environment config
│   ├── package.json               # Dependencies
│   └── README.md
│
├── einhod-water-flutter/          # Flutter Mobile App
│   ├── lib/
│   │   ├── models/                # Data models
│   │   ├── screens/               # UI screens
│   │   ├── services/              # API services
│   │   └── widgets/               # Reusable components
│   └── pubspec.yaml
│
└── Documentation/                 # Test reports & docs
    ├── RECHECK_14_27.md          # Latest security test (93% fixed)
    ├── VERIFICATION_REPORT_FINAL.md
    └── PROJECT_DOCUMENTATION.md   # This file
```

### 2.4 Data Flow Example: Delivery Request

```
1. CLIENT APP
   └─> POST /api/v1/deliveries/request
       Body: { requested_gallons: 100, priority: "urgent" }
       Headers: { Authorization: "Bearer <token>" }

2. API SERVER
   ├─> auth.middleware.js: Verify JWT token
   ├─> validation.middleware.js: Validate request body
   └─> delivery.controller.js: requestDelivery()
       ├─> Check client is active
       ├─> Check subscription not expired
       ├─> Check credit limit (if cash subscription)
       ├─> Check coupon balance (if coupon subscription)
       └─> BEGIN TRANSACTION
           ├─> INSERT INTO delivery_requests
           ├─> CREATE notification for nearby workers
           └─> COMMIT

3. DATABASE
   ├─> Insert delivery record
   ├─> Trigger: notify_new_delivery_request
   └─> Return delivery ID

4. RESPONSE
   └─> 201 Created
       Body: { success: true, delivery_id: 123, ... }

5. WORKER APP (Real-time)
   └─> Receives notification
       └─> GET /api/v1/workers/deliveries/pending
           └─> Shows new delivery in queue
```

---

## 3. TECHNOLOGY STACK

### 3.1 Backend Dependencies

**Core Framework:**
```json
{
  "express": "^4.18.2",           // Web framework
  "pg": "^8.11.3",                // PostgreSQL client
  "dotenv": "^16.3.1"             // Environment variables
}
```

**Security:**
```json
{
  "bcrypt": "^5.1.1",             // Password hashing
  "jsonwebtoken": "^9.0.2",       // JWT authentication
  "helmet": "^7.1.0",             // Security headers
  "cors": "^2.8.5",               // CORS handling
  "express-rate-limit": "^7.1.5"  // Rate limiting
}
```

**Validation & Utilities:**
```json
{
  "express-validator": "^7.0.1",  // Input validation
  "multer": "^1.4.5-lts.1",       // File uploads
  "winston": "^3.11.0",           // Logging
  "node-cron": "^3.0.3",          // Scheduled tasks
  "axios": "^1.6.2"               // HTTP client
}
```

**Development:**
```json
{
  "nodemon": "^3.0.2",            // Auto-restart
  "jest": "^29.7.0",              // Testing
  "supertest": "^6.3.3",          // API testing
  "eslint": "^8.56.0"             // Code linting
}
```

### 3.2 Database Extensions

```sql
CREATE EXTENSION IF NOT EXISTS postgis;  -- GPS calculations
```

### 3.3 System Requirements

**Production Server:**
- Node.js 18+
- PostgreSQL 14+
- 2GB RAM minimum
- 20GB storage
- Linux/Ubuntu recommended

**Development:**
- Node.js 18+
- PostgreSQL 14+
- 4GB RAM
- Any OS (Windows/Mac/Linux)

---

## 4. DATABASE SCHEMA

### 4.1 Schema Overview

**Total Tables:** 20+  
**Total Lines:** 847  
**Database:** PostgreSQL 14+ with PostGIS

### 4.2 Core Tables

#### 4.2.1 Users & Authentication

**users** - Main user accounts
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,  -- client, delivery_worker, onsite_worker, administrator, owner
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);
```

**Indexes:**
- `idx_users_username` - Fast login lookups
- `idx_users_phone` - Phone number searches
- `idx_users_role` - Role-based queries

#### 4.2.2 Client Profiles

**client_profiles** - Customer information
```sql
CREATE TABLE client_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326),  -- GPS coordinates
    subscription_type subscription_type NOT NULL,  -- coupon_book, cash
    subscription_start_date DATE,
    subscription_end_date DATE,
    subscription_expiry_date DATE,
    remaining_coupons INTEGER DEFAULT 0,
    bonus_gallons INTEGER DEFAULT 0,
    monthly_usage_gallons DECIMAL(10, 2) DEFAULT 0,
    current_debt DECIMAL(10, 2) DEFAULT 0,
    preferred_language VARCHAR(10) DEFAULT 'en',
    proximity_notifications_enabled BOOLEAN DEFAULT TRUE,
    home_latitude DECIMAL(10, 8) CHECK (home_latitude BETWEEN -90 AND 90),
    home_longitude DECIMAL(11, 8) CHECK (home_longitude BETWEEN -180 AND 180),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (remaining_coupons >= 0),
    CHECK (current_debt >= 0 AND current_debt <= 1000000)
);
```

**Key Features:**
- ✅ GPS location with PostGIS
- ✅ Dual subscription types
- ✅ Coupon and bonus gallon tracking
- ✅ Debt limit enforcement (₪10,000)
- ✅ Monthly usage tracking

#### 4.2.3 Worker Profiles

**worker_profiles** - Delivery and on-site workers
```sql
CREATE TABLE worker_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    worker_type user_role NOT NULL,  -- delivery_worker, onsite_worker
    vehicle_plate_number VARCHAR(20),
    vehicle_capacity INTEGER,
    vehicle_current_gallons INTEGER DEFAULT 0,
    current_location GEOGRAPHY(POINT, 4326),
    is_on_shift BOOLEAN DEFAULT FALSE,
    shift_start_time TIMESTAMP,
    debt_advances DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (vehicle_current_gallons >= 0),
    CHECK (vehicle_current_gallons <= vehicle_capacity)
);
```

**Key Features:**
- ✅ Vehicle inventory tracking
- ✅ Real-time GPS location
- ✅ Shift management
- ✅ Salary advance tracking
- ✅ Inventory constraints

#### 4.2.4 Delivery Requests

**delivery_requests** - Core delivery operations
```sql
CREATE TABLE delivery_requests (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    worker_id INTEGER REFERENCES worker_profiles(id) ON DELETE SET NULL,
    requested_gallons DECIMAL(10, 2) NOT NULL,
    gallons_delivered DECIMAL(10, 2),
    empty_gallons_returned DECIMAL(10, 2) DEFAULT 0,
    priority delivery_priority DEFAULT 'non_urgent',  -- urgent, mid_urgent, non_urgent
    status delivery_status DEFAULT 'pending',  -- pending, in_progress, completed, cancelled
    payment_method payment_method,  -- cash, credit_card, bank_transfer
    total_price DECIMAL(10, 2),
    paid_amount DECIMAL(10, 2),
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    photo_url TEXT,
    notes TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    
    -- Constraints
    CHECK (requested_gallons > 0 AND requested_gallons <= 1000),
    CHECK (gallons_delivered >= 0 AND gallons_delivered <= 1000),
    CHECK (empty_gallons_returned >= 0),
    CHECK (paid_amount >= 0),
    CHECK (delivery_latitude BETWEEN -90 AND 90),
    CHECK (delivery_longitude BETWEEN -180 AND 180)
);
```

**State Machine:**
```
pending → in_progress → completed
   ↓           ↓
cancelled   cancelled
```

**Key Features:**
- ✅ Priority-based queue
- ✅ State machine validation
- ✅ GPS coordinates mandatory
- ✅ Photo verification required
- ✅ Empty gallon tracking
- ✅ Payment tracking

#### 4.2.5 Coupon System

**coupon_sizes** - Coupon book configurations
```sql
CREATE TABLE coupon_sizes (
    id SERIAL PRIMARY KEY,
    size INTEGER NOT NULL UNIQUE,  -- 100, 200, 300, 400, 500
    price_per_page DECIMAL(10, 2) DEFAULT 0.50,
    bonus_gallons INTEGER DEFAULT 0,
    available_stock INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Default sizes
INSERT INTO coupon_sizes (size, price_per_page, bonus_gallons) VALUES 
(100, 0.50, 0),   -- ₪50, no bonus
(200, 0.45, 10),  -- ₪90, +10 gallons
(300, 0.40, 20),  -- ₪120, +20 gallons
(400, 0.35, 30),  -- ₪140, +30 gallons
(500, 0.30, 50);  -- ₪150, +50 gallons
```

**coupon_book_purchases** - Purchase history
```sql
CREATE TABLE coupon_book_purchases (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    coupon_size_id INTEGER REFERENCES coupon_sizes(id),
    quantity INTEGER NOT NULL,
    total_coupons INTEGER NOT NULL,
    bonus_gallons INTEGER DEFAULT 0,
    total_price DECIMAL(10, 2) NOT NULL,
    payment_method payment_method NOT NULL,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4.2.6 Payments

**payments** - Payment transactions
```sql
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES client_profiles(id) ON DELETE CASCADE,
    delivery_id INTEGER REFERENCES delivery_requests(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method payment_method NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    transaction_reference VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (amount > 0)
);
```

#### 4.2.7 Dispensers

**dispensers** - Water dispenser inventory
```sql
CREATE TABLE dispensers (
    id SERIAL PRIMARY KEY,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    dispenser_type dispenser_type NOT NULL,  -- touch, manual, electric
    status dispenser_status DEFAULT 'new',  -- new, used, disabled, in_maintenance
    current_client_id INTEGER REFERENCES client_profiles(id) ON DELETE SET NULL,
    purchase_price DECIMAL(10, 2),
    rental_price_monthly DECIMAL(10, 2),
    installation_date DATE,
    last_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4.2.8 Notifications

**notifications** - System notifications
```sql
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category notification_category DEFAULT 'normal',  -- important, mid_importance, normal
    is_read BOOLEAN DEFAULT FALSE,
    related_delivery_id INTEGER REFERENCES delivery_requests(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.3 Database Triggers

**5 Active Triggers:**

1. **notify_new_delivery_request** - Notify workers of new deliveries
2. **notify_delivery_assigned** - Notify client when worker assigned
3. **notify_delivery_started** - Notify client when delivery starts
4. **notify_delivery_completed** - Notify client when delivery completes
5. **update_updated_at_column** - Auto-update timestamps

### 4.4 Database Constraints

**Security Constraints:**
- ✅ GPS coordinates validated (-90 to 90, -180 to 180)
- ✅ Gallons range validated (0 to 1000)
- ✅ Debt limit enforced (₪0 to ₪1,000,000)
- ✅ Negative values prevented
- ✅ Vehicle capacity constraints
- ✅ Coupon balance non-negative

**Referential Integrity:**
- ✅ CASCADE deletes for user profiles
- ✅ SET NULL for optional references
- ✅ Foreign key constraints on all relationships

### 4.5 Indexes for Performance

```sql
-- User lookups
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_role ON users(role);

-- GPS queries
CREATE INDEX idx_client_location ON client_profiles USING GIST(location);
CREATE INDEX idx_worker_location ON worker_profiles USING GIST(current_location);

-- Delivery queries
CREATE INDEX idx_delivery_client ON delivery_requests(client_id);
CREATE INDEX idx_delivery_worker ON delivery_requests(worker_id);
CREATE INDEX idx_delivery_status ON delivery_requests(status);
CREATE INDEX idx_delivery_priority ON delivery_requests(priority);

-- Payment queries
CREATE INDEX idx_payment_client ON payments(client_id);
CREATE INDEX idx_payment_status ON payments(payment_status);

-- Notification queries
CREATE INDEX idx_notification_user ON notifications(user_id);
CREATE INDEX idx_notification_read ON notifications(is_read);
```

---

## 5. API ENDPOINTS

### 5.1 Base URL

```
Production: https://api.einhod-water.com/api/v1
Development: http://localhost:3000/api/v1
```

### 5.2 Authentication Endpoints

**POST /auth/login**
```javascript
// Request
{
  "username": "owner",
  "password": "Admin123!"
}

// Response (200 OK)
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "username": "owner",
      "role": "owner",
      "phone_number": "+972501234567"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**GET /auth/me**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "id": 1,
    "username": "owner",
    "role": "owner",
    "phone_number": "+972501234567",
    "is_active": true
  }
}
```

**POST /auth/password/change**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "current_password": "Admin123!",
  "new_password": "NewPassword123!"
}

// Response (200 OK)
{
  "success": true,
  "message": "Password changed successfully"
}
```

**POST /auth/password-reset/request**
```javascript
// Request
{
  "phone_number": "+972501234567"
}

// Response (200 OK)
{
  "success": true,
  "message": "Password reset code sent to your phone"
}
```

**POST /auth/logout**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}

// Response (200 OK)
{
  "success": true,
  "message": "Logged out successfully"
}
```

### 5.3 Client Endpoints

**GET /clients/profile**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "id": 5,
    "full_name": "John Doe",
    "address": "123 Main St, Tel Aviv",
    "subscription_type": "coupon_book",
    "remaining_coupons": 150,
    "bonus_gallons": 20,
    "monthly_usage_gallons": 240,
    "current_debt": 0,
    "subscription_expiry_date": "2027-12-31",
    "subscription_status": "active"
  }
}
```

**PUT /clients/profile**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "full_name": "John Doe Updated",
  "address": "456 New St, Tel Aviv",
  "home_latitude": 32.0853,
  "home_longitude": 34.7818
}

// Response (200 OK)
{
  "success": true,
  "message": "Profile updated successfully"
}
```

**GET /clients/delivery-history**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Query params
?page=1&limit=20&status=completed

// Response (200 OK)
{
  "success": true,
  "data": {
    "deliveries": [
      {
        "id": 123,
        "requested_gallons": 100,
        "gallons_delivered": 100,
        "status": "completed",
        "total_price": 50.00,
        "completed_at": "2026-02-28T10:30:00Z",
        "worker_name": "Ahmed"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "pages": 3
    }
  }
}
```

### 5.4 Delivery Endpoints

**POST /deliveries/request**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "requested_gallons": 100,
  "priority": "urgent",
  "delivery_address": "123 Main St, Tel Aviv",
  "delivery_latitude": 32.0853,
  "delivery_longitude": 34.7818,
  "payment_method": "coupon_book",
  "notes": "Please call before arriving"
}

// Response (201 Created)
{
  "success": true,
  "message": "Delivery request created successfully",
  "data": {
    "delivery_id": 456,
    "status": "pending",
    "estimated_coupons": 5
  }
}
```

**GET /deliveries/:id**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "id": 456,
    "requested_gallons": 100,
    "status": "in_progress",
    "priority": "urgent",
    "worker": {
      "id": 10,
      "name": "Ahmed",
      "phone": "+972501234567",
      "current_latitude": 32.0850,
      "current_longitude": 34.7815
    },
    "requested_at": "2026-02-28T10:00:00Z",
    "assigned_at": "2026-02-28T10:05:00Z",
    "started_at": "2026-02-28T10:10:00Z"
  }
}
```

**PATCH /deliveries/:id**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request (Client can update before assignment)
{
  "priority": "mid_urgent",
  "requested_gallons": 120,
  "notes": "Updated notes"
}

// Response (200 OK)
{
  "success": true,
  "message": "Delivery request updated successfully"
}
```

**DELETE /deliveries/:id**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "message": "Delivery request cancelled successfully"
}
```

### 5.5 Worker Endpoints

**GET /workers/deliveries/pending**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "deliveries": [
      {
        "id": 456,
        "client_name": "John Doe",
        "client_phone": "+972501234567",
        "requested_gallons": 100,
        "priority": "urgent",
        "delivery_address": "123 Main St, Tel Aviv",
        "delivery_latitude": 32.0853,
        "delivery_longitude": 34.7818,
        "distance_km": 2.5,
        "requested_at": "2026-02-28T10:00:00Z"
      }
    ]
  }
}
```

**POST /workers/deliveries/:id/accept**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "message": "Delivery accepted successfully",
  "data": {
    "delivery_id": 456,
    "status": "in_progress"
  }
}
```

**PATCH /workers/deliveries/:id/complete**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "gallons_delivered": 100,
  "empty_gallons_returned": 5,
  "total_price": 50.00,
  "paid_amount": 50.00,
  "delivery_latitude": 32.0853,
  "delivery_longitude": 34.7818,
  "photo_url": "https://storage.../photo.jpg",
  "notes": "Delivery completed successfully"
}

// Response (200 OK)
{
  "success": true,
  "message": "Delivery completed successfully",
  "data": {
    "delivery_id": 456,
    "coupons_deducted": 5,
    "remaining_coupons": 145
  }
}
```

**POST /workers/location/update**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "latitude": 32.0853,
  "longitude": 34.7818
}

// Response (200 OK)
{
  "success": true,
  "message": "Location updated successfully"
}
```

**GET /workers/inventory**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "vehicle_capacity": 1000,
    "current_gallons": 750,
    "available_gallons": 750,
    "deliveries_today": 5,
    "gallons_delivered_today": 250
  }
}
```

### 5.6 Admin Endpoints

**GET /admin/dashboard**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "data": {
    "total_clients": 150,
    "active_clients": 142,
    "total_workers": 12,
    "active_workers": 8,
    "pending_deliveries": 15,
    "in_progress_deliveries": 8,
    "completed_today": 45,
    "revenue_today": 2250.00,
    "revenue_month": 67500.00,
    "clients_with_debt": 23,
    "total_debt": 45000.00
  }
}
```

**GET /admin/clients**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Query params
?page=1&limit=50&search=john&subscription_type=coupon_book

// Response (200 OK)
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": 5,
        "full_name": "John Doe",
        "phone_number": "+972501234567",
        "subscription_type": "coupon_book",
        "remaining_coupons": 150,
        "current_debt": 0,
        "monthly_usage": 240,
        "is_active": true
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 150,
      "pages": 3
    }
  }
}
```

**POST /admin/clients**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "username": "johndoe",
  "password": "SecurePass123!",
  "phone_number": "+972501234567",
  "full_name": "John Doe",
  "address": "123 Main St, Tel Aviv",
  "subscription_type": "coupon_book",
  "home_latitude": 32.0853,
  "home_longitude": 34.7818
}

// Response (201 Created)
{
  "success": true,
  "message": "Client created successfully",
  "data": {
    "user_id": 25,
    "client_id": 20
  }
}
```

**GET /admin/reports/revenue**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Query params
?start_date=2026-02-01&end_date=2026-02-28

// Response (200 OK)
{
  "success": true,
  "data": {
    "total_revenue": 67500.00,
    "coupon_sales": 45000.00,
    "cash_deliveries": 22500.00,
    "total_deliveries": 450,
    "average_delivery_value": 150.00,
    "daily_breakdown": [
      {
        "date": "2026-02-01",
        "revenue": 2400.00,
        "deliveries": 16
      }
    ]
  }
}
```

### 5.7 Payment Endpoints

**POST /payments/record**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "client_id": 5,
  "amount": 1000.00,
  "payment_method": "cash",
  "notes": "Debt payment"
}

// Response (201 Created)
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": {
    "payment_id": 789,
    "new_debt_balance": 0.00
  }
}
```

**POST /payments/coupon-purchase**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Request
{
  "coupon_size_id": 3,  // 300 pages
  "quantity": 1,
  "payment_method": "credit_card"
}

// Response (201 Created)
{
  "success": true,
  "message": "Coupon book purchased successfully",
  "data": {
    "purchase_id": 123,
    "total_coupons": 300,
    "bonus_gallons": 20,
    "total_price": 120.00,
    "new_coupon_balance": 450
  }
}
```

### 5.8 Notification Endpoints

**GET /notifications**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Query params
?page=1&limit=20&is_read=false

// Response (200 OK)
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 456,
        "title": "Delivery Completed",
        "message": "Your delivery of 100 gallons has been completed",
        "category": "important",
        "is_read": false,
        "created_at": "2026-02-28T10:30:00Z"
      }
    ],
    "unread_count": 5
  }
}
```

**PATCH /notifications/:id/read**
```javascript
// Headers
Authorization: Bearer <accessToken>

// Response (200 OK)
{
  "success": true,
  "message": "Notification marked as read"
}
```

### 5.9 Error Responses

**400 Bad Request**
```javascript
{
  "success": false,
  "message": "Validation error",
  "errors": [
    {
      "field": "requested_gallons",
      "message": "Must be between 1 and 1000"
    }
  ]
}
```

**401 Unauthorized**
```javascript
{
  "success": false,
  "message": "Invalid or expired token"
}
```

**403 Forbidden**
```javascript
{
  "success": false,
  "message": "Insufficient permissions"
}
```

**404 Not Found**
```javascript
{
  "success": false,
  "message": "Resource not found"
}
```

**429 Too Many Requests**
```javascript
{
  "success": false,
  "message": "Rate limit exceeded. Try again in 15 minutes."
}
```

**500 Internal Server Error**
```javascript
{
  "success": false,
  "message": "An unexpected error occurred"
}
```

---

