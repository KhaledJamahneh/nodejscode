# 🚀 QUICK START GUIDE - Einhod Pure Water Backend

This is a step-by-step guide for absolute beginners. Follow each step carefully!

## ⚡ What You're Building

A water delivery management system backend that handles:
- User authentication (login/logout)
- Customer subscriptions
- Delivery tracking with GPS
- Payment processing
- Business analytics

## 📋 Before You Start - Install These Programs

### 1. Install Node.js
- **What it is**: JavaScript runtime to run the backend server
- **Download**: https://nodejs.org/ (Download the LTS version)
- **How to install**: 
  - Windows/Mac: Run the installer, click "Next" until done
  - Check it worked: Open terminal/command prompt, type: `node --version`
  - You should see something like: `v18.17.0`

### 2. Install PostgreSQL
- **What it is**: Database to store all your app data
- **Download**: https://www.postgresql.org/download/
- **How to install**:
  - Windows: Run installer, remember the password you set!
  - Mac: Use the installer or run `brew install postgresql`
  - During installation, install "Stack Builder" extras (includes PostGIS)
  - **IMPORTANT**: Remember your PostgreSQL password!

### 3. Install a Code Editor (Optional but recommended)
- **VS Code** (Recommended): https://code.visualstudio.com/
- Or use any text editor you like

### 4. Install a REST API Testing Tool
- **Postman**: https://www.postman.com/downloads/
- Or **Thunder Client** (VS Code extension)
- This lets you test your API without building a frontend yet

## 🎯 Step-by-Step Setup

### STEP 1: Open Terminal/Command Prompt

**Windows**: 
- Press `Windows Key + R`
- Type `cmd` and press Enter

**Mac**: 
- Press `Cmd + Space`
- Type `terminal` and press Enter

### STEP 2: Navigate to Project Folder

```bash
# Replace this path with where you saved the project
cd path/to/einhod-water-backend

# Example on Windows:
cd C:\Users\YourName\Documents\einhod-water-backend

# Example on Mac:
cd ~/Documents/einhod-water-backend
```

### STEP 3: Install Dependencies

```bash
npm install
```

**Wait for it to finish** (might take 2-3 minutes). You'll see a progress bar.

### STEP 4: Create Your Environment File

```bash
# On Windows Command Prompt:
copy .env.example .env

# On Mac/Linux or Windows PowerShell:
cp .env.example .env
```

Now open the `.env` file in your text editor and **CHANGE THESE**:

```env
# Change this to your PostgreSQL password
DB_PASSWORD=your_postgres_password_here

# Change these to any random long strings (at least 32 characters)
JWT_SECRET=make_this_a_really_long_random_string_at_least_32_chars
JWT_REFRESH_SECRET=make_this_different_also_very_long_and_random_32_plus
```

**Save the file!**

### STEP 5: Create the Database

#### Option A: Using pgAdmin (Easier for Beginners)

1. Open **pgAdmin 4** (installed with PostgreSQL)
2. Enter your PostgreSQL password when prompted
3. In the left sidebar, right-click on **"Databases"**
4. Click **"Create" → "Database..."**
5. In "Database" field, type: `einhod_water`
6. Click **"Save"**

#### Option B: Using Command Line

```bash
# Login to PostgreSQL (enter your password when prompted)
psql -U postgres

# Create database
CREATE DATABASE einhod_water;

# Quit
\q
```

### STEP 6: Load the Database Schema

#### Using pgAdmin (Recommended):

1. In pgAdmin, click on the `einhod_water` database
2. Go to **Tools → Query Tool**
3. Click the folder icon (Open File)
4. Navigate to your project folder
5. Select `database/schema.sql`
6. Click the **Execute** button (or press F5)
7. You should see "Query returned successfully"

#### Using Command Line:

```bash
psql -U postgres -d einhod_water -f database/schema.sql
```

### STEP 7: Start the Server!

```bash
npm run dev
```

**You should see:**
```
🚀 Einhod Pure Water API Server running on port 3000
📍 Environment: development
🔗 API Base URL: http://localhost:3000/api/v1
💊 Health check: http://localhost:3000/health
```

**🎉 Congratulations! Your server is running!**

### STEP 8: Test Your API

#### Test 1: Health Check (Using Browser)
- Open your web browser
- Go to: `http://localhost:3000/health`
- You should see JSON data like:
  ```json
  {
    "status": "ok",
    "timestamp": "...",
    "uptime": 5.234
  }
  ```

#### Test 2: Login (Using Postman)

1. **Open Postman**

2. **Create a new request:**
   - Click "+" to create new request
   - Change dropdown from "GET" to "POST"
   - Enter URL: `http://localhost:3000/api/v1/auth/login`

3. **Add headers:**
   - Click "Headers" tab
   - Add: `Content-Type` = `application/json`

4. **Add body:**
   - Click "Body" tab
   - Select "raw"
   - Select "JSON" from dropdown
   - Paste this:
     ```json
     {
       "username": "owner",
       "password": "Admin123!"
     }
     ```

5. **Click "Send"**

6. **You should get a response with:**
   - `accessToken` (long string)
   - User information
   - Status: 200 OK

**🎊 It works! You successfully logged in!**

## 🎓 What You Just Built

You now have a working backend with:
- ✅ User authentication (login/logout)
- ✅ Password management
- ✅ JWT token system
- ✅ Database with all tables
- ✅ Security middleware
- ✅ Logging system

## 📚 What's Next?

Now you can build the rest of the API features:

1. **Client Management** - Let customers view their profile and orders
2. **Delivery System** - Track deliveries in real-time
3. **Payment Processing** - Handle payments
4. **Admin Dashboard** - View analytics and manage the business

**Want to build the next feature?** Just let me know which one, and I'll guide you through it step by step!

## 🆘 Common Problems & Solutions

### Problem: "npm: command not found"
**Solution**: Node.js not installed or not in PATH. Reinstall Node.js.

### Problem: "Cannot connect to database"
**Solution**: 
- Make sure PostgreSQL is running
- Check your password in `.env` file
- Make sure database `einhod_water` exists

### Problem: "Port 3000 already in use"
**Solution**: 
- Option 1: Stop the other program using port 3000
- Option 2: Change PORT in `.env` to 3001

### Problem: "psql: command not found"
**Solution**: Add PostgreSQL to your PATH or use pgAdmin instead

### Problem: Files not found or "ENOENT" errors
**Solution**: Make sure you're in the correct directory: `cd einhod-water-backend`

### Problem: "Cannot find module"
**Solution**: Run `npm install` again

## 🎯 Testing Checklist

Before moving to the next phase, test these:

- [ ] Server starts without errors
- [ ] Health check returns status "ok"
- [ ] Login with owner credentials works
- [ ] Login with wrong password fails
- [ ] `/api/v1/auth/me` returns user info (with valid token)
- [ ] `/api/v1/auth/me` fails without token

## 💡 Tips for Learning

1. **Don't rush**: Take time to understand each part
2. **Read the code**: Open the files and see what each line does
3. **Experiment**: Try changing things and see what happens
4. **Use the logs**: Check `logs/combined.log` when things go wrong
5. **Ask questions**: Don't hesitate to ask for clarification!

---

**Need help?** Ask me anytime! I'm here to guide you through every step. 🚀
