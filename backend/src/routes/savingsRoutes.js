const express = require('express');
const router = express.Router();
const savingsController = require('../controllers/savingsController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/', savingsController.getSavingsGoals);
router.post('/', savingsController.createSavingsGoal);
router.put('/:id', savingsController.updateSavingsGoal);
router.delete('/:id', savingsController.deleteSavingsGoal);

module.exports = router;
