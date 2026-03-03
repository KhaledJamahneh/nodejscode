# Einhod Pure Water - Backend API

Complete backend API for the Einhod Pure Water Delivery Management System.

## 📋 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation Guide](#installation-guide)
- [Database Setup](#database-setup)
- [Running the Server](#running-the-server)
- [API Documentation](#api-documentation)
- [Project Structure](#project-structure)
- [Next Steps](#next-steps)

## 🎯 Overview

This is a Node.js/Express backend API serving a water delivery management platform with:
- 5 user roles (Client, Delivery Worker, On-Site Worker, Administrator, Owner)
- Real-time GPS tracking
- Subscription & payment management
- Delivery coordination
- Comprehensive business analytics

## 🛠 Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+ with PostGIS extension
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcrypt
- **Logging**: Winston
- **Validation**: express-validator
- **Security**: Helmet, CORS, Rate Limiting

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

1. **Node.js** (v18 or higher)
   - Download from: https://nodejs.org/
   - Verify: `node --version`

2. **PostgreSQL** (v14 or higher)
   - Download from: https://www.postgresql.org/download/
   - Verify: `psql --version`

3. **npm** (comes with Node.js)
   - Verify: `npm --version`

4. **Git** (for version control)
   - Download from: https://git-scm.com/
   - Verify: `git --version`

## 📦 Installation Guide

### Step 1: Project Setup

```bash
# Navigate to the project directory
cd einhod-water-backend

# Install all dependencies
npm install
```

This will install all packages listed in `package.json`.

### Step 2: Environment Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Open .env in your text editor and fill in your values
# Important: Change the JWT secrets and database password!
```

**Critical .env settings to configure:**

```env
# Database
DB_PASSWORD=your_actual_database_password

# Security (CHANGE THESE!)
JWT_SECRET=your_long_random_secret_at_least_32_characters
JWT_REFRESH_SECRET=your_other_long_random_secret_different_from_above

# Optional (for later)
GOOGLE_MAPS_API_KEY=your_key_here
FCM_SERVER_KEY=your_firebase_key_here
```

## 🗄 Database Setup

### Step 1: Create PostgreSQL Database

#### On Windows:
1. Open pgAdmin 4 (installed with PostgreSQL)
2. Connect to PostgreSQL server (localhost)
3. Right-click "Databases" → "Create" → "Database"
4. Name: `einhod_water`
5. Click "Save"

#### On Mac/Linux:
```bash
# Login to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE einhod_water;

# Exit
\q
```

### Step 2: Run Database Schema

```bash
# Using psql command line
psql -U postgres -d einhod_water -f database/schema.sql

# OR using pgAdmin:
# 1. Open pgAdmin
# 2. Connect to einhod_water database
# 3. Tools → Query Tool
# 4. Open file: database/schema.sql
# 5. Click Execute (F5)
```

### Step 3: Verify Database

```bash
# Connect to database
psql -U postgres -d einhod_water

# List all tables
\dt

# You should see tables like: users, client_profiles, worker_profiles, etc.

# Check if PostGIS is installed
SELECT PostGIS_version();

# Exit
\q
```

## 🚀 Running the Server

### Development Mode (with auto-restart)

```bash
npm run dev
```

The server will start on `http://localhost:3000` and automatically restart when you make changes.

### Production Mode

```bash
npm start
```

### Verify Server is Running

Open your browser and go to: `http://localhost:3000/health`

You should see:
```json
{
  "status": "ok",
  "timestamp": "2024-...",
  "uptime": 5.234,
  "environment": "development"
}
```

## 📚 API Documentation

### Base URL

```
http://localhost:3000/api/v1
```

### Authentication Endpoints

#### 1. Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "owner",
  "password": "Admin123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "username": "owner",
      "role": "owner",
      "phone_number": "+1234567890"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

#### 2. Get Current User
```http
GET /api/v1/auth/me
Authorization: Bearer {accessToken}
```

#### 3. Change Password
```http
POST /api/v1/auth/password/change
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "current_password": "Admin123!",
  "new_password": "NewPassword123!"
}
```

#### 4. Request Password Reset
```http
POST /api/v1/auth/password-reset/request
Content-Type: application/json

{
  "phone_number": "+1234567890"
}
```

#### 5. Logout
```http
POST /api/v1/auth/logout
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "refreshToken": "your_refresh_token"
}
```

### Testing with Postman/Thunder Client

1. **Install a REST client** (choose one):
   - Postman: https://www.postman.com/downloads/
   - Thunder Client (VS Code extension)
   - Insomnia: https://insomnia.rest/

2. **Test the login endpoint:**
   - Method: POST
   - URL: `http://localhost:3000/api/v1/auth/login`
   - Headers: `Content-Type: application/json`
   - Body (raw JSON):
     ```json
     {
       "username": "owner",
       "password": "Admin123!"
     }
     ```

3. **Copy the accessToken from the response**

4. **Test authenticated endpoint:**
   - Method: GET
   - URL: `http://localhost:3000/api/v1/auth/me`
   - Headers: 
     - `Content-Type: application/json`
     - `Authorization: Bearer YOUR_ACCESS_TOKEN_HERE`

## 📁 Project Structure

```
einhod-water-backend/
├── database/
│   └── schema.sql              # Complete database schema
├── src/
│   ├── config/
│   │   └── database.js         # Database connection config
│   ├── controllers/
│   │   └── auth.controller.js  # Authentication logic
│   ├── middleware/
│   │   ├── auth.middleware.js  # JWT verification
│   │   └── validation.middleware.js
│   ├── routes/
│   │   ├── auth.routes.js      # Auth endpoints ✅
│   │   ├── client.routes.js    # Client endpoints (placeholder)
│   │   ├── delivery.routes.js  # Delivery endpoints (placeholder)
│   │   ├── worker.routes.js    # Worker endpoints (placeholder)
│   │   ├── admin.routes.js     # Admin endpoints (placeholder)
│   │   ├── gps.routes.js       # GPS endpoints (placeholder)
│   │   ├── payment.routes.js   # Payment endpoints (placeholder)
│   │   └── notification.routes.js
│   ├── utils/
│   │   └── logger.js           # Winston logger
│   └── server.js               # Main entry point
├── logs/                       # Application logs
├── .env.example               # Environment template
├── .env                       # Your environment config (create this)
├── package.json               # Dependencies
└── README.md                  # This file
```

## 🔐 Default Credentials

**Owner Account:**
- Username: `owner`
- Password: `Admin123!`
- Role: `owner`

⚠️ **IMPORTANT**: Change this password immediately after first login!

## 🐛 Troubleshooting

### "Cannot connect to database"
- Verify PostgreSQL is running
- Check DB_PASSWORD in .env matches your PostgreSQL password
- Ensure database `einhod_water` exists

### "Port 3000 already in use"
- Change PORT in .env to another number (e.g., 3001)
- Or stop the other process using port 3000

### "Module not found"
- Run `npm install` again
- Delete `node_modules` folder and run `npm install`

### "PostGIS extension error"
- Install PostGIS: 
  - Windows: Stack Builder during PostgreSQL installation
  - Mac: `brew install postgis`
  - Linux: `sudo apt-get install postgis`

## 📝 Development Status

### ✅ Phase 1-4: Backend Core (COMPLETE)
1. ✅ Authentication system
2. ✅ Client endpoints (profile, subscriptions)
3. ✅ Delivery request system
4. ✅ Worker schedule management
5. ✅ Payment processing
6. ✅ Admin features
7. ✅ Database schema complete

### ✅ Phase 5: Flutter App (COMPLETE)
8. ✅ Mobile app development
9. ✅ UI/UX implementation
10. ✅ All 21 issues fixed
11. ✅ Production-ready

### 🔧 Final Backend Updates Needed
See `BACKEND_ENDPOINTS_NEEDED.md` for 4 remaining endpoints:
- User registration (admin)
- Dispenser settings (client)
- Coupon price update (admin)
- Request cancel/delete (admin)

**Estimated time:** 30-45 minutes

## 🤝 Development Workflow

When you're ready to build the next feature:

1. **Choose an endpoint to implement** (e.g., client profile)
2. **Create the controller** in `src/controllers/`
3. **Add validation rules** in the route file
4. **Test with Postman/Thunder Client**
5. **Document in README**

## 📞 Need Help?

If you get stuck:
1. Check the logs in `logs/combined.log`
2. Review error messages carefully
3. Test database queries in pgAdmin
4. Ask me for help with specific errors!

## 🎉 Congratulations!

You now have a working backend API foundation. The authentication system is complete and tested. You can log in, manage tokens, and reset passwords.

**Ready to build the next feature?** Let me know which endpoint you want to tackle first!

---

Built with ❤️ for Einhod Pure Water
