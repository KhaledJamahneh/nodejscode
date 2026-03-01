// Show all tables with their columns
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function showAllTablesWithColumns() {
  try {
    // Get all tables
    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    console.log('\n=== DATABASE SCHEMA ===\n');
    
    for (const table of tables.rows) {
      const tableName = table.table_name;
      
      // Get columns for this table
      const columns = await pool.query(`
        SELECT column_name, data_type, character_maximum_length, column_default, is_nullable
        FROM information_schema.columns 
        WHERE table_name = $1
        ORDER BY ordinal_position
      `, [tableName]);
      
      console.log(`\n📋 ${tableName.toUpperCase()}`);
      console.log('─'.repeat(80));
      
      columns.rows.forEach((col) => {
        const type = col.character_maximum_length 
          ? `${col.data_type}(${col.character_maximum_length})`
          : col.data_type;
        const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
        const def = col.column_default ? ` DEFAULT ${col.column_default}` : '';
        console.log(`  ${col.column_name.padEnd(30)} ${type.padEnd(20)} ${nullable}${def}`);
      });
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

showAllTablesWithColumns();
