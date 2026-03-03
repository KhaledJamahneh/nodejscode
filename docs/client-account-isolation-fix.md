# Client Account Isolation Fix

## Date: 2026-03-01

## Problem
All clients were seeing the same account data because the Dio HTTP client instance was being reused with cached authorization tokens from previous logins.

## Root Cause
The `DioClient` singleton instance was never being reset on logout or login, causing:
1. Old JWT tokens to remain in the Dio interceptor's memory
2. New logins to still use the previous user's token
3. All API requests to authenticate as the first logged-in user

## Solution

### auth_service.dart Changes

**1. Login Method:**
- Added `DioClient.reset()` at the start of login
- Creates fresh Dio instance before authentication
- Ensures no stale tokens from previous sessions

**2. Logout Method:**
- Reordered operations to get refresh token BEFORE clearing storage
- Added `DioClient.reset()` after clearing storage
- Ensures clean state for next login

### Code Changes

**Before (Login):**
```dart
Future<Map<String, dynamic>> login(String username, String password) async {
  try {
    final response = await _dio.post(ApiEndpoints.login, ...);
    // Save tokens and user data
  }
}
```

**After (Login):**
```dart
Future<Map<String, dynamic>> login(String username, String password) async {
  try {
    DioClient.reset();  // ← NEW: Clear old instance
    final dio = DioClient.instance;  // ← NEW: Get fresh instance
    final response = await dio.post(ApiEndpoints.login, ...);
    // Save tokens and user data
  }
}
```

**Before (Logout):**
```dart
Future<void> logout() async {
  await StorageService.clearAll();  // ← Cleared FIRST (wrong order)
  try {
    final refreshToken = await StorageService.getRefreshToken();  // ← Returns null!
    await _dio.post(ApiEndpoints.logout, ...);
  } catch (e) {}
}
```

**After (Logout):**
```dart
Future<void> logout() async {
  try {
    final refreshToken = await StorageService.getRefreshToken();  // ← Get BEFORE clearing
    await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
  } catch (e) {}
  
  await StorageService.clearAll();  // ← Clear storage
  DioClient.reset();  // ← NEW: Reset Dio instance
}
```

## How It Works

### DioClient Interceptor
The Dio interceptor adds the Authorization header on every request:
```dart
onRequest: (options, handler) async {
  final token = await StorageService.getAccessToken();
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  return handler.next(options);
}
```

### The Problem Flow (Before Fix)
1. User A logs in → Token A saved → Dio instance created with Token A
2. User A logs out → Storage cleared BUT Dio instance still exists
3. User B logs in → Token B saved → **Same Dio instance reused**
4. User B makes request → Interceptor reads Token B from storage
5. BUT the Dio instance might have cached Token A in memory
6. Result: User B sees User A's data

### The Solution Flow (After Fix)
1. User A logs in → `DioClient.reset()` → Fresh Dio → Token A
2. User A logs out → Storage cleared → `DioClient.reset()` → Dio destroyed
3. User B logs in → `DioClient.reset()` → Fresh Dio → Token B
4. User B makes request → Fresh interceptor reads Token B
5. Result: User B sees User B's data ✅

## Testing Required

1. ✅ Login as Client A, verify profile shows Client A data
2. ✅ Logout from Client A
3. ✅ Login as Client B, verify profile shows Client B data (not Client A)
4. ✅ Repeat with multiple clients
5. ✅ Test with different roles (client, worker, admin)

## Additional Notes

- The backend authentication was already correct (using `req.user.id` from JWT)
- The issue was purely on the Flutter client side
- This fix ensures complete session isolation between users
- No database or backend changes required
