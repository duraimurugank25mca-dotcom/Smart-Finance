const db = require('../config/db');

// List EMIs
const getEmis = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    let query = `
      SELECT id, emi_name, loan_provider, emi_amount, due_date, payment_frequency,
             category, status, total_installments, paid_installments, created_at,
             (due_date - CURRENT_DATE) as days_remaining
      FROM emi_details
      WHERE user_id = $1
    `;
    const params = [userId];

    if (status) {
      params.push(status);
      query += ` AND status = $${params.length}`;
    }

    query += ' ORDER BY due_date ASC';
    const result = await db.query(query, params);

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Create EMI
const createEmi = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      emi_name,
      loan_provider,
      emi_amount,
      due_date,
      payment_frequency = 'monthly',
      category = 'Personal Loan',
      total_installments = 12,
    } = req.body;

    if (!emi_name || !loan_provider || !emi_amount || !due_date) {
      return res.status(400).json({
        success: false,
        message: 'emi_name, loan_provider, emi_amount, and due_date are required.',
      });
    }

    const amount = parseFloat(emi_amount);
    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid EMI amount.' });
    }

    const inserted = await db.query(
      `INSERT INTO emi_details (user_id, emi_name, loan_provider, emi_amount, due_date, payment_frequency, category, total_installments)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [userId, emi_name.trim(), loan_provider.trim(), amount, due_date, payment_frequency, category, total_installments]
    );

    const emi = inserted.rows[0];

    // Pre-generate standard reminders (2 days before, 1 day before, due date)
    const dueDateObj = new Date(due_date);
    const twoDaysBefore = new Date(dueDateObj);
    twoDaysBefore.setDate(twoDaysBefore.getDate() - 2);

    const oneDayBefore = new Date(dueDateObj);
    oneDayBefore.setDate(oneDayBefore.getDate() - 1);

    const reminderDates = [
      { date: twoDaysBefore.toISOString().substring(0, 10), title: `Upcoming EMI: ${emi_name} due in 2 days` },
      { date: oneDayBefore.toISOString().substring(0, 10), title: `Upcoming EMI: ${emi_name} due tomorrow` },
      { date: due_date, title: `EMI Due Today: ${emi_name} (${loan_provider})` },
    ];

    for (const r of reminderDates) {
      await db.query(
        `INSERT INTO reminders (user_id, emi_id, title, reminder_date, reminder_type)
         VALUES ($1, $2, $3, $4, 'emi')
         ON CONFLICT DO NOTHING`,
        [userId, emi.id, r.title, r.date]
      );
    }

    res.status(201).json({
      success: true,
      message: 'EMI created and reminders scheduled.',
      data: emi,
    });
  } catch (error) {
    next(error);
  }
};

// Update EMI
const updateEmi = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      emi_name,
      loan_provider,
      emi_amount,
      due_date,
      payment_frequency,
      category,
      status,
      total_installments,
      paid_installments,
    } = req.body;

    const existing = await db.query('SELECT id FROM emi_details WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    if (existing.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'EMI record not found.' });
    }

    const updated = await db.query(
      `UPDATE emi_details
       SET emi_name = COALESCE($1, emi_name),
           loan_provider = COALESCE($2, loan_provider),
           emi_amount = COALESCE($3, emi_amount),
           due_date = COALESCE($4, due_date),
           payment_frequency = COALESCE($5, payment_frequency),
           category = COALESCE($6, category),
           status = COALESCE($7, status),
           total_installments = COALESCE($8, total_installments),
           paid_installments = COALESCE($9, paid_installments),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $10 AND user_id = $11
       RETURNING *`,
      [
        emi_name,
        loan_provider,
        emi_amount ? parseFloat(emi_amount) : undefined,
        due_date,
        payment_frequency,
        category,
        status,
        total_installments,
        paid_installments,
        id,
        req.user.id,
      ]
    );

    res.status(200).json({
      success: true,
      message: 'EMI record updated successfully.',
      data: updated.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Mark EMI as Paid (Advances due date and creates an expense transaction automatically)
const markEmiPaid = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const emiRes = await db.query('SELECT * FROM emi_details WHERE id = $1 AND user_id = $2', [id, userId]);
    if (emiRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'EMI record not found.' });
    }

    const emi = emiRes.rows[0];

    // Find or fallback to 'EMI' category
    const catRes = await db.query("SELECT id FROM categories WHERE name ILIKE '%EMI%' AND type = 'expense' LIMIT 1");
    const categoryId = catRes.rowCount > 0 ? catRes.rows[0].id : 14;

    // Create corresponding expense transaction in transactions table
    await db.query(
      `INSERT INTO transactions (user_id, category_id, type, amount, transaction_date, payment_method, description)
       VALUES ($1, $2, 'expense', $3, CURRENT_DATE, 'Bank Transfer', $4)`,
      [userId, categoryId, emi.emi_amount, `EMI Payment: ${emi.emi_name} (${emi.loan_provider})`]
    );

    // Calculate next due date
    const currentDue = new Date(emi.due_date);
    let nextDue = new Date(currentDue);
    if (emi.payment_frequency === 'yearly') {
      nextDue.setFullYear(nextDue.getFullYear() + 1);
    } else if (emi.payment_frequency === 'quarterly') {
      nextDue.setMonth(nextDue.getMonth() + 3);
    } else {
      nextDue.setMonth(nextDue.getMonth() + 1);
    }

    const newPaidCount = (emi.paid_installments || 0) + 1;
    const isCompleted = emi.total_installments && newPaidCount >= emi.total_installments;

    const updated = await db.query(
      `UPDATE emi_details
       SET due_date = $1,
           paid_installments = $2,
           status = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $4
       RETURNING *`,
      [
        nextDue.toISOString().substring(0, 10),
        newPaidCount,
        isCompleted ? 'paid' : 'active',
        id,
      ]
    );

    // Create notification log
    await db.query(
      `INSERT INTO notification_logs (user_id, title, body, notification_type, metadata)
       VALUES ($1, $2, $3, 'emi', $4)`,
      [
        userId,
        `EMI Paid: ${emi.emi_name}`,
        `Payment of ₹${parseFloat(emi.emi_amount).toLocaleString('en-IN')} marked as paid. Next due date: ${nextDue.toISOString().substring(0, 10)}.`,
        JSON.stringify({ emi_id: emi.id }),
      ]
    );

    res.status(200).json({
      success: true,
      message: 'EMI payment logged and expense transaction created successfully.',
      data: updated.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

// Delete EMI
const deleteEmi = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await db.query('DELETE FROM emi_details WHERE id = $1 AND user_id = $2 RETURNING id', [id, req.user.id]);

    if (deleted.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'EMI record not found.' });
    }

    res.status(200).json({ success: true, message: 'EMI record deleted successfully.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getEmis,
  createEmi,
  updateEmi,
  markEmiPaid,
  deleteEmi,
};
