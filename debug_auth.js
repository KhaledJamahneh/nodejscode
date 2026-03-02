
const bcrypt = require('bcrypt');
const { query } = require('./src/config/database');
require('dotenv').config();

async function debug() {
    const username = 'creative_client';
    const password = 'TestPass123!';
    
    const result = await query("SELECT * FROM users WHERE username = $1", [username]);
    if (result.rows.length === 0) {
        console.log('User not found');
        return;
    }
    
    const user = result.rows[0];
    console.log('User found:', user.username);
    console.log('Stored Hash:', user.password_hash);
    console.log('Is Active:', user.is_active);
    console.log('Role:', user.role);
    
    const isValid = await bcrypt.compare(password, user.password_hash);
    console.log('Password valid in debug script:', isValid);
    
    const rounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    console.log('System BCRYPT_ROUNDS:', rounds);
}

debug();
