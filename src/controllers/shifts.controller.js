// src/controllers/shifts.controller.js
const { query } = require('../config/database');

// Get all shifts
exports.getShifts = async (req, res) => {
  try {
    const result = await query('SELECT * FROM work_shifts ORDER BY name');
    res.json({ shifts: result.rows });
  } catch (error) {
    console.error('Error fetching shifts:', error);
    res.status(500).json({ message: 'Failed to fetch shifts' });
  }
};

// Create shift
exports.createShift = async (req, res) => {
  try {
    const { name, days_of_week, start_time, end_time } = req.body;
    
    const result = await query(
      'INSERT INTO work_shifts (name, days_of_week, start_time, end_time) VALUES ($1, $2, $3, $4) RETURNING *',
      [name, days_of_week, start_time, end_time]
    );
    
    res.status(201).json({ shift: result.rows[0] });
  } catch (error) {
    console.error('Error creating shift:', error);
    res.status(500).json({ message: 'Failed to create shift' });
  }
};

// Update shift
exports.updateShift = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, days_of_week, start_time, end_time, is_active } = req.body;
    
    const result = await query(
      'UPDATE work_shifts SET name = $1, days_of_week = $2, start_time = $3, end_time = $4, is_active = $5 WHERE id = $6 RETURNING *',
      [name, days_of_week, start_time, end_time, is_active, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Shift not found' });
    }
    
    res.json({ shift: result.rows[0] });
  } catch (error) {
    console.error('Error updating shift:', error);
    res.status(500).json({ message: 'Failed to update shift' });
  }
};

// Delete shift
exports.deleteShift = async (req, res) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM work_shifts WHERE id = $1', [id]);
    res.json({ message: 'Shift deleted successfully' });
  } catch (error) {
    console.error('Error deleting shift:', error);
    res.status(500).json({ message: 'Failed to delete shift' });
  }
};

// Assign shift to worker
exports.assignShift = async (req, res) => {
  try {
    const { userId, shiftId } = req.body;
    
    await query(
      'UPDATE worker_profiles SET shift_id = $1 WHERE user_id = $2',
      [shiftId, userId]
    );
    
    res.json({ message: 'Shift assigned successfully' });
  } catch (error) {
    console.error('Error assigning shift:', error);
    res.status(500).json({ message: 'Failed to assign shift' });
  }
};

// Get worker leaves
exports.getLeaves = async (req, res) => {
  try {
    const { user_id, active_only } = req.query;
    
    let sql = `
      SELECT wl.*, u.username 
      FROM worker_leaves wl
      JOIN users u ON wl.user_id = u.id
      WHERE 1=1
    `;
    const params = [];
    
    if (user_id) {
      params.push(user_id);
      sql += ` AND wl.user_id = $${params.length}`;
    }
    
    if (active_only === 'true') {
      sql += ` AND CURRENT_DATE BETWEEN wl.start_date AND wl.end_date`;
    }
    
    sql += ' ORDER BY wl.start_date DESC';
    
    const result = await query(sql, params);
    res.json({ leaves: result.rows });
  } catch (error) {
    console.error('Error fetching leaves:', error);
    res.status(500).json({ message: 'Failed to fetch leaves' });
  }
};

// Create leave
exports.createLeave = async (req, res) => {
  try {
    const { user_id, leave_type, start_date, end_date, reason } = req.body;
    
    const result = await query(
      'INSERT INTO worker_leaves (user_id, leave_type, start_date, end_date, reason) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [user_id, leave_type, start_date, end_date, reason]
    );
    
    res.status(201).json({ leave: result.rows[0] });
  } catch (error) {
    console.error('Error creating leave:', error);
    res.status(500).json({ message: 'Failed to create leave' });
  }
};

// Update leave
exports.updateLeave = async (req, res) => {
  try {
    const { id } = req.params;
    const { leave_type, start_date, end_date, reason } = req.body;
    
    const result = await query(
      'UPDATE worker_leaves SET leave_type = $1, start_date = $2, end_date = $3, reason = $4 WHERE id = $5 RETURNING *',
      [leave_type, start_date, end_date, reason, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Leave not found' });
    }
    
    res.json({ leave: result.rows[0] });
  } catch (error) {
    console.error('Error updating leave:', error);
    res.status(500).json({ message: 'Failed to update leave' });
  }
};

// Delete leave
exports.deleteLeave = async (req, res) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM worker_leaves WHERE id = $1', [id]);
    res.json({ message: 'Leave deleted successfully' });
  } catch (error) {
    console.error('Error deleting leave:', error);
    res.status(500).json({ message: 'Failed to delete leave' });
  }
};
