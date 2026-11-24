const db = require('../config/db');

// List transactions with filtering, search & pagination
const getTransactions = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      type,
      category_id,
      start_date,
      end_date,
      search,
      payment_method,
      page = 1,
      limit = 30,
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [userId];
    let whereClause = 'WHERE t.user_id = $1 AND t.is_deleted = false';

    if (type) {
      params.push(type);
      whereClause += ` AND t.type = $${params.length}`;
    }

    if (category_id) {
      params.push(parseInt(category_id, 10));
      whereClause += ` AND t.category_id = $${params.length}`;
    }

    if (start_date) {
      params.push(start_date);
      whereClause += ` AND t.transaction_date >= $${params.length}`;
    }

    if (end_date) {
      params.push(end_date);
      whereClause += ` AND t.transaction_date <= $${params.length}`;
    }

    if (payment_method) {
      params.push(payment_method);
      whereClause += ` AND t.payment_method = $${params.length}`;
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      whereClause += ` AND (t.description ILIKE $${params.length} OR c.name ILIKE $${params.length} OR t.payment_method ILIKE $${params.length})`;
    }

    const query = `
      SELECT t.id, t.user_id, t.category_id, t.type, t.amount, t.transaction_date,
             t.payment_method, t.description, t.attachment_url, t.created_at, t.updated_at,
             c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      ${whereClause}
      ORDER BY t.transaction_date DESC, t.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    params.push(parseInt(limit, 10), parseInt(offset, 10));
    const result = await db.query(query, params);

    // Count query
    const countQuery = `
      SELECT COUNT(*) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      ${whereClause}
    `;
    const countResult = await db.query(countQuery, params.slice(0, -2));
    const total = parseInt(countResult.rows[0].total, 10);

    res.status(200).json({
      success: true,
      data: {
        transactions: result.rows,
        total,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get single transaction by ID
const getTransactionById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.id = $1 AND t.user_id = $2 AND t.is_deleted = false`,
      [id, req.user.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    res.status(200).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// Create transaction (Income or Expense)
const createTransaction = async (req, res, next) => {
  try {
    const {
      category_id,
      type,
      amount,
      transaction_date,
      payment_method,
      description,
      attachment_url,
    } = req.body;

    if (!category_id || !type || !amount || !transaction_date) {
      return res.status(400).json({
        success: false,
        message: 'category_id, type, amount, and transaction_date are required.',
      });
    }

    if (!['income', 'expense'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Type must be either income or expense.',
      });
    }

    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be a positive number.',
      });
    }

    // Verify category exists and matches type
    const catCheck = await db.query('SELECT id, name, type FROM categories WHERE id = $1', [category_id]);
    if (catCheck.rowCount === 0) {
      return res.status(400).json({ success: false, message: 'Specified category does not exist.' });
    }

    const inserted = await db.query(
      `INSERT INTO transactions (user_id, category_id, type, amount, transaction_date, payment_method, description, attachment_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, user_id, category_id, type, amount, transaction_date, payment_method, description, attachment_url, created_at`,
      [
        req.user.id,
        category_id,
        type,
        numAmount,
        transaction_date,
        payment_method || 'Cash',
        description || '',
        attachment_url || null,
      ]
    );

    // Fetch joined details
    const finalResult = await db.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.id = $1`,
      [inserted.rows[0].id]
    );

    res.status(201).json({
      success: true,
      message: 'Transaction saved successfully.',
      data: finalResult.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Update transaction
const updateTransaction = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      category_id,
      type,
      amount,
      transaction_date,
      payment_method,
      description,
      attachment_url,
    } = req.body;

    const existing = await db.query(
      'SELECT id FROM transactions WHERE id = $1 AND user_id = $2 AND is_deleted = false',
      [id, req.user.id]
    );

    if (existing.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    const updated = await db.query(
      `UPDATE transactions
       SET category_id = COALESCE($1, category_id),
           type = COALESCE($2, type),
           amount = COALESCE($3, amount),
           transaction_date = COALESCE($4, transaction_date),
           payment_method = COALESCE($5, payment_method),
           description = COALESCE($6, description),
           attachment_url = COALESCE($7, attachment_url),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $8 AND user_id = $9
       RETURNING id`,
      [
        category_id,
        type,
        amount ? parseFloat(amount) : undefined,
        transaction_date,
        payment_method,
        description,
        attachment_url,
        id,
        req.user.id,
      ]
    );

    const finalResult = await db.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.id = $1`,
      [id]
    );

    res.status(200).json({
      success: true,
      message: 'Transaction updated successfully.',
      data: finalResult.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Delete transaction
const deleteTransaction = async (req, res, next) => {
  try {
    const { id } = req.params;

    const deleted = await db.query(
      'UPDATE transactions SET is_deleted = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.id]
    );

    if (deleted.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found or already deleted.' });
    }

    res.status(200).json({
      success: true,
      message: 'Transaction deleted successfully.',
    });
  } catch (error) {
    next(error);
  }
};

// Financial Dashboard Summary
const getDashboardSummary = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    // All-time totals
    const totalStatsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as total_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as total_expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false`,
      [userId]
    );

    const totalIncome = parseFloat(totalStatsRes.rows[0].total_income);
    const totalExpenses = parseFloat(totalStatsRes.rows[0].total_expense);
    const totalBalance = totalIncome - totalExpenses;

    // Current Month totals
    const monthStatsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as month_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as month_expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false AND TO_CHAR(transaction_date, 'YYYY-MM') = $2`,
      [userId, currentMonth]
    );

    const monthlyIncome = parseFloat(monthStatsRes.rows[0].month_income);
    const monthlyExpenses = parseFloat(monthStatsRes.rows[0].month_expense);
    const monthlySavings = monthlyIncome - monthlyExpenses;
    const savingsPercentage = monthlyIncome > 0 ? ((monthlySavings / monthlyIncome) * 100).toFixed(1) : '0.0';

    // Recent 5 transactions
    const recentRes = await db.query(
      `SELECT t.id, t.type, t.amount, t.transaction_date, t.payment_method, t.description,
              c.name as category_name, c.icon as category_icon, c.color as category_color
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false
       ORDER BY t.transaction_date DESC, t.created_at DESC
       LIMIT 5`,
      [userId]
    );

    // Monthly Income vs Expense over past 6 months
    const monthlyTrendRes = await db.query(
      `SELECT 
         TO_CHAR(transaction_date, 'YYYY-MM') as month,
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false
         AND transaction_date >= (CURRENT_DATE - INTERVAL '6 months')
       GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
       ORDER BY month ASC`,
      [userId]
    );

    // Category-wise expense breakdown for current month
    const categoryBreakdownRes = await db.query(
      `SELECT c.id, c.name, c.color, c.icon,
              COALESCE(SUM(t.amount), 0) as total_amount
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false AND t.type = 'expense'
         AND TO_CHAR(t.transaction_date, 'YYYY-MM') = $2
       GROUP BY c.id, c.name, c.color, c.icon
       ORDER BY total_amount DESC`,
      [userId, currentMonth]
    );

    res.status(200).json({
      success: true,
      data: {
        totalBalance,
        totalIncome,
        totalExpenses,
        monthlyIncome,
        monthlyExpenses,
        monthlySavings,
        savingsPercentage: parseFloat(savingsPercentage),
        recentTransactions: recentRes.rows,
        monthlyTrend: monthlyTrendRes.rows,
        categoryBreakdown: categoryBreakdownRes.rows,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getTransactions,
  getTransactionById,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  getDashboardSummary,
};
