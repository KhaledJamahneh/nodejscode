/**
 * Test script for coupon book request fixes
 * Tests:
 * 1. Client creates physical coupon request (status: approved)
 * 2. Admin can see the request
 * 3. Worker can see the request in secondary list
 * 4. Client can cancel the request (before assignment)
 * 5. Client can edit the request (before assignment)
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';

let clientToken, adminToken, workerToken;
let couponRequestId;

async function login(username, password) {
  const response = await axios.post(`${BASE_URL}/auth/login`, {
    username,
    password
  });
  return response.data.data.accessToken;
}

async function test1_ClientCreatesCouponRequest() {
  console.log('\n=== Test 1: Client creates physical coupon request ===');
  try {
    const response = await axios.post(
      `${BASE_URL}/clients/coupon-book-request`,
      {
        book_type: 'physical',
        coupon_size_id: 1, // 100 pages
        payment_method: 'cash'
      },
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    
    couponRequestId = response.data.data.id;
    console.log('✓ Request created:', response.data.data);
    console.log('  Status:', response.data.data.status);
    return true;
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function test2_AdminSeesRequest() {
  console.log('\n=== Test 2: Admin can see the request ===');
  try {
    const response = await axios.get(
      `${BASE_URL}/admin/coupon-book-requests`,
      { headers: { Authorization: `Bearer ${adminToken}` } }
    );
    
    const found = response.data.data.requests.find(r => r.id === couponRequestId);
    if (found) {
      console.log('✓ Admin sees request:', found.id, 'Status:', found.status);
      return true;
    } else {
      console.error('✗ Request not found in admin view');
      return false;
    }
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function test3_WorkerSeesRequest() {
  console.log('\n=== Test 3: Worker can see the request ===');
  try {
    const response = await axios.get(
      `${BASE_URL}/workers/schedule/secondary`,
      { headers: { Authorization: `Bearer ${workerToken}` } }
    );
    
    const found = response.data.data.requests.find(
      r => r.id === couponRequestId && r.task_type === 'coupon_request'
    );
    if (found) {
      console.log('✓ Worker sees request:', found.id, 'Status:', found.status);
      return true;
    } else {
      console.error('✗ Request not found in worker secondary list');
      console.log('  Available requests:', response.data.data.requests.length);
      return false;
    }
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function test4_ClientEditsRequest() {
  console.log('\n=== Test 4: Client can edit the request ===');
  try {
    const response = await axios.patch(
      `${BASE_URL}/clients/coupon-books/${couponRequestId}`,
      {
        coupon_size_id: 2, // Change to 200 pages
        book_type: 'physical'
      },
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    
    console.log('✓ Request edited successfully');
    console.log('  New size:', response.data.data.coupon_size_id);
    return true;
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function test5_ClientCancelsRequest() {
  console.log('\n=== Test 5: Client can cancel the request ===');
  try {
    const response = await axios.delete(
      `${BASE_URL}/clients/coupon-books/${couponRequestId}`,
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    
    console.log('✓ Request cancelled successfully');
    return true;
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function test6_VerifyCancelled() {
  console.log('\n=== Test 6: Verify request is cancelled ===');
  try {
    const response = await axios.get(
      `${BASE_URL}/clients/coupon-book-requests`,
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    
    const found = response.data.data.find(r => r.id === couponRequestId);
    if (found && found.status === 'cancelled') {
      console.log('✓ Request status is cancelled');
      return true;
    } else {
      console.error('✗ Request not cancelled properly');
      return false;
    }
  } catch (error) {
    console.error('✗ Failed:', error.response?.data || error.message);
    return false;
  }
}

async function runTests() {
  console.log('Starting coupon request tests...\n');
  
  try {
    // Login
    console.log('Logging in...');
    clientToken = await login('client1', 'Client123!');
    adminToken = await login('owner', 'Admin123!');
    workerToken = await login('worker1', 'Worker123!');
    console.log('✓ All users logged in');
    
    // Run tests
    const results = [];
    results.push(await test1_ClientCreatesCouponRequest());
    results.push(await test2_AdminSeesRequest());
    results.push(await test3_WorkerSeesRequest());
    results.push(await test4_ClientEditsRequest());
    results.push(await test5_ClientCancelsRequest());
    results.push(await test6_VerifyCancelled());
    
    // Summary
    const passed = results.filter(r => r).length;
    const total = results.length;
    console.log(`\n${'='.repeat(50)}`);
    console.log(`Tests passed: ${passed}/${total}`);
    console.log(`${'='.repeat(50)}`);
    
    process.exit(passed === total ? 0 : 1);
  } catch (error) {
    console.error('\nFatal error:', error.message);
    process.exit(1);
  }
}

runTests();
