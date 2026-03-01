require('dotenv').config();
const { query } = require('../src/config/database');

async function addColumn() {
  try {
    console.log('Checking if available_stock column exists...');
    
    const check = await query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'coupon_sizes' 
      AND column_name = 'available_stock'
    `);
    
    if (check.rows.length > 0) {
      console.log('✓ Column available_stock already exists');
    } else {
      console.log('Adding available_stock column...');
      await query('ALTER TABLE coupon_sizes ADD COLUMN available_stock INTEGER DEFAULT 100');
      console.log('✓ Column added successfully');
    }
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

addColumn();
