// Run migration to add preferred_language to worker_profiles
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function runMigration() {
  try {
    console.log('Adding preferred_language column to worker_profiles...');
    
    await pool.query(`
      ALTER TABLE worker_profiles 
      ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en'
    `);
    
    console.log('✅ Migration completed successfully!');
    
    // Verify
    const result = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'worker_profiles' 
      AND column_name = 'preferred_language'
    `);
    
    if (result.rows.length > 0) {
      console.log('✅ Column preferred_language exists in worker_profiles');
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

runMigration();
