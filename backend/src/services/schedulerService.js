const cron = require('node-cron');
const db = require('../config/db');

/**
 * Scheduled background tasks
 * Runs every day at 09:00 AM (or can be triggered on demand)
 */
const initScheduler = () => {
  console.log('Initializing scheduled background tasks...');

  // Run daily at 09:00 AM
  cron.schedule('0 9 * * *', async () => {
    console.log('Running scheduled daily reminder and budget checks...');
    await checkEmiReminders();
    await checkBudgetAlerts();
  });
};

/**
 * Checks upcoming and overdue EMIs and creates notification logs
 */
const checkEmiReminders = async () => {
  try {
    const today = new Date().toISOString().substring(0, 10);

    // 1. Due Today or in next 2 days
    const upcomingEmis = await db.query(
      `SELECT e.*, (e.due_date - CURRENT_DATE) as days_diff
       FROM emi_details e
       WHERE e.status = 'active'
         AND e.due_date >= CURRENT_DATE 
         AND e.due_date <= (CURRENT_DATE + INTERVAL '2 days')`
    );

    for (const emi of upcomingEmis.rows) {
      const days = parseInt(emi.days_diff, 10);
      let title = '';
      if (days === 0) {
        title = `URGENT: ${emi.emi_name} EMI is due TODAY!`;
      } else if (days === 1) {
        title = `Reminder: ${emi.emi_name} EMI is due tomorrow`;
      } else {
        title = `Upcoming: ${emi.emi_name} EMI due in 2 days`;
      }

      const body = `EMI of ₹${parseFloat(emi.emi_amount).toLocaleString('en-IN')} for ${emi.loan_provider} is due on ${emi.due_date.toISOString().substring(0, 10)}. Please ensure balance.`;

      // Prevent duplicate notification on same day
      const exists = await db.query(
        `SELECT id FROM notification_logs 
         WHERE user_id = $1 AND title = $2 AND DATE(sent_at) = CURRENT_DATE`,
        [emi.user_id, title]
      );

      if (exists.rowCount === 0) {
        await db.query(
          `INSERT INTO notification_logs (user_id, title, body, notification_type, metadata)
           VALUES ($1, $2, $3, 'emi', $4)`,
          [emi.user_id, title, body, JSON.stringify({ emi_id: emi.id, amount: emi.emi_amount })]
        );
      }
    }

    // 2. Mark Overdue EMIs
    const overdueEmis = await db.query(
      `UPDATE emi_details
       SET status = 'overdue', updated_at = CURRENT_TIMESTAMP
       WHERE status = 'active' AND due_date < CURRENT_DATE
       RETURNING id, user_id, emi_name, loan_provider, emi_amount, due_date`
    );

    for (const emi of overdueEmis.rows) {
      const title = `OVERDUE ALERT: ${emi.emi_name} EMI is overdue`;
      const body = `Your EMI of ₹${parseFloat(emi.emi_amount).toLocaleString('en-IN')} was due on ${emi.due_date.toISOString().substring(0, 10)}. Please make the payment immediately.`;

      const exists = await db.query(
        `SELECT id FROM notification_logs 
         WHERE user_id = $1 AND title = $2 AND DATE(sent_at) = CURRENT_DATE`,
        [emi.user_id, title]
      );

      if (exists.rowCount === 0) {
        await db.query(
          `INSERT INTO notification_logs (user_id, title, body, notification_type, metadata)
           VALUES ($1, $2, $3, 'emi', $4)`,
          [emi.user_id, title, body, JSON.stringify({ emi_id: emi.id, overdue: true })]
        );
      }
    }
  } catch (error) {
    console.error('Error during scheduled EMI checks:', error);
  }
};

/**
 * Checks whether user has exceeded budget thresholds
 */
const checkBudgetAlerts = async () => {
  try {
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    const budgets = await db.query(
      `SELECT b.*, c.name as category_name,
              COALESCE((SELECT SUM(t.amount) 
                        FROM transactions t 
                        WHERE t.user_id = b.user_id AND t.category_id = b.category_id 
                          AND t.type = 'expense' AND t.is_deleted = false 
                          AND TO_CHAR(t.transaction_date, 'YYYY-MM') = b.month_year), 0) as spent
       FROM budgets b
       LEFT JOIN categories c ON b.category_id = c.id
       WHERE b.month_year = $1`,
      [currentMonth]
    );

    for (const b of budgets.rows) {
      const limit = parseFloat(b.amount);
      const spent = parseFloat(b.spent);
      const percent = limit > 0 ? (spent / limit) * 100 : 0;

      if (percent >= parseFloat(b.alert_threshold)) {
        const title = `Budget Alert: ${b.category_name || 'Category'} at ${percent.toFixed(0)}%`;
        const body = `You have spent ₹${spent.toLocaleString('en-IN')} out of your ₹${limit.toLocaleString('en-IN')} budget for ${b.category_name}.`;

        const exists = await db.query(
          `SELECT id FROM notification_logs 
           WHERE user_id = $1 AND title = $2 AND DATE(sent_at) = CURRENT_DATE`,
          [b.user_id, title]
        );

        if (exists.rowCount === 0) {
          await db.query(
            `INSERT INTO notification_logs (user_id, title, body, notification_type, metadata)
             VALUES ($1, $2, $3, 'budget_warning', $4)`,
            [b.user_id, title, body, JSON.stringify({ category_id: b.category_id, spent, limit })]
          );
        }
      }
    }
  } catch (error) {
    console.error('Error during budget alert checks:', error);
  }
};

module.exports = {
  initScheduler,
  checkEmiReminders,
  checkBudgetAlerts,
};
