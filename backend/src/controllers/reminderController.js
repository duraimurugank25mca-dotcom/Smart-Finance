const db = require('../config/db');

// List reminders for user
const getReminders = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { status = 'pending' } = req.query;

    let query = `
      SELECT r.id, r.emi_id, r.title, r.reminder_date, r.reminder_time, r.reminder_type, r.status, r.is_sent,
             e.emi_name, e.loan_provider, e.emi_amount
      FROM reminders r
      LEFT JOIN emi_details e ON r.emi_id = e.id
      WHERE r.user_id = $1
    `;
    const params = [userId];

    if (status) {
      params.push(status);
      query += ` AND r.status = $${params.length}`;
    }

    query += ' ORDER BY r.reminder_date ASC';
    const result = await db.query(query, params);

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Dismiss reminder
const dismissReminder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updated = await db.query(
      'UPDATE reminders SET status = \'dismissed\' WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.id]
    );

    if (updated.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Reminder not found.' });
    }

    res.status(200).json({ success: true, message: 'Reminder dismissed.' });
  } catch (error) {
    next(error);
  }
};

// Get notifications
const getNotifications = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await db.query(
      'SELECT * FROM notification_logs WHERE user_id = $1 ORDER BY sent_at DESC LIMIT 30',
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

// Mark notifications read
const markNotificationsRead = async (req, res, next) => {
  try {
    await db.query('UPDATE notification_logs SET is_read = true WHERE user_id = $1', [req.user.id]);
    res.status(200).json({ success: true, message: 'Notifications marked as read.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getReminders,
  dismissReminder,
  getNotifications,
  markNotificationsRead,
};
