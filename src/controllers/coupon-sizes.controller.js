// src/controllers/coupon-sizes.controller.js
const { query } = require('../config/database');

/**
 * GET /api/v1/admin/coupon-sizes
 * Get all coupon sizes
 */
const getCouponSizes = async (req, res) => {
  try {
    const result = await query('SELECT * FROM coupon_sizes ORDER BY size ASC');
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to get coupon sizes' });
  }
};

/**
 * POST /api/v1/admin/coupon-sizes
 * Create new coupon size
 */
const createCouponSize = async (req, res) => {
  try {
    const { size } = req.body;
    
    if (!size || size <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid size' });
    }

    const result = await query(
      'INSERT INTO coupon_sizes (size) VALUES ($1) RETURNING *',
      [size]
    );
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ success: false, message: 'Size already exists' });
    }
    res.status(500).json({ success: false, message: 'Failed to create coupon size' });
  }
};

/**
 * PUT /api/v1/admin/coupon-sizes/:id
 * Update coupon size
 */
const updateCouponSize = async (req, res) => {
  try {
    const { id } = req.params;
    const { size } = req.body;
    
    if (!size || size <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid size' });
    }

    const result = await query(
      'UPDATE coupon_sizes SET size = $1 WHERE id = $2 RETURNING *',
      [size, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Coupon size not found' });
    }
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ success: false, message: 'Size already exists' });
    }
    res.status(500).json({ success: false, message: 'Failed to update coupon size' });
  }
};

/**
 * DELETE /api/v1/admin/coupon-sizes/:id
 * Delete coupon size (hard delete, sets client references to NULL)
 */
const deleteCouponSize = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query('DELETE FROM coupon_sizes WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Coupon size not found' });
    }
    
    res.json({ success: true, message: 'Coupon size deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete coupon size' });
  }
};

module.exports = {
  getCouponSizes,
  createCouponSize,
  updateCouponSize,
  deleteCouponSize,
};
