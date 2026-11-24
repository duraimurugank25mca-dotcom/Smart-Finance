const db = require('../config/db');

// List budgets for user
const getBudgets = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const currentMonth = req.query.month_year || `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    // Get budgets joined with category and calculate actual spent
    const query = `
      SELECT b.id, b.user_id, b.category_id, b.month_year, b.amount as budget_limit, b.alert_threshold,
             c.name as category_name, c.color as category_color, c.icon as category_icon,
             COALESCE(
               (SELECT SUM(t.amount) 
                FROM transactions t 
                WHERE t.user_id = b.user_id 
                  AND t.category_id = b.category_id 
                  AND t.type = 'expense' 
                  AND t.is_deleted = false 
                  AND TO_CHAR(t.transaction_date, 'YYYY-MM') = b.month_year),
               0
             ) as spent_amount
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.user_id = $1 AND b.month_year = $2
      ORDER BY b.amount DESC
    `;

    const result = await db.query(query, [userId, currentMonth]);

    const budgets = result.rows.map((b) => {
      const budgetLimit = parseFloat(b.budget_limit);
      const spent = parseFloat(b.spent_amount);
      const remaining = Math.max(0, budgetLimit - spent);
      const progressPercent = budgetLimit > 0 ? Math.min(100, (spent / budgetLimit) * 100).toFixed(1) : '0';
      const isExceeded = spent > budgetLimit;
      const isWarning = spent >= budgetLimit * (parseFloat(b.alert_threshold) / 100);

      return {
        ...b,
        budget_limit: budgetLimit,
        spent_amount: spent,
        remaining_amount: remaining,
        progress_percentage: parseFloat(progressPercent),
        is_exceeded: isExceeded,
        is_warning: isWarning,
      };
    });

    res.status(200).json({
      success: true,
      data: {
        month: currentMonth,
        budgets,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Create or update budget
const upsertBudget = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { category_id, month_year, amount, alert_threshold = 80.0 } = req.body;

    if (!category_id || !month_year || !amount) {
      return res.status(400).json({
        success: false,
        message: 'category_id, month_year (YYYY-MM), and amount are required.',
      });
    }

    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid budget amount.' });
    }

    const upserted = await db.query(
      `INSERT INTO budgets (user_id, category_id, month_year, amount, alert_threshold)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (user_id, category_id, month_year)
       DO UPDATE SET amount = EXCLUDED.amount, alert_threshold = EXCLUDED.alert_threshold, updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [userId, category_id, month_year, numAmount, alert_threshold]
    );

    res.status(200).json({
      success: true,
      message: 'Budget saved successfully.',
      data: upserted.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Delete budget
const deleteBudget = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await db.query('DELETE FROM budgets WHERE id = $1 AND user_id = $2 RETURNING id', [id, req.user.id]);
    if (deleted.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Budget not found.' });
    }
    res.status(200).json({ success: true, message: 'Budget deleted successfully.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getBudgets,
  upsertBudget,
  deleteBudget,
};
