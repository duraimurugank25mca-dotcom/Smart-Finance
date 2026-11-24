const db = require('../config/db');
const {
  callAiService,
  fallbackWastageAnalysis,
  fallbackIncomeAnalysis,
  fallbackChatAnswer,
} = require('../services/aiService');

// Perform AI Financial Analysis
const analyseFinancials = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    // Fetch user transactions for last 90 days
    const txRes = await db.query(
      `SELECT t.id, t.type, t.amount, t.transaction_date, t.payment_method, t.description,
              c.name as category_name
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false
         AND t.transaction_date >= (CURRENT_DATE - INTERVAL '90 days')
       ORDER BY t.transaction_date DESC`,
      [userId]
    );

    const transactions = txRes.rows;

    // Monthly totals
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

    // Call Python AI Service for Wastage Analysis
    let wastage = await callAiService('/analyse/wastage', {
      transactions,
      monthly_income: monthlyIncome,
    });

    if (!wastage) {
      wastage = fallbackWastageAnalysis(transactions, monthlyIncome);
    }

    // Call Python AI Service for Income Improvement
    let incomeAnalysis = await callAiService('/analyse/income', {
      transactions,
      total_income: monthlyIncome,
      total_expense: monthlyExpenses,
    });

    if (!incomeAnalysis) {
      incomeAnalysis = fallbackIncomeAnalysis(transactions, monthlyIncome, monthlyExpenses);
    }

    // Store insight record in PostgreSQL ai_insights
    await db.query(
      `INSERT INTO ai_insights (user_id, insight_type, title, content, severity, period)
       VALUES ($1, 'wastage', 'Monthly Wastage & Cost Optimization Analysis', $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      [userId, JSON.stringify(wastage), wastage.severity || 'medium', currentMonth]
    );

    res.status(200).json({
      success: true,
      data: {
        period: currentMonth,
        wastage,
        incomeAnalysis,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Natural Language Financial Chat
const chatFinancialAssistant = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { question } = req.body;

    if (!question) {
      return res.status(400).json({ success: false, message: 'Question string is required.' });
    }

    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    // Get live metrics for current user
    const totalStatsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as total_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as total_expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false`,
      [userId]
    );

    const monthStatsRes = await db.query(
      `SELECT 
         COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) as month_income,
         COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) as month_expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false AND TO_CHAR(transaction_date, 'YYYY-MM') = $2`,
      [userId, currentMonth]
    );

    // Today's expenses
    const todayRes = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as today_expense
       FROM transactions
       WHERE user_id = $1 AND is_deleted = false AND type = 'expense' AND transaction_date = CURRENT_DATE`,
      [userId]
    );

    // Top Category
    const topCatRes = await db.query(
      `SELECT c.name, COALESCE(SUM(t.amount), 0) as total
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false AND t.type = 'expense'
         AND TO_CHAR(t.transaction_date, 'YYYY-MM') = $2
       GROUP BY c.name
       ORDER BY total DESC LIMIT 1`,
      [userId, currentMonth]
    );

    const totalIncome = parseFloat(totalStatsRes.rows[0].total_income);
    const totalExpenses = parseFloat(totalStatsRes.rows[0].total_expense);
    const monthlyIncome = parseFloat(monthStatsRes.rows[0].month_income);
    const monthlyExpenses = parseFloat(monthStatsRes.rows[0].month_expense);
    const monthlySavings = monthlyIncome - monthlyExpenses;
    const savingsPct = monthlyIncome > 0 ? ((monthlySavings / monthlyIncome) * 100).toFixed(1) : '0';

    const context = {
      totalBalance: totalIncome - totalExpenses,
      totalIncome,
      totalExpenses,
      monthlyIncome,
      monthlyExpenses,
      monthlySavings,
      savingsPercentage: savingsPct,
      todayExpenses: parseFloat(todayRes.rows[0].today_expense),
      topExpenseCategory: topCatRes.rowCount > 0 ? topCatRes.rows[0].name : 'None',
      topExpenseAmount: topCatRes.rowCount > 0 ? parseFloat(topCatRes.rows[0].total) : 0,
      currency: req.user.preferred_currency || 'INR',
    };

    // Try calling Python AI service
    let aiResponse = await callAiService('/chat', {
      question,
      context,
    });

    let answer = aiResponse?.answer;
    if (!answer) {
      answer = fallbackChatAnswer(question, context);
    }

    res.status(200).json({
      success: true,
      data: {
        question,
        answer,
        context,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get User AI Insights history
const getInsights = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await db.query(
      'SELECT * FROM ai_insights WHERE user_id = $1 ORDER BY created_at DESC LIMIT 20',
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

module.exports = {
  analyseFinancials,
  chatFinancialAssistant,
  getInsights,
};
