// src/controllers/user.controller.js
const { query } = require('../config/database');
const logger = require('../utils/logger');

/**
 * PUT /api/v1/users/language
 * Update user's preferred language
 */
const updateLanguage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { language } = req.body;

    if (!['en', 'ar'].includes(language)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid language. Supported: en, ar'
      });
    }

    await query(
      'UPDATE users SET preferred_language = $1 WHERE id = $2',
      [language, userId]
    );

    logger.info('Language updated:', { userId, language });

    res.json({
      success: true,
      message: 'Language updated successfully',
      data: { preferred_language: language }
    });
  } catch (error) {
    logger.error('Update language error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update language'
    });
  }
};

module.exports = { updateLanguage };
