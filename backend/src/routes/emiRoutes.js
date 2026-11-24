const express = require('express');
const router = express.Router();
const emiController = require('../controllers/emiController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/', emiController.getEmis);
router.post('/', emiController.createEmi);
router.put('/:id', emiController.updateEmi);
router.post('/:id/pay', emiController.markEmiPaid);
router.delete('/:id', emiController.deleteEmi);

module.exports = router;
