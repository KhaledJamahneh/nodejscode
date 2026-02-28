const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

router.use(authenticateToken);
router.use(authorizeRoles('administrator', 'owner'));

router.get('/', scheduleController.getSchedules);
router.get('/:id', scheduleController.getSchedule);
router.post('/', scheduleController.createSchedule);
router.put('/:id', scheduleController.updateSchedule);
router.delete('/:id', scheduleController.deleteSchedule);
router.post('/batch-delete', scheduleController.batchDeleteSchedules);

module.exports = router;
