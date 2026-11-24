const jwt = require('jsonwebtoken');
const db = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'smart_finance_super_secret_jwt_key_2026_secured';

/**
 * Middleware to authenticate requests using JWT
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required. No token provided.',
      });
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired session. Please log in again.',
      });
    }

    // Verify user exists and is active in database
    const userRes = await db.query(
      'SELECT id, full_name, email, role, is_active, preferred_currency, preferred_language FROM users WHERE id = $1',
      [decoded.id]
    );

    if (userRes.rowCount === 0) {
      return res.status(401).json({
        success: false,
        message: 'User account not found.',
      });
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'This account has been deactivated by administrator. Please contact support.',
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal authentication error.',
    });
  }
};

/**
 * Middleware to restrict access to ADMIN only
 */
const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'ADMIN') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Administrative privileges required.',
    });
  }
  next();
};

/**
 * Middleware to protect user data isolation
 * Enforces that non-admin requests cannot access another user's private data.
 * Even for admin, private financial transactions cannot be accessed without explicit authorized audit flag.
 */
const enforceDataIsolation = (req, res, next) => {
  const targetUserId = req.params.userId || req.query.userId || req.body.userId;

  if (targetUserId && targetUserId !== req.user.id) {
    if (req.user.role === 'ADMIN') {
      const authorizedAudit = req.headers['x-admin-audit-purpose'];
      if (!authorizedAudit) {
        return res.status(403).json({
          success: false,
          message: 'Privacy Protection: Admins cannot access private user transactions without an explicit authorized administrative purpose header (x-admin-audit-purpose).',
        });
      }
    } else {
      return res.status(403).json({
        success: false,
        message: 'Data Isolation Violation: You are not authorized to access another user data.',
      });
    }
  }

  next();
};

module.exports = {
  authenticate,
  requireAdmin,
  enforceDataIsolation,
  JWT_SECRET,
};
