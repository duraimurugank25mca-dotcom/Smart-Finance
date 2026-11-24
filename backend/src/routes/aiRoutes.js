const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.post('/analyse', aiController.analyseFinancials);
router.post('/chat', aiController.chatFinancialAssistant);
router.get('/insights', aiController.getInsights);

module.exports = router;
