# ✅ LOGIC FIXES - APPLICATION CHECKLIST

**Project:** Einhod Pure Water Backend  
**Date:** 2026-02-28  
**Estimated Time:** 15-30 minutes  
**Risk Level:** Medium (breaking changes)

---

## 📋 PRE-APPLICATION

### Preparation
- [ ] Read `MIGRATION_GUIDE.md` completely
- [ ] Read `LOGIC_IMPROVEMENTS_SUMMARY.md`
- [ ] Review `DEVELOPER_QUICK_REFERENCE.md`
- [ ] Notify team of upcoming changes
- [ ] Schedule maintenance window (15-30 min)
- [ ] Prepare rollback plan

### Backup
- [ ] Stop application server
- [ ] Create database backup:
  ```bash
  pg_dump -U postgres einhod_water > backup_$(date +%Y%m%d_%H%M%S).sql
  ```
- [ ] Verify backup file exists and has content
- [ ] Create code backup:
  ```bash
  git commit -am "Pre-migration backup"
  git tag pre-migration-backup
  ```

---

## 🔧 APPLICATION

### Step 1: Apply Database Migration
- [ ] Navigate to project directory:
  ```bash
  cd einhod-water-backend
  ```
- [ ] Apply migration:
  ```bash
  psql -U postgres -d einhod_water -f migrations/fix_all_logical_issues.sql
  ```
- [ ] Check for errors in output
- [ ] If errors occur, STOP and investigate

### Step 2: Verify Database Changes
- [ ] Connect to database:
  ```bash
  psql -U postgres -d einhod_water
  ```
- [ ] Verify roles column:
  ```sql
  \d users
  -- Should show: roles | user_role[] | not null | default ARRAY['client']::user_role[]
  ```
- [ ] Verify timezone types:
  ```sql
  SELECT column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name = 'users' AND column_name = 'created_at';
  -- Should show: timestamptz
  ```
- [ ] Verify system_config table:
  ```sql
  SELECT * FROM system_config;
  -- Should show 3 rows
  ```
- [ ] Verify functions exist:
  ```sql
  SELECT proname FROM pg_proc WHERE proname IN ('use_coupons', 'update_vehicle_inventory');
  -- Should show 2 rows
  ```
- [ ] Verify triggers exist:
  ```sql
  SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema = 'public';
  -- Should show multiple triggers
  ```
- [ ] Exit psql:
  ```sql
  \q
  ```

### Step 3: Update Code
- [ ] Code already updated (files modified in this session)
- [ ] Verify files exist:
  ```bash
  ls -la migrations/fix_all_logical_issues.sql
  ls -la src/utils/roles.js
  ls -la MIGRATION_GUIDE.md
  ```

### Step 4: Install Dependencies (if needed)
- [ ] Check if any new dependencies:
  ```bash
  npm install
  ```

---

## 🚀 DEPLOYMENT

### Start Server
- [ ] Start server:
  ```bash
  npm start
  ```
- [ ] Check for startup errors in console
- [ ] Verify server is running:
  ```bash
  curl http://localhost:3000/health
  ```
- [ ] Should return: `{"status":"ok",...}`

### Check Logs
- [ ] Open logs in separate terminal:
  ```bash
  tail -f logs/combined.log
  ```
- [ ] Look for any errors or warnings
- [ ] Verify no migration-related errors

---

## 🧪 TESTING

### Test 1: Health Check
- [ ] Open browser or Postman
- [ ] GET `http://localhost:3000/health`
- [ ] Should return 200 OK with status

### Test 2: Login (Existing User)
- [ ] POST `http://localhost:3000/api/v1/auth/login`
  ```json
  {
    "username": "owner",
    "password": "Admin123!"
  }
  ```
- [ ] Should return 200 OK
- [ ] Response should have `roles` array (not `role`)
- [ ] JWT token should contain `roles` field
- [ ] Copy accessToken for next tests

### Test 3: Get Profile
- [ ] GET `http://localhost:3000/api/v1/clients/profile`
- [ ] Headers: `Authorization: Bearer <accessToken>`
- [ ] Should return 200 OK
- [ ] Response should have `roles` array
- [ ] Should NOT have `latitude`/`longitude` fields
- [ ] Should have `home_latitude`/`home_longitude`

### Test 4: Create Delivery Request
- [ ] POST `http://localhost:3000/api/v1/deliveries/request`
- [ ] Headers: `Authorization: Bearer <accessToken>`
  ```json
  {
    "requested_gallons": 100,
    "payment_method": "cash",
    "priority": "non_urgent"
  }
  ```
- [ ] Should return 201 Created (if client account)
- [ ] Or appropriate error if not client

### Test 5: System Config
- [ ] Connect to database:
  ```bash
  psql -U postgres -d einhod_water
  ```
- [ ] Check config:
  ```sql
  SELECT * FROM system_config;
  ```
- [ ] Update a value:
  ```sql
  UPDATE system_config SET value = '5' WHERE key = 'max_pending_requests';
  ```
- [ ] Verify update:
  ```sql
  SELECT * FROM system_config WHERE key = 'max_pending_requests';
  ```
- [ ] Exit:
  ```sql
  \q
  ```

### Test 6: Multiple Roles (Optional)
- [ ] Create test user with multiple roles:
  ```sql
  INSERT INTO users (username, phone_number, password_hash, roles)
  VALUES ('test_dual', '+9999999999', '$2b$12$...', ARRAY['client', 'delivery_worker']::user_role[]);
  ```
- [ ] Login with test user
- [ ] Verify JWT contains both roles

### Test 7: Atomic Operations (Optional)
- [ ] Test coupon deduction:
  ```sql
  SELECT use_coupons(1, 5);
  -- Should return true if client has enough coupons
  ```
- [ ] Test vehicle inventory:
  ```sql
  SELECT update_vehicle_inventory(1, -100);
  -- Should succeed if worker has enough inventory
  ```

---

## 📊 VERIFICATION

### Database Integrity
- [ ] Check for any constraint violations:
  ```sql
  SELECT conname, conrelid::regclass 
  FROM pg_constraint 
  WHERE contype = 'c' AND connamespace = 'public'::regnamespace;
  ```
- [ ] Run ANALYZE to update statistics:
  ```sql
  ANALYZE;
  ```

### Performance Check
- [ ] Run sample query with EXPLAIN:
  ```sql
  EXPLAIN ANALYZE 
  SELECT * FROM delivery_requests 
  WHERE client_id = 1 AND status = 'pending';
  ```
- [ ] Should use index `idx_delivery_requests_client_status`

### Error Logs
- [ ] Check error log:
  ```bash
  tail -50 logs/error.log
  ```
- [ ] Should have no new errors after migration

---

## 📝 POST-APPLICATION

### Documentation
- [ ] Update API documentation with new field names
- [ ] Update team wiki/docs with changes
- [ ] Share `DEVELOPER_QUICK_REFERENCE.md` with team

### Monitoring
- [ ] Monitor server for next 24 hours
- [ ] Check logs regularly
- [ ] Monitor database performance
- [ ] Watch for any user-reported issues

### Cleanup
- [ ] Remove old backup files after 7 days (if all is well)
- [ ] Archive migration documentation

---

## 🔄 ROLLBACK (If Needed)

### If Issues Occur
- [ ] Stop server:
  ```bash
  # Press Ctrl+C or kill process
  ```
- [ ] Restore database:
  ```bash
  psql -U postgres -d einhod_water < backup_YYYYMMDD_HHMMSS.sql
  ```
- [ ] Revert code:
  ```bash
  git reset --hard pre-migration-backup
  ```
- [ ] Restart server:
  ```bash
  npm start
  ```
- [ ] Verify rollback successful
- [ ] Investigate issues before re-attempting

---

## ✅ COMPLETION

### Final Checks
- [ ] All tests passing
- [ ] No errors in logs
- [ ] Server running stable
- [ ] Team notified of completion
- [ ] Documentation updated
- [ ] Backup verified and stored

### Sign-off
- [ ] Applied by: ________________
- [ ] Date/Time: ________________
- [ ] Issues encountered: ________________
- [ ] Resolution: ________________
- [ ] Status: ☐ Success  ☐ Partial  ☐ Rolled Back

---

## 📞 SUPPORT

### If You Need Help
1. Check logs: `logs/combined.log`, `logs/error.log`
2. Review error messages carefully
3. Check database connection
4. Verify migration completed fully
5. Consult `MIGRATION_GUIDE.md`
6. Contact: [Your support contact]

### Common Issues

**Issue:** "column role does not exist"  
**Solution:** Migration didn't complete. Re-run migration script.

**Issue:** "invalid input syntax for type user_role[]"  
**Solution:** Check data format in queries, should use ARRAY syntax.

**Issue:** "function use_coupons does not exist"  
**Solution:** Migration didn't create functions. Check migration output for errors.

**Issue:** JWT tokens invalid  
**Solution:** Users need to re-login to get new token format with roles array.

---

## 🎉 SUCCESS CRITERIA

Migration is successful when:
- ✅ Server starts without errors
- ✅ Health check returns OK
- ✅ Login works and returns roles array
- ✅ Profile endpoint works
- ✅ Delivery requests work
- ✅ No errors in logs
- ✅ Database queries use new indexes
- ✅ All tests pass

---

**Prepared by:** AI Assistant  
**Version:** 1.0  
**Last Updated:** 2026-02-28

**IMPORTANT:** Do not skip any steps. If any step fails, STOP and investigate before proceeding.
