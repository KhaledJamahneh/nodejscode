#!/bin/bash
# Monitor language changes in real-time

echo "🔍 Monitoring language changes..."
echo "Press Ctrl+C to stop"
echo ""

cd einhod-water-backend

while true; do
  clear
  echo "📊 Current Language Settings ($(date '+%H:%M:%S'))"
  echo "================================================"
  echo ""
  
  node -e "
  require('dotenv').config();
  const { query } = require('./src/config/database');
  query('SELECT username, role, preferred_language, last_login FROM users WHERE preferred_language IS NOT NULL ORDER BY last_login DESC NULLS LAST LIMIT 10')
    .then(r => {
      r.rows.forEach(u => {
        const lang = u.preferred_language === 'ar' ? '🇸🇦 Arabic' : '🇬🇧 English';
        const lastLogin = u.last_login ? new Date(u.last_login).toLocaleString() : 'Never';
        console.log(\`\${u.username.padEnd(20)} | \${lang.padEnd(12)} | Last: \${lastLogin}\`);
      });
      process.exit(0);
    });
  " 2>/dev/null
  
  sleep 3
done
