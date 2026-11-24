const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.get('/me', authenticate, authController.getProfile);
router.put('/profile', authenticate, authController.updateProfile);
router.post('/forgot-password', authController.forgotPassword);

module.exports = router;
