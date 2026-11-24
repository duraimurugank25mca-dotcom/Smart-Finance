const express = require('express');
const router = express.Router();
const reminderController = require('../controllers/reminderController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/', reminderController.getReminders);
router.put('/:id/dismiss', reminderController.dismissReminder);
router.get('/notifications', reminderController.getNotifications);
router.put('/notifications/read', reminderController.markNotificationsRead);

module.exports = router;
