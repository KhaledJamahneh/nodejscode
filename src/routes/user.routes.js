// src/routes/user.routes.js
const express = require('express');
const { body } = require('express-validator');
const { updateLanguage } = require('../controllers/user.controller');
const { authenticateToken } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

const router = express.Router();

router.put(
  '/language',
  authenticateToken,
  [
    body('language').isIn(['en', 'ar']).withMessage('Language must be en or ar')
  ],
  validate,
  updateLanguage
);

module.exports = router;
