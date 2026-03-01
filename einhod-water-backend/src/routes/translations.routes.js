// src/routes/translations.routes.js
// Admin routes for managing translations

const express = require('express');
const router = express.Router();
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { reloadTranslations } = require('../utils/i18n');
const logger = require('../utils/logger');

/**
 * POST /api/admin/translations/reload
 * Reload translations without server restart (admin only)
 */
router.post('/reload', authenticateToken, authorizeRoles('owner', 'administrator'), (req, res) => {
  try {
    reloadTranslations();
    logger.info('Translations reloaded by admin', { userId: req.user.userId });
    
    res.json({
      success: true,
      message: 'Translations reloaded successfully'
    });
  } catch (error) {
    logger.error('Failed to reload translations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reload translations',
      error: error.message
    });
  }
});

module.exports = router;
