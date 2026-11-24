const http = require('http');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

/**
 * Helper to call AI Service HTTP endpoint with fallback
 */
const callAiService = (endpoint, payload) => {
  return new Promise((resolve) => {
    try {
      const dataString = JSON.stringify(payload);
      const url = new URL(endpoint, AI_SERVICE_URL);

      const options = {
        hostname: url.hostname,
        port: url.port || 8000,
        path: url.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(dataString),
        },
        timeout: 4000,
      };

      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            resolve(parsed.data || parsed);
          } catch (_) {
            resolve(null);
          }
        });
      });

      req.on('error', () => resolve(null));
      req.on('timeout', () => {
        req.destroy();
        resolve(null);
      });

      req.write(dataString);
      req.end();
    } catch (_) {
      resolve(null);
    }
  });
};

/**
 * Built-in JS fallback for wastage analysis
 */
const fallbackWastageAnalysis = (transactions, monthlyIncome) => {
  const expenses = transactions.filter((t) => t.type === 'expense');
  const totalExpense = expenses.reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);

  // Group by category
  const categoryTotals = {};
  expenses.forEach((t) => {
    const cat = t.category_name || 'General';
    categoryTotals[cat] = (categoryTotals[cat] || 0) + parseFloat(t.amount || 0);
  });

  const discretionaryCategories = ['Food', 'Shopping', 'Entertainment', 'Other expenses'];
  let discretionaryTotal = 0;
  Object.keys(categoryTotals).forEach((cat) => {
    if (discretionaryCategories.includes(cat)) {
      discretionaryTotal += categoryTotals[cat];
    }
  });

  const discretionaryPercentage = totalExpense > 0 ? (discretionaryTotal / totalExpense) * 100 : 0;
  const potentialSavings = discretionaryTotal * 0.2;

  const recommendations = [];
  if (discretionaryPercentage > 30) {
    recommendations.push(
      `Discretionary spending (Food, Shopping, Entertainment) makes up ${discretionaryPercentage.toFixed(1)}% of your expenses. Capping non-essential purchases could save around ₹${potentialSavings.toFixed(0)} this month.`
    );
  }

  // Anomalies: spends > ₹2000
  const anomalies = expenses
    .filter((t) => parseFloat(t.amount) > 2000)
    .slice(0, 3)
    .map((t) => ({
      amount: parseFloat(t.amount),
      category: t.category_name,
      date: t.transaction_date,
      description: t.description,
      insight: `High single expenditure of ₹${parseFloat(t.amount).toLocaleString('en-IN')} on ${t.category_name}.`,
    }));

  if (anomalies.length > 0) {
    recommendations.push(`Detected ${anomalies.length} high-value expenditures this month. Review them to optimize cash flow.`);
  }

  if (recommendations.length === 0) {
    recommendations.push('Your expenses are well-balanced within standard essential spending boundaries.');
  }

  return {
    anomalies,
    repeated_purchases: [],
    discretionary_total: discretionaryTotal,
    discretionary_percentage: parseFloat(discretionaryPercentage.toFixed(1)),
    estimated_monthly_wastage_potential: potentialSavings,
    recommendations,
    severity: discretionaryPercentage > 45 ? 'high' : discretionaryPercentage > 25 ? 'medium' : 'low',
  };
};

/**
 * Built-in JS fallback for income improvement
 */
const fallbackIncomeAnalysis = (transactions, totalIncome, totalExpense) => {
  const netSavings = totalIncome - totalExpense;
  const savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;
  const emergencyFund = Math.max(50000, totalExpense * 3);

  const strategies = [
    `Current savings rate is ${savingsRate.toFixed(1)}%. Maintain at least 20% savings for financial resilience.`,
    `Recommended emergency fund target: ₹${emergencyFund.toLocaleString('en-IN')} (equivalent to 3 months of baseline living expenses).`,
    'Automate transfers to savings immediately on salary deposit day to avoid lifestyle creep.',
  ];

  return {
    current_savings_rate: parseFloat(savingsRate.toFixed(1)),
    income_streams_count: 1,
    recommended_emergency_fund: emergencyFund,
    net_surplus: netSavings,
    strategies,
  };
};

/**
 * Built-in JS fallback for chat
 */
const fallbackChatAnswer = (question, context) => {
  const q = question.toLowerCase();
  const balance = parseFloat(context.totalBalance || 0);
  const monthlyIncome = parseFloat(context.monthlyIncome || 0);
  const monthlyExpenses = parseFloat(context.monthlyExpenses || 0);
  const savings = parseFloat(context.monthlySavings || 0);
  const topCat = context.topExpenseCategory || 'General';

  if (q.includes('balance') || q.includes('iruku')) {
    return `Your net balance is ₹${balance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}.`;
  }
  if (q.includes('today') || q.includes('innaiku')) {
    return `You have spent ₹${parseFloat(context.todayExpenses || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })} today.`;
  }
  if (q.includes('income this month') || q.includes('month income')) {
    return `Your recorded income this month is ₹${monthlyIncome.toLocaleString('en-IN', { minimumFractionDigits: 2 })}.`;
  }
  if (q.includes('highest') || q.includes('top')) {
    return `Your highest spending category this month is ${topCat}.`;
  }
  if (q.includes('save') || q.includes('savings')) {
    return `Your current monthly savings is ₹${savings.toLocaleString('en-IN', { minimumFractionDigits: 2 })} (${context.savingsPercentage || 0}%). Target saving at least 20% each month.`;
  }

  return `Financial Overview: Balance: ₹${balance.toLocaleString('en-IN')}, Income: ₹${monthlyIncome.toLocaleString('en-IN')}, Expenses: ₹${monthlyExpenses.toLocaleString('en-IN')}, Savings: ₹${savings.toLocaleString('en-IN')}.`;
};

module.exports = {
  callAiService,
  fallbackWastageAnalysis,
  fallbackIncomeAnalysis,
  fallbackChatAnswer,
};
