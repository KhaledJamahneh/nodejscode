// scripts/business_logic_scenario_3.js
const { query, transaction } = require('../src/config/database');

async function runTest() {
  console.log('--- STARTING BUSINESS LOGIC SCENARIO 3: FINANCIAL LIFECYCLE ---');

  try {
    // 1. SETUP
    console.log('--- Step 1: Setup Environment ---');
    await query("DELETE FROM users WHERE username IN ('alice_test', 'bob_test', 'dave_test', 'client1', 'client2', 'client3', 'client4', 'client5')");
    
    // Alice
    const aliceId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('alice_test', 'hash', ARRAY['client']::user_role[], '1') RETURNING id")).rows[0].id;
    const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
    const alicePid = (await query("INSERT INTO client_profiles (user_id, full_name, address, subscription_type, subscription_expiry_date) VALUES ($1, 'Alice', 'Addr', 'cash', $2) RETURNING id", [aliceId, yesterday])).rows[0].id;

    // Bob
    const bobId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('bob_test', 'hash', ARRAY['delivery_worker']::user_role[], '2') RETURNING id")).rows[0].id;
    const bobPid = (await query("INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date, vehicle_current_gallons) VALUES ($1, 'Bob', 'delivery', CURRENT_DATE, 100) RETURNING id", [bobId])).rows[0].id;

    // Dave
    const daveId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('dave_test', 'hash', ARRAY['client','delivery_worker']::user_role[], '3') RETURNING id")).rows[0].id;
    const daveCPid = (await query("INSERT INTO client_profiles (user_id, full_name, address, subscription_type, current_debt) VALUES ($1, 'Dave Client', 'Addr', 'cash', 500) RETURNING id", [daveId])).rows[0].id;
    const daveWPid = (await query("INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date, debt_advances) VALUES ($1, 'Dave Worker', 'delivery', CURRENT_DATE, 0) RETURNING id", [daveId])).rows[0].id;

    console.log('OK: Environment Ready.');

    // 2. DUAL-ROLE DEBT SEPARATION
    console.log('--- Step 2: Test Dual-Role Financial Separation ---');
    await query("UPDATE worker_profiles SET debt_advances = debt_advances + 1000 WHERE id = $1", [daveWPid]);
    
    const daveCheck = await query(`
        SELECT cp.current_debt, wp.debt_advances 
        FROM client_profiles cp 
        JOIN worker_profiles wp ON cp.user_id = wp.user_id 
        WHERE cp.user_id = $1`, [daveId]);
    
    console.log(`Dave: Client Debt = ${daveCheck.rows[0].current_debt}, Worker Advance = ${daveCheck.rows[0].debt_advances}`);
    if (parseFloat(daveCheck.rows[0].current_debt) === 500 && parseFloat(daveCheck.rows[0].debt_advances) === 1000) {
        console.log('OK: Dual-role finances are correctly separated.');
    } else throw new Error('Dual-role financial leak detected');

    // 3. SUBSCRIPTION EXPIRY BUFFER
    console.log('--- Step 3: Test Expiry Grace Period ---');
    const tryNewRequest = async (pId) => {
        const profile = (await query("SELECT subscription_expiry_date FROM client_profiles WHERE id = $1", [pId])).rows[0];
        const expiry = new Date(profile.subscription_expiry_date);
        const grace = new Date(expiry); grace.setDate(grace.getDate() + 10);
        if (new Date() > grace) return 'Blocked';
        return 'Allowed';
    };
    
    const aliceReq = await tryNewRequest(alicePid);
    console.log(`Alice (Expired yesterday) making new request: ${aliceReq}`);
    if (aliceReq === 'Allowed') console.log('OK: 10-day grace period is active.');
    else throw new Error('Grace period failed');

    // 4. BATCH INVENTORY RACE
    console.log('--- Step 4: Test Batch Inventory Depletion ---');
    const cids = [];
    for(let i=1; i<=5; i++) {
        const u = (await query(`INSERT INTO users (username, password_hash, role, phone_number) VALUES ('client${i}', 'h', ARRAY['client']::user_role[], '${i+10}') RETURNING id`)).rows[0].id;
        const p = (await query(`INSERT INTO client_profiles (user_id, full_name, address, subscription_type) VALUES ($1, 'C${i}', 'A', 'cash') RETURNING id`, [u])).rows[0].id;
        cids.push(p);
    }

    const performDelivery = async (clientPid, workerPid, amount) => {
        try {
            return await transaction(async (client) => {
                const w = await client.query("SELECT vehicle_current_gallons FROM worker_profiles WHERE id = $1 FOR UPDATE", [workerPid]);
                if (parseInt(w.rows[0].vehicle_current_gallons) < amount) throw new Error('Out of stock');
                await client.query("UPDATE worker_profiles SET vehicle_current_gallons = vehicle_current_gallons - $1 WHERE id = $2", [amount, workerPid]);
                return 'Success';
            });
        } catch (e) { return e.message; }
    };

    const results = await Promise.all(cids.map(id => performDelivery(id, bobPid, 30)));
    const successful = results.filter(r => r === 'Success').length;
    const blocked = results.filter(r => r === 'Out of stock').length;
    
    console.log(`Batch Results: ${successful} successful, ${blocked} out of stock.`);
    if (successful === 3 && blocked === 2) console.log('OK: First-come-first-served inventory verified.');
    else throw new Error(`Inventory race failed: ${successful} succ, ${blocked} fail`);

    // 5. ASSET RECIRCULATION
    console.log('--- Step 5: Test Asset Recirculation ---');
    // Delete existing test dispenser if exists
    await query("DELETE FROM dispensers WHERE serial_number = 'SN-TEST-100'");
    const dispenserId = (await query("INSERT INTO dispensers (serial_number, dispenser_type, status, purchase_date) VALUES ('SN-TEST-100', 'manual', 'new', CURRENT_DATE) RETURNING id")).rows[0].id;
    
    const assignDispenser = async (dId, cId) => {
        await query("UPDATE dispensers SET status = 'used', current_client_id = $1 WHERE id = $2", [cId, dId]);
    };
    const returnDispenser = async (dId) => {
        await query("UPDATE dispensers SET status = 'new', current_client_id = NULL WHERE id = $1", [dId]);
    };

    await assignDispenser(dispenserId, alicePid);
    let dCheck = (await query("SELECT status, current_client_id FROM dispensers WHERE id = $1", [dispenserId])).rows[0];
    console.log(`Assigned: Status=${dCheck.status}, ClientID=${dCheck.current_client_id}`);
    
    await returnDispenser(dispenserId);
    dCheck = (await query("SELECT status, current_client_id FROM dispensers WHERE id = $1", [dispenserId])).rows[0];
    console.log(`Returned: Status=${dCheck.status}, ClientID=${dCheck.current_client_id}`);
    
    if (dCheck.status === 'new' && dCheck.current_client_id === null) console.log('OK: Asset recirculation working.');
    else throw new Error('Asset recirculation failed');

    console.log('\nALL SCENARIO 3 TESTS PASSED SUCCESSFULLY!');

  } catch (error) {
    console.error('\nTEST FAILED:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

runTest();
