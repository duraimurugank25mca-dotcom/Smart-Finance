const express = require('express');
const router = express.Router();
const voiceController = require('../controllers/voiceController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.post('/parse', voiceController.parseVoice);

module.exports = router;
