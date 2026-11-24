const db = require('../config/db');
const { callAiService } = require('../services/aiService');

// Parse Voice Command
const parseVoice = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { text, language = 'en' } = req.body;

    if (!text) {
      return res.status(400).json({ success: false, message: 'Voice text is required.' });
    }

    // Call Python AI Service voice parser
    let parsed = await callAiService('/voice/parse', {
      text,
      language,
    });

    // Built-in JS fallback if Python service unavailable
    if (!parsed) {
      const lower = text.toLowerCase();
      const numMatch = lower.match(/\d+/);
      const amount = numMatch ? parseFloat(numMatch[0]) : 0;

      if (lower.includes('salary') || lower.includes('income') || lower.includes('varumanam')) {
        parsed = {
          intent: 'ADD_INCOME',
          action: 'preview_transaction',
          data: {
            type: 'income',
            amount: amount || 5000,
            category_name: 'Salary',
            transaction_date: new Date().toISOString().substring(0, 10),
            payment_method: 'Bank Transfer',
            description: `Voice: ${text}`,
          },
          response_text: `Found income of ₹${amount || 5000} for Salary. Please confirm to save.`,
          requires_confirmation: true,
        };
      } else if (lower.includes('petrol') || lower.includes('expense') || lower.includes('selavu') || lower.includes('spent')) {
        const cat = lower.includes('petrol') ? 'Petrol / Fuel' : 'Other expenses';
        parsed = {
          intent: 'ADD_EXPENSE',
          action: 'preview_transaction',
          data: {
            type: 'expense',
            amount: amount || 200,
            category_name: cat,
            transaction_date: new Date().toISOString().substring(0, 10),
            payment_method: 'UPI',
            description: `Voice: ${text}`,
          },
          response_text: `Found expense of ₹${amount || 200} for ${cat}. Please confirm to save.`,
          requires_confirmation: true,
        };
      } else if (lower.includes('balance')) {
        parsed = {
          intent: 'QUERY_BALANCE',
          action: 'query',
          response_text: 'Checking your current balance.',
          requires_confirmation: false,
        };
      } else {
        parsed = {
          intent: 'GENERAL_QUERY',
          action: 'chat',
          response_text: `Processed: ${text}`,
          requires_confirmation: false,
        };
      }
    }

    // Match category ID if it's a transaction preview
    if (parsed.data && parsed.data.category_name) {
      const catRes = await db.query(
        'SELECT id, name, icon, color FROM categories WHERE name ILIKE $1 AND type = $2 LIMIT 1',
        [`%${parsed.data.category_name}%`, parsed.data.type]
      );
      if (catRes.rowCount > 0) {
        parsed.data.category_id = catRes.rows[0].id;
        parsed.data.category_icon = catRes.rows[0].icon;
        parsed.data.category_color = catRes.rows[0].color;
      }
    }

    res.status(200).json({
      success: true,
      data: parsed,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  parseVoice,
};
