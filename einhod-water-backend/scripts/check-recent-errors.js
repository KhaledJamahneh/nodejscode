require('dotenv').config();
const { Client } = require('pg');

async function checkErrors() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  
  try {
    // Check if there's an error log table
    const result = await client.query(`
      SELECT message, level, timestamp, meta
      FROM logs
      WHERE level = 'error' AND timestamp > NOW() - INTERVAL '10 minutes'
      ORDER BY timestamp DESC
      LIMIT 5
    `).catch(() => ({ rows: [] }));
    
    if (result.rows.length > 0) {
      console.log('Recent errors:');
      result.rows.forEach(r => console.log(r));
    } else {
      console.log('No error logs found in database');
    }
  } catch (e) {
    console.log('Could not query logs:', e.message);
  } finally {
    await client.end();
    process.exit(0);
  }
}

checkErrors();
