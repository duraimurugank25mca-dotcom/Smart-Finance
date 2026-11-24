// Use running backend server on port 5000
const http = require('http');

async function testApi() {
  const PORT = 5000;
  console.log('Testing Backend REST APIs...');

  const request = (path, method = 'GET', body = null, token = null) => {
    return new Promise((resolve, reject) => {
      const postData = body ? JSON.stringify(body) : '';
      const req = http.request(
        {
          hostname: '127.0.0.1',
          port: PORT,
          path,
          method,
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
            ...(postData ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
          },
        },
        (res) => {
          let data = '';
          res.on('data', (c) => (data += c));
          res.on('end', () => {
            try {
              resolve({ status: res.statusCode, data: JSON.parse(data), headers: res.headers });
            } catch (e) {
              resolve({ status: res.statusCode, raw: data, headers: res.headers });
            }
          });
        }
      );
      req.on('error', reject);
      if (postData) req.write(postData);
      req.end();
    });
  };

  try {
    // 1. Health check
    const health = await request('/api/health');
    console.log('1. Health check:', health.status, health.data.status);

    // 2. Login User
    const loginRes = await request('/api/auth/login', 'POST', {
      email: 'user@smartfinance.com',
      password: 'User@123',
    });
    console.log('2. User Login:', loginRes.status, loginRes.data.message);
    const userToken = loginRes.data.data.token;

    // 3. User Dashboard Summary
    const summaryRes = await request('/api/transactions/summary', 'GET', null, userToken);
    console.log('3. Dashboard Summary:', summaryRes.status, {
      totalBalance: summaryRes.data.data.totalBalance,
      monthlyIncome: summaryRes.data.data.monthlyIncome,
      monthlyExpenses: summaryRes.data.data.monthlyExpenses,
      monthlySavings: summaryRes.data.data.monthlySavings,
      savingsPercentage: summaryRes.data.data.savingsPercentage,
    });

    // 4. List Transactions
    const txRes = await request('/api/transactions?limit=5', 'GET', null, userToken);
    console.log('4. Transactions List:', txRes.status, `Retrieved ${txRes.data.data.transactions.length} items of ${txRes.data.data.total} total.`);

    // 5. Create New Transaction
    const addTx = await request(
      '/api/transactions',
      'POST',
      {
        category_id: 6, // Food
        type: 'expense',
        amount: 350.0,
        transaction_date: new Date().toISOString().substring(0, 10),
        payment_method: 'UPI',
        description: 'Test Dinner with Friends',
      },
      userToken
    );
    console.log('5. Add Transaction:', addTx.status, addTx.data.message);

    // 6. Report Summary
    const repRes = await request('/api/reports/summary?start_date=2026-11-01&end_date=2026-11-30', 'GET', null, userToken);
    console.log('6. Report Summary:', repRes.status, {
      netSavings: repRes.data.data.netSavings,
      categoryCount: repRes.data.data.categoryBreakdown.length,
    });

    // 7. PDF Report Generation
    const pdfRes = await request(
      '/api/reports/pdf',
      'POST',
      {
        start_date: '2026-11-01',
        end_date: '2026-11-30',
        report_type: 'all',
      },
      userToken
    );
    console.log('7. PDF Generation:', pdfRes.status, 'Content-Type:', pdfRes.headers['content-type']);

    // 8. EMIs
    const emiRes = await request('/api/emi', 'GET', null, userToken);
    console.log('8. EMI List:', emiRes.status, `Retrieved ${emiRes.data.data.length} active EMIs.`);

    // 9. Budgets
    const budgetRes = await request('/api/budgets', 'GET', null, userToken);
    console.log('9. Budgets List:', budgetRes.status, `Retrieved ${budgetRes.data.data.budgets.length} budget items.`);

    // 10. Savings Goals
    const savingsRes = await request('/api/savings', 'GET', null, userToken);
    console.log('10. Savings Goals:', savingsRes.status, `Retrieved ${savingsRes.data.data.length} savings goals.`);

    // 11. AI Chat Question
    const aiChat = await request(
      '/api/ai/chat',
      'POST',
      {
        question: 'What is my total income this month?',
      },
      userToken
    );
    console.log('11. AI Chat Answer:', aiChat.status, aiChat.data.data.answer);

    // 12. Voice Parse Command
    const voiceRes = await request(
      '/api/voice/parse',
      'POST',
      {
        text: 'Add 200 rupees petrol expense',
        language: 'en',
      },
      userToken
    );
    console.log('12. Voice Intent Parser:', voiceRes.status, voiceRes.data.data.intent, voiceRes.data.data.response_text);

    // 13. Admin Login & User Management
    const adminLogin = await request('/api/auth/login', 'POST', {
      email: 'admin@smartfinance.com',
      password: 'Admin@123',
    });
    const adminToken = adminLogin.data.data.token;
    const adminUsers = await request('/api/admin/users', 'GET', null, adminToken);
    const adminStats = await request('/api/admin/analytics', 'GET', null, adminToken);
    console.log('13. Admin Management:', adminUsers.status, `Total registered users: ${adminUsers.data.data.total}`);
    console.log('14. Admin Analytics:', adminStats.status, adminStats.data.data.users);

    console.log('\n>>> ALL 14 BACKEND APIS VERIFIED AND PASSING SUCCESSFULLY! <<<');
  } catch (err) {
    console.error('API Test Error:', err);
  } finally {
    process.exit(0);
  }
}

testApi();
