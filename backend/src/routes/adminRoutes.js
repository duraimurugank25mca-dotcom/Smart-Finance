const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, requireAdmin } = require('../middleware/auth');

router.use(authenticate);
router.use(requireAdmin);

router.get('/users', adminController.listUsers);
router.put('/users/:id/status', adminController.toggleUserStatus);
router.get('/analytics', adminController.getSystemAnalytics);
router.get('/logs', adminController.getActivityLogs);
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);

module.exports = router;
