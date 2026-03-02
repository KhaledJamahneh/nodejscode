// scripts/migrate-multiple-roles.js
require('dotenv').config();
const { query } = require('../src/config/database');

async function migrate() {
  console.log('🚀 Starting migration for multiple roles...');

  try {
    // 1. Check current column type
    const checkType = await query(`
      SELECT data_type, udt_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'role'
    `);

    if (checkType.rows.length === 0) {
      console.error('❌ Table users or column role not found.');
      process.exit(1);
    }

    const column = checkType.rows[0];
    if (column.data_type === 'ARRAY') {
      console.log('✅ Role column is already an array. Skipping migration.');
      process.exit(0);
    }

    console.log('📦 Converting role column to user_role array...');

    // 2. Alter column to array
    await query(`
      ALTER TABLE users 
      ALTER COLUMN role TYPE user_role[] 
      USING ARRAY[role]::user_role[]
    `);

    console.log('✅ Role column converted to user_role[].');
    console.log('✨ Migration complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
