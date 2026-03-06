const { query } = require('../config/database');

// ── List all schedules ────────────────────────────────────────────────────────
exports.getSchedules = async (req, res) => {
  try {
    const result = await query(`
      SELECT 
        sd.*,
        cp.full_name as client_name,
        wp.full_name as worker_name
      FROM scheduled_deliveries sd
      LEFT JOIN client_profiles cp ON cp.id = sd.client_id
      LEFT JOIN worker_profiles wp ON sd.worker_id = wp.id
      ORDER BY sd.is_active DESC, sd.start_date DESC
    `);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching schedules:', error);
    res.status(getStatusCode(error)).json({ success: false, error: 'Failed to fetch schedules' });
  }
};

// ── Get single schedule ───────────────────────────────────────────────────────
exports.getSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(`
      SELECT 
        sd.*,
        cp.full_name as client_name,
        wp.full_name as worker_name
      FROM scheduled_deliveries sd
      JOIN client_profiles cp ON sd.client_id = cp.id
      LEFT JOIN worker_profiles wp ON sd.worker_id = wp.id
      WHERE sd.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Schedule not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching schedule:', error);
    res.status(getStatusCode(error)).json({ error: 'Failed to fetch schedule' });
  }
};

// ── Create schedule ───────────────────────────────────────────────────────────
exports.createSchedule = async (req, res) => {
  try {
    const {
      client_id,
      worker_id,
      gallons,
      schedule_type,
      schedule_time,
      schedule_days,
      start_date,
      end_date,
      is_active,
      notes
    } = req.body;

    // Support both single client_id and array of client_ids
    const clientIds = Array.isArray(client_id) ? client_id : [client_id];

    // Create a schedule for each client
    const results = [];
    for (const cid of clientIds) {
      const result = await query(`
        INSERT INTO scheduled_deliveries (
          client_id, worker_id, gallons, schedule_type, schedule_time,
          schedule_days, start_date, end_date, is_active, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *
      `, [
        cid, worker_id, gallons, schedule_type, schedule_time,
        schedule_days, start_date, end_date, is_active ?? true, notes
      ]);
      results.push(result.rows[0]);
    }

    res.status(201).json(results.length === 1 ? results[0] : results);
  } catch (error) {
    console.error('Error creating schedule:', error);
    res.status(500).json({ error: 'Failed to create schedule' });
  }
};

// ── Update schedule ───────────────────────────────────────────────────────────
exports.updateSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      worker_id,
      gallons,
      schedule_type,
      schedule_time,
      schedule_days,
      start_date,
      end_date,
      is_active,
      notes
    } = req.body;

    const result = await query(`
      UPDATE scheduled_deliveries SET
        worker_id = COALESCE($2, worker_id),
        gallons = COALESCE($3, gallons),
        schedule_type = COALESCE($4, schedule_type),
        schedule_time = COALESCE($5, schedule_time),
        schedule_days = COALESCE($6, schedule_days),
        start_date = COALESCE($7, start_date),
        end_date = COALESCE($8, end_date),
        is_active = COALESCE($9, is_active),
        notes = COALESCE($10, notes),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [
      id, worker_id, gallons, schedule_type, schedule_time,
      schedule_days, start_date, end_date, is_active, notes
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Schedule not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating schedule:', error);
    res.status(getStatusCode(error)).json({ error: 'Failed to update schedule' });
  }
};

// ── Delete schedule ───────────────────────────────────────────────────────────
exports.deleteSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      'DELETE FROM scheduled_deliveries WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Schedule not found' });
    }
    res.json({ message: 'Schedule deleted successfully' });
  } catch (error) {
    console.error('Error deleting schedule:', error);
    res.status(getStatusCode(error)).json({ error: 'Failed to delete schedule' });
  }
};

// ── Batch delete ──────────────────────────────────────────────────────────────
exports.batchDeleteSchedules = async (req, res) => {
  try {
    const { ids } = req.body;
    await query(
      'DELETE FROM scheduled_deliveries WHERE id = ANY($1)',
      [ids]
    );
    res.json({ message: `Deleted ${ids.length} schedules` });
  } catch (error) {
    console.error('Error batch deleting schedules:', error);
    res.status(getStatusCode(error)).json({ error: 'Failed to delete schedules' });
  }
};
