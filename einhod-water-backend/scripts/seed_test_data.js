const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'einhod_water',
  password: 'postgres',
  port: 5432,
});

const firstNames = ['Ahmad', 'Mohammed', 'Ali', 'Hassan', 'Omar', 'Khalid', 'Youssef', 'Ibrahim', 'Mahmoud', 'Tariq', 'Fatima', 'Aisha', 'Maryam', 'Layla', 'Noor', 'Sara', 'Huda', 'Amina', 'Zainab', 'Rania'];
const lastNames = ['Al-Masri', 'Al-Khalil', 'Abu-Salem', 'Mansour', 'Nasser', 'Qasim', 'Haddad', 'Khoury', 'Saleh', 'Farah', 'Awad', 'Daher', 'Jabr', 'Karam', 'Musa', 'Najjar', 'Odeh', 'Rashid', 'Taha', 'Zahra'];
const cities = ['Ramallah', 'Nablus', 'Hebron', 'Bethlehem', 'Jenin', 'Tulkarm', 'Qalqilya', 'Jericho'];
const streets = ['Main St', 'Market St', 'Jerusalem Rd', 'Manara Sq', 'Old City', 'Al-Bireh', 'Ein Sara', 'Al-Masyoun'];

function randomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomPhone() {
  return `+970${Math.floor(Math.random() * 900000000 + 100000000)}`;
}

function randomCoordinate(base, range) {
  return (base + (Math.random() * range - range / 2)).toFixed(6);
}

async function seedData() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const hashedPassword = await bcrypt.hash('password123', 10);
    
    console.log('Creating 100 clients...');
    for (let i = 1; i <= 100; i++) {
      const firstName = randomItem(firstNames);
      const lastName = randomItem(lastNames);
      const username = `client${i}`;
      const email = `${username}@test.com`;
      const phone = randomPhone();
      const fullName = `${firstName} ${lastName}`;
      const city = randomItem(cities);
      const street = randomItem(streets);
      const address = `${Math.floor(Math.random() * 200 + 1)} ${street}, ${city}`;
      const lat = randomCoordinate(31.9, 0.5);
      const lng = randomCoordinate(35.2, 0.5);
      
      // Create user
      const userResult = await client.query(
        `INSERT INTO users (username, email, password_hash, phone_number, role, is_active) 
         VALUES ($1, $2, $3, $4, $5, true) 
         RETURNING id`,
        [username, email, hashedPassword, phone, ['client']]
      );
      const userId = userResult.rows[0].id;
      
      // Create client profile
      const subscriptionType = Math.random() > 0.5 ? 'coupon_book' : 'cash';
      const remainingCoupons = subscriptionType === 'coupon_book' ? Math.floor(Math.random() * 200 + 50) : 0;
      const currentDebt = Math.random() > 0.7 ? (Math.random() * 500).toFixed(2) : 0;
      
      await client.query(
        `INSERT INTO client_profiles 
         (user_id, full_name, address, subscription_type, remaining_coupons, current_debt, home_latitude, home_longitude) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [userId, fullName, address, subscriptionType, remainingCoupons, currentDebt, lat, lng]
      );
      
      if (i % 10 === 0) console.log(`Created ${i} clients...`);
    }
    
    console.log('Creating 100 workers...');
    for (let i = 1; i <= 100; i++) {
      const firstName = randomItem(firstNames);
      const lastName = randomItem(lastNames);
      const username = `worker${i}`;
      const email = `${username}@test.com`;
      const phone = randomPhone();
      const fullName = `${firstName} ${lastName}`;
      
      // Create user
      const workerType = i <= 70 ? 'delivery' : 'onsite';
      const role = i <= 70 ? 'delivery_worker' : 'onsite_worker';
      
      const userResult = await client.query(
        `INSERT INTO users (username, email, password_hash, phone_number, role, is_active) 
         VALUES ($1, $2, $3, $4, $5, true) 
         RETURNING id`,
        [username, email, hashedPassword, phone, [role]]
      );
      const userId = userResult.rows[0].id;
      
      // Create worker profile
      const salary = workerType === 'delivery' ? (Math.random() * 1000 + 2000).toFixed(2) : (Math.random() * 800 + 1500).toFixed(2);
      
      await client.query(
        `INSERT INTO worker_profiles 
         (user_id, full_name, worker_type, current_salary, hire_date) 
         VALUES ($1, $2, $3, $4, CURRENT_DATE)`,
        [userId, fullName, workerType, salary]
      );
      
      if (i % 10 === 0) console.log(`Created ${i} workers...`);
    }
    
    await client.query('COMMIT');
    console.log('✅ Successfully created 100 clients and 100 workers!');
    console.log('Default password for all users: password123');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error seeding data:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

seedData();
