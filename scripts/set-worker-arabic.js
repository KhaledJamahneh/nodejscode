// Set worker language to Arabic
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function setWorkerLanguage() {
  try {
    // Get first delivery worker
    const worker = await pool.query(`
      SELECT u.id, u.username, wp.id as worker_id, wp.preferred_language
      FROM users u
      JOIN worker_profiles wp ON u.id = wp.user_id
      WHERE 'delivery_worker' = ANY(u.role)
      LIMIT 1
    `);
    
    if (worker.rows.length === 0) {
      console.log('No delivery workers found');
      await pool.end();
      return;
    }
    
    const w = worker.rows[0];
    console.log(`\nFound worker: ${w.username} (current language: ${w.preferred_language})`);
    
    // Update to Arabic
    await pool.query(`
      UPDATE worker_profiles 
      SET preferred_language = 'ar' 
      WHERE id = $1
    `, [w.worker_id]);
    
    console.log(`✅ Updated ${w.username} language to Arabic (ar)`);
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

setWorkerLanguage();
