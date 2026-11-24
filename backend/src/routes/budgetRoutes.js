const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budgetController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/', budgetController.getBudgets);
router.post('/', budgetController.upsertBudget);
router.delete('/:id', budgetController.deleteBudget);

module.exports = router;
