const db = require('../config/db');
const { generateFinancialPdf } = require('../services/pdfService');

// Get Report Summary data
const getReportSummary = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { start_date, end_date, report_type = 'all' } = req.query;

    if (!start_date || !end_date) {
      return res.status(400).json({ success: false, message: 'start_date and end_date are required (YYYY-MM-DD).' });
    }

    if (new Date(start_date) > new Date(end_date)) {
      return res.status(400).json({ success: false, message: 'start_date cannot be greater than end_date.' });
    }

    // Totals
    const totalsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as total_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as total_expenses,
         COUNT(*) as total_count
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false
         AND transaction_date >= $2 AND transaction_date <= $3`,
      [userId, start_date, end_date]
    );

    const totalIncome = parseFloat(totalsRes.rows[0].total_income);
    const totalExpenses = parseFloat(totalsRes.rows[0].total_expenses);
    const netSavings = totalIncome - totalExpenses;

    // Category breakdown
    const categoryBreakdownRes = await db.query(
      `SELECT c.id, c.name, c.color, c.type,
              COALESCE(SUM(t.amount), 0) as total_amount,
              COUNT(t.id) as count
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false
         AND t.transaction_date >= $2 AND t.transaction_date <= $3
         ${report_type !== 'all' ? 'AND t.type = $4' : ''}
       GROUP BY c.id, c.name, c.color, c.type
       ORDER BY total_amount DESC`,
      report_type !== 'all' ? [userId, start_date, end_date, report_type] : [userId, start_date, end_date]
    );

    res.status(200).json({
      success: true,
      data: {
        startDate: start_date,
        endDate: end_date,
        reportType: report_type,
        totalIncome,
        totalExpenses,
        netSavings,
        totalTransactions: parseInt(totalsRes.rows[0].total_count, 10),
        categoryBreakdown: categoryBreakdownRes.rows,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Generate and download / view PDF
const generatePdfReport = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { start_date, end_date, report_type = 'all' } = req.body;

    if (!start_date || !end_date) {
      return res.status(400).json({ success: false, message: 'start_date and end_date are required (YYYY-MM-DD).' });
    }

    if (new Date(start_date) > new Date(end_date)) {
      return res.status(400).json({ success: false, message: 'start_date cannot be after end_date.' });
    }

    // Fetch user details
    const userRes = await db.query(
      'SELECT full_name, email, preferred_currency FROM users WHERE id = $1',
      [userId]
    );
    const user = userRes.rows[0];

    // Fetch transactions
    let txQuery = `
      SELECT t.id, t.type, t.amount, t.transaction_date, t.payment_method, t.description,
             c.name as category_name
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = $1 AND t.is_deleted = false
        AND t.transaction_date >= $2 AND t.transaction_date <= $3
    `;
    const params = [userId, start_date, end_date];

    if (report_type && report_type !== 'all') {
      params.push(report_type);
      txQuery += ` AND t.type = $${params.length}`;
    }

    txQuery += ' ORDER BY t.transaction_date DESC, t.created_at DESC';

    const txResult = await db.query(txQuery, params);
    const transactions = txResult.rows;

    // Totals
    const totalsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as total_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as total_expenses
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false
         AND transaction_date >= $2 AND transaction_date <= $3`,
      [userId, start_date, end_date]
    );

    const totalIncome = parseFloat(totalsRes.rows[0].total_income);
    const totalExpenses = parseFloat(totalsRes.rows[0].total_expenses);
    const netSavings = totalIncome - totalExpenses;

    // Category breakdown
    const categoryRes = await db.query(
      `SELECT c.name, COALESCE(SUM(t.amount), 0) as total_amount
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false AND t.type = 'expense'
         AND t.transaction_date >= $2 AND t.transaction_date <= $3
       GROUP BY c.name
       ORDER BY total_amount DESC`,
      [userId, start_date, end_date]
    );

    const pdfBuffer = await generateFinancialPdf({
      user,
      startDate: start_date,
      endDate: end_date,
      reportType: report_type,
      transactions,
      summary: { totalIncome, totalExpenses, netSavings },
      categoryBreakdown: categoryRes.rows,
    });

    const filename = `Financial_Report_${start_date}_to_${end_date}.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', pdfBuffer.length);
    res.send(pdfBuffer);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getReportSummary,
  generatePdfReport,
};
