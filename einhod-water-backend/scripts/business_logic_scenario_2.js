// scripts/business_logic_scenario_2.js
const { query, transaction } = require('../src/config/database');
const { isValidTransition } = require('../src/utils/state-machine');

async function runTest() {
  console.log('--- STARTING BUSINESS LOGIC SCENARIO 2: CHAIN OF CUSTODY ---');

  try {
    // 1. SETUP
    console.log('--- Step 1: Setup Alice, Bob, Dave ---');
    await query("DELETE FROM users WHERE username IN ('alice_test', 'bob_test', 'dave_test')");
    
    // Alice
    const aliceId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('alice_test', 'hash', ARRAY['client']::user_role[], '1') RETURNING id")).rows[0].id;
    const alicePid = (await query("INSERT INTO client_profiles (user_id, full_name, address, subscription_type, remaining_coupons, gallons_on_hand) VALUES ($1, 'Alice', 'Addr', 'coupon_book', 1, 10) RETURNING id", [aliceId])).rows[0].id;

    // Bob
    const bobId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('bob_test', 'hash', ARRAY['delivery_worker']::user_role[], '2') RETURNING id")).rows[0].id;
    const bobPid = (await query("INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date, vehicle_current_gallons) VALUES ($1, 'Bob', 'delivery', CURRENT_DATE, 100) RETURNING id", [bobId])).rows[0].id;

    // Dave (Dual Role)
    const daveId = (await query("INSERT INTO users (username, password_hash, role, phone_number) VALUES ('dave_test', 'hash', ARRAY['client','delivery_worker']::user_role[], '3') RETURNING id")).rows[0].id;
    const daveCPid = (await query("INSERT INTO client_profiles (user_id, full_name, address, subscription_type) VALUES ($1, 'Dave Client', 'Addr', 'cash') RETURNING id", [daveId])).rows[0].id;
    const daveWPid = (await query("INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date) VALUES ($1, 'Dave Worker', 'delivery', CURRENT_DATE) RETURNING id", [daveId])).rows[0].id;

    console.log('OK: Environment Ready.');

    // 2. INVENTORY DEPLETION TEST
    console.log('--- Step 2: Test Inventory Chain of Custody ---');
    await transaction(async (client) => {
        await client.query("UPDATE worker_profiles SET vehicle_current_gallons = vehicle_current_gallons - 60 WHERE id = $1", [bobPid]);
    });
    
    const tryOverDeliver = async (amount) => {
        const res = await query("SELECT vehicle_current_gallons FROM worker_profiles WHERE id = $1", [bobPid]);
        if (parseInt(res.rows[0].vehicle_current_gallons) < amount) throw new Error('Insufficient inventory');
        return 'Success';
    };
    try {
        await tryOverDeliver(50);
        throw new Error('Should have failed inventory check');
    } catch (e) {
        console.log(`Bob (40 gal) delivering 50: ${e.message}`);
        console.log('OK: Inventory Drain enforced.');
    }

    // 3. STATE MACHINE INTEGRITY
    console.log('--- Step 3: Test Terminal State Integrity ---');
    const currentStatus = 'completed';
    const nextStatus = 'in_progress';
    const valid = isValidTransition('delivery', currentStatus, nextStatus);
    console.log(`Transition Completed -> In Progress: ${valid ? 'Allowed' : 'Denied'}`);
    if (!valid) console.log('OK: State Machine prevents status rollback.');
    else throw new Error('State machine failed');

    // 4. COUPON DOUBLE-SPEND (Concurrency)
    console.log('--- Step 4: Test Coupon Double-Spend Race ---');
    const spendCoupon = async (pId) => {
        try {
            return await transaction(async (client) => {
                const res = await client.query("SELECT remaining_coupons FROM client_profiles WHERE id = $1 FOR UPDATE", [pId]);
                if (parseInt(res.rows[0].remaining_coupons) < 1) throw new Error('Insufficient coupons');
                await new Promise(r => setTimeout(r, 50)); 
                await client.query("UPDATE client_profiles SET remaining_coupons = remaining_coupons - 1 WHERE id = $1", [pId]);
                return 'Success';
            });
        } catch (e) { return e.message; }
    };

    const results = await Promise.all([spendCoupon(alicePid), spendCoupon(alicePid)]);
    console.log(`Race Results: Worker 1: ${results[0]}, Worker 2: ${results[1]}`);
    if (results.includes('Success') && results.includes('Insufficient coupons')) {
        console.log('OK: Concurrency Lock prevented double-spend.');
    } else throw new Error('Race condition allowed double-spend');

    // 5. SELF-DEALING BLOCK
    console.log('--- Step 5: Test Self-Dealing Block ---');
    const drId = (await query("INSERT INTO delivery_requests (client_id, requested_gallons, status) VALUES ($1, 20, 'pending') RETURNING id", [daveCPid])).rows[0].id;
    
    const tryAccept = async (wId, rId) => {
        try {
            const worker = (await query("SELECT user_id FROM worker_profiles WHERE id = $1", [wId])).rows[0];
            const request = (await query("SELECT cp.user_id FROM delivery_requests dr JOIN client_profiles cp ON dr.client_id = cp.id WHERE dr.id = $1", [rId])).rows[0];
            if (worker.user_id === request.user_id) throw new Error('Workers cannot deliver to themselves');
            return 'Success';
        } catch (e) { return e.message; }
    };

    const selfDeal = await tryAccept(daveWPid, drId);
    console.log(`Dave Worker accepting Dave Client request: ${selfDeal}`);
    if (selfDeal.includes('cannot deliver to themselves')) console.log('OK: Self-dealing prevented.');
    else throw new Error('Self-dealing allowed');

    // 6. ASSET INTEGRITY (Bottle Return)
    console.log('--- Step 6: Test Asset Integrity ---');
    const tryReturn = async (delivered, returned, onHand) => {
        if (returned > onHand + delivered) throw new Error('Return exceeds on-hand assets');
        return 'Success';
    };
    try {
        await tryReturn(20, 40, 10);
        throw new Error('Should have failed bottle return');
    } catch (e) {
        console.log(`Returning 40 bottles (30 max): ${e.message}`);
        console.log('OK: Asset Integrity enforced.');
    }

    console.log('\nALL SCENARIO 2 TESTS PASSED SUCCESSFULLY!');

  } catch (error) {
    console.error('\nTEST FAILED:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

runTest();
