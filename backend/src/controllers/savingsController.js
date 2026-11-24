const db = require('../config/db');

// List savings goals
const getSavingsGoals = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await db.query(
      `SELECT id, goal_name, target_amount, current_amount, target_date, category, is_completed, created_at,
              (target_amount - current_amount) as remaining_amount,
              ROUND((current_amount / NULLIF(target_amount, 0) * 100), 1) as progress_percentage,
              (target_date - CURRENT_DATE) as days_left
       FROM savings_goals
       WHERE user_id = $1
       ORDER BY is_completed ASC, target_date ASC`,
      [userId]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Create savings goal
const createSavingsGoal = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { goal_name, target_amount, current_amount = 0, target_date, category = 'General' } = req.body;

    if (!goal_name || !target_amount || !target_date) {
      return res.status(400).json({
        success: false,
        message: 'goal_name, target_amount, and target_date are required.',
      });
    }

    const targetNum = parseFloat(target_amount);
    const currentNum = parseFloat(current_amount) || 0;

    const inserted = await db.query(
      `INSERT INTO savings_goals (user_id, goal_name, target_amount, current_amount, target_date, category)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, goal_name.trim(), targetNum, currentNum, target_date, category]
    );

    res.status(201).json({
      success: true,
      message: 'Savings goal created successfully.',
      data: inserted.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Update savings goal / Add deposit
const updateSavingsGoal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { goal_name, target_amount, current_amount, target_date, category, is_completed } = req.body;

    const existing = await db.query('SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    if (existing.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Savings goal not found.' });
    }

    const updated = await db.query(
      `UPDATE savings_goals
       SET goal_name = COALESCE($1, goal_name),
           target_amount = COALESCE($2, target_amount),
           current_amount = COALESCE($3, current_amount),
           target_date = COALESCE($4, target_date),
           category = COALESCE($5, category),
           is_completed = COALESCE($6, is_completed),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $7 AND user_id = $8
       RETURNING *`,
      [
        goal_name,
        target_amount ? parseFloat(target_amount) : undefined,
        current_amount !== undefined ? parseFloat(current_amount) : undefined,
        target_date,
        category,
        is_completed,
        id,
        req.user.id,
      ]
    );

    res.status(200).json({
      success: true,
      message: 'Savings goal updated.',
      data: updated.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Delete savings goal
const deleteSavingsGoal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await db.query('DELETE FROM savings_goals WHERE id = $1 AND user_id = $2 RETURNING id', [id, req.user.id]);
    if (deleted.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Savings goal not found.' });
    }
    res.status(200).json({ success: true, message: 'Savings goal deleted.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getSavingsGoals,
  createSavingsGoal,
  updateSavingsGoal,
  deleteSavingsGoal,
};
