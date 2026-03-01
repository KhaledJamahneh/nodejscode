require('dotenv').config();
const { query } = require('../src/config/database');

async function checkNotifications() {
  try {
    const result = await query(`
      SELECT n.id, n.user_id, u.username, n.type, n.title, n.is_read, n.created_at
      FROM notifications n
      JOIN users u ON n.user_id = u.id
      ORDER BY n.created_at DESC
      LIMIT 20
    `);
    
    console.log('\n📬 Recent Notifications:\n');
    result.rows.forEach(row => {
      console.log(`${row.is_read ? '✓' : '●'} [${row.type}] ${row.username}: ${row.title}`);
      console.log(`   Created: ${row.created_at}\n`);
    });
    
    console.log(`Total: ${result.rows.length} notifications\n`);
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

checkNotifications();
