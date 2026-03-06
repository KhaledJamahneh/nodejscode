const { query } = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('Running debt tracking migration...');
    
    const migrationPath = path.join(__dirname, '../database/migrations/add_debt_tracking.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    await query(sql);
    
    console.log('✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
