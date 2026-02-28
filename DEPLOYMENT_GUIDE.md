# Quick Fix Deployment Guide

## What Was Fixed

1. **PostgreSQL Role Array Error** - Client profile queries now work correctly
2. **Missing Notification Routes** - `/api/v1/notifications/unread-count` now works

## Deploy to Render

### Option 1: Git Push (Recommended)
```bash
git add .
git commit -m "fix: PostgreSQL role array comparison and notification routes"
git push origin main
```
Render will auto-deploy.

### Option 2: Manual Redeploy
1. Go to Render Dashboard
2. Select your service
3. Click "Manual Deploy" → "Deploy latest commit"

## Test After Deployment

### Test 1: Client Profile (Fixed)
```bash
# Login as client user
curl -X POST https://nodejscode-33ip.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"home","password":"YOUR_PASSWORD"}'

# Get profile (should work now)
curl https://nodejscode-33ip.onrender.com/api/v1/clients/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test 2: Notification Count (Fixed)
```bash
# Get unread count (should return 200, not 404)
curl https://nodejscode-33ip.onrender.com/api/v1/notifications/unread-count \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Expected Results

✅ Client profile: Returns 200 with profile data  
✅ Notification count: Returns 200 with `{"success": true, "data": {"unread_count": 0}}`  
✅ No more "malformed array literal" errors  
✅ No more 404 on notification routes

## Rollback (if needed)

```bash
git revert HEAD
git push origin main
```
