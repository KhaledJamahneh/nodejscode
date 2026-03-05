// Run this script directly to add payment columns
// Usage: node scripts/add-payment-columns.js

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function migrate() {
  try {
    console.log('Starting migration...');
    
    const result = await pool.query(`
      ALTER TABLE deliveries 
      ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS total_price DECIMAL(10, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS paid_coupons_count INTEGER DEFAULT 0
    `);
    
    console.log('✅ Migration completed successfully!');
    console.log('Columns added: paid_amount, total_price, paid_coupons_count');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
