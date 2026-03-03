# ✅ DEPLOYMENT CHECKLIST

Use this checklist when deploying to production.

---

## 📋 PRE-DEPLOYMENT

- [x] All code implemented
- [x] All endpoints tested locally
- [x] Documentation complete
- [x] Database migration ready
- [x] Code committed to Git
- [x] Code pushed to GitHub

---

## 🚀 DEPLOYMENT STEPS

### 1. Server Preparation
- [ ] SSH into production server
- [ ] Navigate to project directory
- [ ] Backup current database
  ```bash
  pg_dump -U postgres einhod_water > backup_$(date +%Y%m%d_%H%M%S).sql
  ```

### 2. Code Update
- [ ] Pull latest code
  ```bash
  git pull origin main
  ```
- [ ] Verify correct commit
  ```bash
  git log -1
  # Should show: bbf28a3 or later
  ```

### 3. Dependencies
- [ ] Install any new dependencies
  ```bash
  npm install
  ```

### 4. Database Migration
- [ ] Run migration script
  ```bash
  psql -U postgres -d einhod_water -f database/migrations/005_add_dispenser_settings.sql
  ```
- [ ] Verify column exists
  ```bash
  psql -U postgres -d einhod_water -c "\d client_profiles"
  # Should show dispenser_settings column
  ```

### 5. Server Restart
- [ ] Restart the backend server
  ```bash
  # Development
  npm run dev
  
  # Production with PM2
  pm2 restart einhod-backend
  
  # Production with systemd
  sudo systemctl restart einhod-backend
  ```

### 6. Health Check
- [ ] Verify server is running
  ```bash
  curl http://localhost:3000/health
  # Should return: {"status":"ok",...}
  ```

### 7. Endpoint Verification
- [ ] Run verification script
  ```bash
  ./verify-endpoints.sh
  ```
- [ ] Test dispenser settings endpoint
  ```bash
  # Get a client token first
  TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"testclient","password":"password"}' \
    | jq -r '.data.accessToken')
  
  # Test endpoint
  curl -H "Authorization: Bearer $TOKEN" \
    http://localhost:3000/api/v1/clients/dispensers/settings
  ```

---

## 🧪 POST-DEPLOYMENT TESTING

### Client Endpoints
- [ ] Test GET /api/v1/clients/dispensers/settings
- [ ] Test PUT /api/v1/clients/dispensers/settings
- [ ] Test client profile access
- [ ] Test payment flow (with null debt)

### Admin Endpoints
- [ ] Test POST /api/v1/admin/requests/:id/cancel
- [ ] Test DELETE /api/v1/admin/requests/:id/permanent
- [ ] Test user management
- [ ] Test analytics dashboard

### Worker Endpoints
- [ ] Test delivery assignment
- [ ] Test schedule management
- [ ] Test location updates

---

## 📱 FLUTTER APP TESTING

- [ ] Update API base URL in Flutter app (if needed)
- [ ] Test dispenser settings screen
- [ ] Test request cancellation
- [ ] Test payment flow
- [ ] Test all 21 previously fixed issues
- [ ] Build and test release APK

---

## 📊 MONITORING

### Immediate (First Hour)
- [ ] Monitor error logs
  ```bash
  tail -f logs/combined.log
  # OR with PM2
  pm2 logs einhod-backend
  ```
- [ ] Check for 500 errors
- [ ] Verify database connections
- [ ] Monitor response times

### First Day
- [ ] Check error rate in logs
- [ ] Monitor database performance
- [ ] Verify all endpoints responding
- [ ] Check user feedback

### First Week
- [ ] Review analytics data
- [ ] Check for any edge cases
- [ ] Monitor server resources (CPU, RAM, disk)
- [ ] Gather user feedback

---

## 🔧 TROUBLESHOOTING

### Server Won't Start
```bash
# Check logs
cat logs/combined.log | tail -50

# Check port availability
lsof -i :3000

# Check database connection
psql -U postgres -d einhod_water -c "SELECT 1"
```

### Migration Fails
```bash
# Check if column already exists
psql -U postgres -d einhod_water -c "\d client_profiles"

# If exists, skip migration
# If not, check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Endpoints Return 404
```bash
# Verify routes are loaded
grep -r "dispensers/settings" src/routes/

# Check server logs for route registration
cat logs/combined.log | grep -i "route"
```

### Endpoints Return 401
```bash
# Verify JWT secret is set
grep JWT_SECRET .env

# Test token generation
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"owner","password":"Admin123!"}'
```

---

## 📞 ROLLBACK PROCEDURE

If something goes wrong:

### 1. Stop Server
```bash
pm2 stop einhod-backend
# OR
sudo systemctl stop einhod-backend
```

### 2. Restore Database
```bash
psql -U postgres -d einhod_water < backup_YYYYMMDD_HHMMSS.sql
```

### 3. Revert Code
```bash
git log --oneline -5  # Find previous commit
git checkout <previous-commit-hash>
```

### 4. Restart Server
```bash
pm2 start einhod-backend
# OR
sudo systemctl start einhod-backend
```

---

## ✅ COMPLETION CHECKLIST

- [ ] All deployment steps completed
- [ ] All tests passing
- [ ] No errors in logs
- [ ] Flutter app working
- [ ] Users can access system
- [ ] Monitoring in place
- [ ] Team notified of deployment

---

## 📝 NOTES

**Deployment Date:** _______________

**Deployed By:** _______________

**Server:** _______________

**Issues Encountered:** 
- 
- 
- 

**Resolution:**
- 
- 
- 

---

## 🎉 SUCCESS!

Once all items are checked, the deployment is complete!

**Next Steps:**
1. Monitor for 24 hours
2. Gather user feedback
3. Plan next iteration
4. Celebrate! 🎊

---

*Einhod Pure Water - Production Deployment Checklist*  
*Version 1.0 - March 2026*
