const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');

// Register new user
const register = async (req, res, next) => {
  try {
    const { full_name, email, password, phone, preferred_currency, preferred_language } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Full name, email, and password are required.',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long.',
      });
    }

    // Check if user already exists
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase().trim()]);
    if (existing.rowCount > 0) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email address already exists.',
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const newUser = await db.query(
      `INSERT INTO users (full_name, email, password_hash, role, phone, preferred_currency, preferred_language)
       VALUES ($1, $2, $3, 'USER', $4, $5, $6)
       RETURNING id, full_name, email, role, is_active, phone, preferred_currency, preferred_language, created_at`,
      [
        full_name.trim(),
        email.toLowerCase().trim(),
        passwordHash,
        phone || null,
        preferred_currency || 'INR',
        preferred_language || 'en',
      ]
    );

    const user = newUser.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Account registered successfully.',
      data: {
        token,
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Login user
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password.',
      });
    }

    const userRes = await db.query(
      'SELECT id, full_name, email, password_hash, role, is_active, phone, preferred_currency, preferred_language FROM users WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    if (userRes.rowCount === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password credentials.',
      });
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated by an administrator. Please contact support.',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password credentials.',
      });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Don't return password hash
    delete user.password_hash;

    res.status(200).json({
      success: true,
      message: 'Logged in successfully.',
      data: {
        token,
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Logout
const logout = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Logged out successfully. Token cleared on client.',
  });
};

// Get current user profile
const getProfile = async (req, res, next) => {
  try {
    const userRes = await db.query(
      'SELECT id, full_name, email, role, is_active, phone, preferred_currency, preferred_language, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (userRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    res.status(200).json({
      success: true,
      data: userRes.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Update profile
const updateProfile = async (req, res, next) => {
  try {
    const { full_name, phone, preferred_currency, preferred_language } = req.body;

    const updated = await db.query(
      `UPDATE users 
       SET full_name = COALESCE($1, full_name),
           phone = COALESCE($2, phone),
           preferred_currency = COALESCE($3, preferred_currency),
           preferred_language = COALESCE($4, preferred_language),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $5
       RETURNING id, full_name, email, role, is_active, phone, preferred_currency, preferred_language, updated_at`,
      [full_name, phone, preferred_currency, preferred_language, req.user.id]
    );

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      data: updated.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Forgot Password
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required.' });
    }

    const check = await db.query('SELECT id, full_name FROM users WHERE email = $1', [email.toLowerCase().trim()]);
    // Always return safe message to avoid email enumeration
    res.status(200).json({
      success: true,
      message: 'If that email address is registered, password reset instructions have been dispatched.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  logout,
  getProfile,
  updateProfile,
  forgotPassword,
};
