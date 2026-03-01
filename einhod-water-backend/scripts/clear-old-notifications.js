// scripts/clear-old-notifications.js
// Clear old English notifications so users see new localized ones

require('dotenv').config();
const { query } = require('../src/config/database');

async function clearOldNotifications() {
  try {
    console.log('🗑️  Clearing old English notifications...\n');

    // Delete all existing notifications
    const result = await query('DELETE FROM notifications WHERE created_at < NOW()');
    
    console.log(`✅ Deleted ${result.rowCount} old notifications`);
    console.log('✅ New notifications will be in user\'s preferred language\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

clearOldNotifications();
