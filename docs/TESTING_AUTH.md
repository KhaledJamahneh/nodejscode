# Authentication & Authorization Test Suite

## Overview
Automated tests for User Authentication and Authorization scenarios covering login, registration, role-based access, and security features.

## Test Scenarios Covered

### 1.1 Standard Login Flow ✅
- Valid credentials login
- JWT token issuance
- Role embedding in token
- Profile access with token

### 1.2 Multi-Role Login ✅
- Multiple roles handling
- Role priority verification
- Access to multiple endpoints

### 1.3 Invalid Credentials ✅
- Incorrect password rejection
- Non-existent user handling
- 401 Unauthorized responses

### 1.4 Password Reset via Verification Code ✅
- Reset request generation
- Code validation
- Password update with bcrypt

### 1.5 JWT Refresh ✅
- Access token refresh
- Refresh token validation
- Token expiry handling

### 1.6 Role-Based Access Denial ✅
- Client denied admin access (403)
- Admin allowed admin access
- Middleware authorization checks

### 1.7 Creative: Role Escalation Attempt ✅
- Tampered JWT rejection
- Signature verification
- Security breach detection

### 1.8 Session Persistence ✅
- Token reuse across requests
- Session consistency
- User identity maintenance

## Running Tests

### Prerequisites
```bash
# Install dependencies
npm install

# Setup test database (optional - uses production DB for now)
npm run db:setup
```

### Run All Tests
```bash
npm test
```

### Run Specific Test Suite
```bash
npm test -- auth.test.js
```

### Run with Coverage
```bash
npm test -- --coverage
```

### Watch Mode
```bash
npm test -- --watch
```

## Test Data

### Test Users Created
- **testclient**: Client role user for testing
- **khaled**: Existing multi-role user (admin + onsite_worker)

### Cleanup
Tests automatically clean up created data in `afterAll()` hooks.

## Expected Results

All tests should pass with:
- ✅ 200 OK for successful operations
- ✅ 401 Unauthorized for invalid auth
- ✅ 403 Forbidden for role violations
- ✅ JWT tokens properly formatted
- ✅ Roles array correctly populated

## Notes

1. **Database**: Currently uses production database. For safety, create separate test DB.
2. **Rate Limiting**: May trigger if running tests repeatedly. Wait or disable in test env.
3. **Verification Codes**: Mock codes used (123456). Check logs for actual codes.
4. **Existing Users**: Tests assume 'khaled' user exists with admin role.

## Future Enhancements

- [ ] Separate test database
- [ ] Mock SMS service for verification codes
- [ ] Rate limiting bypass for tests
- [ ] Haptic feedback testing (frontend)
- [ ] Confetti animation testing (frontend)
- [ ] Arabic/RTL testing (frontend)
- [ ] Integration with CI/CD pipeline

## Troubleshooting

### Tests Failing?
1. Check `.env.test` configuration
2. Verify database connection
3. Ensure test user doesn't already exist
4. Check JWT secrets match

### Database Errors?
```bash
# Reset test database
npm run db:setup
npm run db:seed
```

### Token Errors?
- Verify JWT_SECRET in .env.test
- Check token expiry times
- Ensure bcrypt rounds are consistent

## Related Files
- `src/__tests__/auth.test.js` - Test suite
- `src/controllers/auth.controller.js` - Auth logic
- `src/middleware/auth.middleware.js` - Auth middleware
- `jest.config.js` - Jest configuration
- `.env.test` - Test environment variables
