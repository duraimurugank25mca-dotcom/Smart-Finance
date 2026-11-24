const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.post('/scan', billController.scanBill);
router.post('/confirm', billController.confirmBill);
router.get('/', billController.getBillHistory);
router.get('/analytics', billController.getBillAnalytics);
router.get('/:id', billController.getBillById);

module.exports = router;
