#!/bin/bash
# Test notifications endpoint after deployment

echo "🔍 Testing Notifications Endpoint"
echo "=================================="
echo ""

# Get admin user's notifications
echo "📬 Checking admin user notifications..."
echo ""

cd einhod-water-backend

# Query database directly
node -e "
require('dotenv').config();
const { query } = require('./src/config/database');

(async () => {
  try {
    // Get admin user
    const user = await query(\"SELECT id, username, role FROM users WHERE username = 'admin' LIMIT 1\");
    if (user.rows.length === 0) {
      console.log('❌ Admin user not found');
      process.exit(1);
    }
    
    const userId = user.rows[0].id;
    console.log('✅ User:', user.rows[0].username, '| Roles:', user.rows[0].role);
    console.log('');
    
    // Get notifications
    const notifs = await query(\`
      SELECT id, type, title, message, is_read, created_at
      FROM notifications
      WHERE user_id = \$1
      ORDER BY created_at DESC
      LIMIT 5
    \`, [userId]);
    
    console.log('📬 Notifications (' + notifs.rows.length + '):');
    console.log('');
    
    notifs.rows.forEach((n, i) => {
      console.log(\`\${i+1}. [\${n.type}] \${n.title}\`);
      console.log(\`   \${n.message}\`);
      console.log(\`   \${n.is_read ? '✓ Read' : '● Unread'} | \${n.created_at}\`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
})();
" 2>&1 | grep -v "Warning:" | grep -v "info\|debug"
