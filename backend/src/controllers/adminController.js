const db = require('../config/db');

// List registered users with pagination & search
const listUsers = async (req, res, next) => {
  try {
    const { search, role, status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT id, full_name, email, role, is_active, phone, preferred_currency, created_at,
             (SELECT COUNT(*) FROM transactions t WHERE t.user_id = users.id AND t.is_deleted = false) as transaction_count,
             (SELECT COALESCE(SUM(amount), 0) FROM transactions t WHERE t.user_id = users.id AND t.type = 'expense' AND t.is_deleted = false) as total_expenses_recorded
      FROM users
      WHERE 1=1
    `;
    const params = [];

    if (search) {
      params.push(`%${search.trim()}%`);
      query += ` AND (full_name ILIKE $${params.length} OR email ILIKE $${params.length})`;
    }

    if (role) {
      params.push(role);
      query += ` AND role = $${params.length}`;
    }

    if (status !== undefined) {
      params.push(status === 'active');
      query += ` AND is_active = $${params.length}`;
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    // Total count
    const countRes = await db.query('SELECT COUNT(*) FROM users');
    const totalUsers = parseInt(countRes.rows[0].count, 10);

    res.status(200).json({
      success: true,
      data: {
        users: result.rows,
        total: totalUsers,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      },
    });
  } catch (error) {
    next(error);
  }
};

// Activate or Deactivate user account
const toggleUserStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (typeof is_active !== 'boolean') {
      return res.status(400).json({ success: false, message: 'is_active boolean is required.' });
    }

    // Prevent admin from deactivating self
    if (id === req.user.id) {
      return res.status(400).json({ success: false, message: 'Administrators cannot deactivate their own active account.' });
    }

    const updated = await db.query(
      'UPDATE users SET is_active = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, full_name, email, role, is_active',
      [is_active, id]
    );

    if (updated.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    res.status(200).json({
      success: true,
      message: `User account has been ${is_active ? 'activated' : 'deactivated'} successfully.`,
      data: updated.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// System level analytics
const getSystemAnalytics = async (req, res, next) => {
  try {
    const usersCountRes = await db.query(`
      SELECT 
        COUNT(*) as total_users,
        COUNT(*) FILTER (WHERE is_active = true) as active_users,
        COUNT(*) FILTER (WHERE is_active = false) as deactivated_users,
        COUNT(*) FILTER (WHERE role = 'ADMIN') as admin_count
      FROM users
    `);

    const transactionStatsRes = await db.query(`
      SELECT 
        COUNT(*) as total_transactions,
        COUNT(*) FILTER (WHERE type = 'income') as income_transactions,
        COUNT(*) FILTER (WHERE type = 'expense') as expense_transactions,
        COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as system_total_income,
        COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as system_total_expense
      FROM transactions
      WHERE is_deleted = false
    `);

    const emiStatsRes = await db.query(`
      SELECT 
        COUNT(*) as total_emis,
        COUNT(*) FILTER (WHERE status = 'active') as active_emis,
        COUNT(*) FILTER (WHERE status = 'overdue') as overdue_emis
      FROM emi_details
    `);

    const billsCountRes = await db.query('SELECT COUNT(*) as total_scans FROM bill_scans');

    res.status(200).json({
      success: true,
      data: {
        users: usersCountRes.rows[0],
        transactions: transactionStatsRes.rows[0],
        emis: emiStatsRes.rows[0],
        scans: billsCountRes.rows[0],
      },
    });
  } catch (error) {
    next(error);
  }
};

// Activity logs
const getActivityLogs = async (req, res, next) => {
  try {
    const logsRes = await db.query(`
      SELECT n.id, n.title, n.body, n.notification_type, n.sent_at, u.full_name as user_name, u.email as user_email
      FROM notification_logs n
      JOIN users u ON n.user_id = u.id
      ORDER BY n.sent_at DESC
      LIMIT 50
    `);

    res.status(200).json({
      success: true,
      data: logsRes.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Application settings
let appSettings = {
  maintenance_mode: false,
  allow_registration: true,
  default_currency: 'INR',
  ai_model: 'Gemini-3.8-Flash-Integrated',
  fcm_enabled: true,
  max_upload_size_mb: 10,
};

const getSettings = (req, res) => {
  res.status(200).json({ success: true, data: appSettings });
};

const updateSettings = (req, res) => {
  appSettings = { ...appSettings, ...req.body };
  res.status(200).json({ success: true, message: 'Settings updated successfully.', data: appSettings });
};

module.exports = {
  listUsers,
  toggleUserStatus,
  getSystemAnalytics,
  getActivityLogs,
  getSettings,
  updateSettings,
};
