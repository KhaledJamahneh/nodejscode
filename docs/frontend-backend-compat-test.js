const axios = require('axios');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const BASE_URL = (process.env.API_URL || 'http://localhost:3000') + '/api/v1';
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const results = { passed: 0, failed: 0, details: [] };

const log = (test, status, message) => {
  const result = { test, status, message };
  results.details.push(result);
  if (status === 'PASS') results.passed++;
  else results.failed++;
  console.log(`[${status}] ${test}: ${message}`);
};

const api = axios.create({ baseURL: BASE_URL, validateStatus: () => true });

async function setupTestUser(username, role) {
  await pool.query('DELETE FROM users WHERE username = $1', [username]);
  const dbRole = role === 'worker' ? ['delivery_worker'] : [role];
  const phone = `+9725${Math.floor(Math.random() * 10000000).toString().padStart(7, '0')}`;
  const passwordHash = await bcrypt.hash('Secure123!', 10);

  const userRes = await pool.query(
    'INSERT INTO users (username, phone_number, password_hash, role, is_active) VALUES ($1, $2, $3, $4, $5) RETURNING id',
    [username, phone, passwordHash, dbRole, true]
  );
  const userId = userRes.rows[0].id;

  if (role === 'client') {
    const cpRes = await pool.query(
      `INSERT INTO client_profiles (user_id, full_name, address, subscription_type)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [userId, username, 'Test Address', 'cash']
    );
    return { userId, profileId: cpRes.rows[0].id };
  } else if (role === 'worker') {
    const wpRes = await pool.query(
      `INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [userId, username, 'delivery', new Date()]
    );
    return { userId, profileId: wpRes.rows[0].id };
  }
  return { userId };
}

// ─── COMPATIBILITY TESTS ──────────────────────────────────────────────────

async function test1_LoginResponseStructure() {
  const testName = '1. Login Response Structure';
  try {
    const username = 'compat_client';
    await setupTestUser(username, 'client');
    
    const res = await api.post('/auth/login', { username, password: 'Secure123!' });
    
    // Frontend expects: response.data['data']['accessToken']
    // Frontend expects: response.data['data']['user']['roles']
    const data = res.data.data;
    if (!data) {
      log(testName, 'FAIL', 'Response missing nested "data" object');
      return;
    }
    
    if (data.accessToken && data.user && Array.isArray(data.user.roles)) {
      log(testName, 'PASS', 'Structure matches frontend AuthService expectation');
    } else {
      log(testName, 'FAIL', `Structure mismatch: ${JSON.stringify(res.data)}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function test2_DeliveryRequestsListStructure() {
  const testName = '2. Delivery Requests List Structure';
  try {
    const username = 'compat_client_list';
    const { userId, profileId } = await setupTestUser(username, 'client');
    const loginRes = await api.post('/auth/login', { username, password: 'Secure123!' });
    const token = loginRes.data.data.accessToken;

    // Create a request first
    await pool.query(
      'INSERT INTO delivery_requests (client_id, requested_gallons, status) VALUES ($1, $2, $3)',
      [profileId, 100, 'pending']
    );

    const res = await api.get('/deliveries/requests', { headers: { Authorization: `Bearer ${token}` } });
    
    // Frontend expects: response.data['data']['requests'] as a List
    const data = res.data.data;
    if (data && Array.isArray(data.requests)) {
      log(testName, 'PASS', 'Requests list structure matches ClientService expectation');
    } else {
      log(testName, 'FAIL', `Structure mismatch: ${JSON.stringify(res.data)}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function test3_WorkerProfileStructure() {
  const testName = '3. Worker Profile Structure';
  try {
    const username = 'compat_worker';
    await setupTestUser(username, 'worker');
    const loginRes = await api.post('/auth/login', { username, password: 'Secure123!' });
    const token = loginRes.data.data.accessToken;

    const res = await api.get('/workers/profile', { headers: { Authorization: `Bearer ${token}` } });
    
    // Frontend expects: response.data['data'] as a Map (the profile object itself)
    const data = res.data.data;
    if (data && data.full_name === username) {
      log(testName, 'PASS', 'Worker profile structure matches WorkerService expectation');
    } else {
      log(testName, 'FAIL', `Structure mismatch: ${JSON.stringify(res.data)}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function test4_ErrorPropagation() {
  const testName = '4. Error Message Propagation';
  try {
    // Attempt login with wrong password
    const res = await api.post('/auth/login', { username: 'nonexistent', password: 'wrong' });
    
    // Frontend expects: response.data['message']
    if (res.data.success === false && typeof res.data.message === 'string') {
      log(testName, 'PASS', 'Error message structure matches frontend expectation');
    } else {
      log(testName, 'FAIL', `Error structure mismatch: ${JSON.stringify(res.data)}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function test5_CouponDeliveryRequest() {
  const testName = '5. Coupon Delivery Request';
  try {
    const username = 'compat_coupon_client';
    const { userId, profileId } = await setupTestUser(username, 'client');
    
    // Give some coupons
    await pool.query('UPDATE client_profiles SET remaining_coupons = 10, subscription_type = $1 WHERE id = $2', ['coupon_book', profileId]);
    
    const loginRes = await api.post('/auth/login', { username, password: 'Secure123!' });
    const token = loginRes.data.data.accessToken;

    // Frontend ClientService.createRequest: requested_gallons, payment_method
    const res = await api.post('/deliveries/request', 
      { requested_gallons: 100, payment_method: 'coupon_book' }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.status === 201) {
      const profile = await pool.query('SELECT remaining_coupons FROM client_profiles WHERE id = $1', [profileId]);
      if (profile.rows[0].remaining_coupons === 5) { // 100 / 20 = 5 coupons deducted
        log(testName, 'PASS', 'Coupon delivery request created and coupons deducted');
      } else {
        log(testName, 'FAIL', `Expected 5 coupons remaining, got ${profile.rows[0].remaining_coupons}`);
      }
    } else {
      log(testName, 'FAIL', `Expected 201, got ${res.status}: ${JSON.stringify(res.data)}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function runAll() {
  console.log('--- STARTING FRONTEND-BACKEND COMPATIBILITY TESTS ---\n');
  
  await test1_LoginResponseStructure();
  await test2_DeliveryRequestsListStructure();
  await test3_WorkerProfileStructure();
  await test4_ErrorPropagation();
  await test5_CouponDeliveryRequest();
  
  console.log('\n--- FINAL RESULTS ---');
  console.log(`Passed: ${results.passed}/${results.passed + results.failed}`);
  console.log(`Failed: ${results.failed}/${results.passed + results.failed}`);
  
  await pool.end();
}

runAll().catch(console.error);
