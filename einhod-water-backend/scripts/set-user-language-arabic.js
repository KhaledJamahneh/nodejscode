// scripts/set-user-language-arabic.js
// Set a specific user's preferred language to Arabic

require('dotenv').config();
const { query } = require('../src/config/database');

async function setUserLanguageToArabic() {
  try {
    // Get username from command line argument
    const username = process.argv[2];
    
    if (!username) {
      console.log('Usage: node scripts/set-user-language-arabic.js <username>');
      console.log('Example: node scripts/set-user-language-arabic.js testclient');
      process.exit(1);
    }

    // Check if user exists
    const userResult = await query(
      'SELECT id, username, preferred_language FROM users WHERE username = $1',
      [username]
    );

    if (userResult.rows.length === 0) {
      console.log(`❌ User '${username}' not found`);
      process.exit(1);
    }

    const user = userResult.rows[0];
    console.log(`\nFound user: ${user.username}`);
    console.log(`Current language: ${user.preferred_language || 'en'}`);

    // Update to Arabic
    await query(
      'UPDATE users SET preferred_language = $1 WHERE id = $2',
      ['ar', user.id]
    );

    console.log(`✅ Updated ${user.username}'s preferred language to Arabic (ar)\n`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

setUserLanguageToArabic();
