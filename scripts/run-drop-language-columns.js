const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DB_ALLOW_INSECURE_SSL === 'true' 
    ? { rejectUnauthorized: false }
    : { rejectUnauthorized: true }
});

async function runMigration() {
  const client = await pool.connect();
  
  try {
    console.log('Starting migration: Drop redundant language columns...\n');
    
    // Check if column exists
    const checkColumn = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'client_profiles' 
      AND column_name = 'preferred_language'
    `);
    
    if (checkColumn.rows.length === 0) {
      console.log('✅ Column already dropped - migration not needed');
      return;
    }
    
    console.log('Found redundant column: client_profiles.preferred_language');
    
    // Drop the column
    await client.query('ALTER TABLE client_profiles DROP COLUMN preferred_language');
    
    console.log('✅ Dropped client_profiles.preferred_language');
    console.log('\n✅ Migration completed successfully!');
    console.log('Single source of truth: users.preferred_language');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
