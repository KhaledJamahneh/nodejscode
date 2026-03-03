# Language Storage Consolidation

## Problem
Language preference is stored in multiple places:
- `client_profiles.preferred_language`
- `worker_profiles.preferred_language`

This creates conflicts for dual-role users (workers who are also clients).

## Solution
Move `preferred_language` to `users` table as the single source of truth.

## Migration Steps

### 1. Add language to users table
```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en';
```

### 2. Migrate existing data
```sql
-- Copy from client_profiles
UPDATE users u
SET preferred_language = cp.preferred_language
FROM client_profiles cp
WHERE u.id = cp.user_id 
AND cp.preferred_language IS NOT NULL;

-- Copy from worker_profiles (overwrites if dual role)
UPDATE users u
SET preferred_language = wp.preferred_language
FROM worker_profiles wp
WHERE u.id = wp.user_id 
AND wp.preferred_language IS NOT NULL;
```

### 3. Update application code
Change all queries from:
```javascript
// OLD
SELECT wp.preferred_language FROM worker_profiles wp WHERE wp.user_id = $1
SELECT cp.preferred_language FROM client_profiles cp WHERE cp.user_id = $1
```

To:
```javascript
// NEW
SELECT u.preferred_language FROM users u WHERE u.id = $1
```

### 4. (Optional) Remove redundant columns
```sql
ALTER TABLE client_profiles DROP COLUMN IF EXISTS preferred_language;
ALTER TABLE worker_profiles DROP COLUMN IF EXISTS preferred_language;
```

## Benefits
- Single source of truth
- No conflicts for dual-role users
- Simpler queries
- Consistent language across all user interactions
