// Run language consolidation migration
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function consolidateLanguage() {
  try {
    console.log('🔄 Consolidating language preferences to users table...\n');
    
    // Read migration file
    const migrationSQL = fs.readFileSync(
      path.join(__dirname, '../migrations/consolidate_language.sql'),
      'utf8'
    );
    
    // Execute migration
    await pool.query(migrationSQL);
    
    console.log('✅ Migration completed successfully!\n');
    
    // Verify
    const stats = await pool.query(`
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN preferred_language = 'ar' THEN 1 END) as arabic_users,
        COUNT(CASE WHEN preferred_language = 'en' THEN 1 END) as english_users
      FROM users
    `);
    
    console.log('📊 Language Statistics:');
    console.log(`   Total users: ${stats.rows[0].total_users}`);
    console.log(`   Arabic: ${stats.rows[0].arabic_users}`);
    console.log(`   English: ${stats.rows[0].english_users}`);
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

consolidateLanguage();
