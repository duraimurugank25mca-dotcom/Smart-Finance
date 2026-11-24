const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function seedDatabase() {
  console.log('Seeding Smart Finance Database with comprehensive realistic data...');

  try {
    // 1. Ensure categories
    const categoriesSeed = [
      ['Salary', 'income', 'payments', '#10B981'],
      ['Business income', 'income', 'business_center', '#059669'],
      ['Freelancing', 'income', 'laptop', '#34D399'],
      ['Investment income', 'income', 'trending_up', '#14B8A6'],
      ['Other income', 'income', 'savings', '#06B6D4'],
      ['Food', 'expense', 'restaurant', '#F59E0B'],
      ['Petrol / Fuel', 'expense', 'local_gas_station', '#EF4444'],
      ['Shopping', 'expense', 'shopping_bag', '#EC4899'],
      ['Groceries', 'expense', 'shopping_cart', '#8B5CF6'],
      ['Rent', 'expense', 'home', '#3B82F6'],
      ['Electricity', 'expense', 'bolt', '#F97316'],
      ['Medical', 'expense', 'local_hospital', '#DC2626'],
      ['Travel', 'expense', 'directions_car', '#6366F1'],
      ['EMI', 'expense', 'account_balance', '#4F46E5'],
      ['Entertainment', 'expense', 'movie', '#A855F7'],
      ['Other expenses', 'expense', 'more_horiz', '#6B7280'],
    ];

    for (const [name, type, icon, color] of categoriesSeed) {
      await db.query(
        `INSERT INTO categories (name, type, icon, color, is_default)
         VALUES ($1, $2, $3, $4, TRUE)
         ON CONFLICT (name, type) DO UPDATE SET icon = $3, color = $4`,
        [name, type, icon, color]
      );
    }
    console.log('Default categories initialized.');

    // 2. Insert Users
    const salt = await bcrypt.genSalt(10);
    const adminPasswordHash = await bcrypt.hash('Admin@123', salt);
    const userPasswordHash = await bcrypt.hash('User@123', salt);

    const adminRes = await db.query(
      `INSERT INTO users (full_name, email, password_hash, role, phone, preferred_currency, preferred_language)
       VALUES ('Admin Administrator', 'admin@smartfinance.com', $1, 'ADMIN', '+91 9876543210', 'INR', 'en')
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [adminPasswordHash]
    );
    const adminId = adminRes.rows[0].id;

    const userRes = await db.query(
      `INSERT INTO users (full_name, email, password_hash, role, phone, preferred_currency, preferred_language)
       VALUES ('Durai Finance', 'user@smartfinance.com', $1, 'USER', '+91 9840123456', 'INR', 'en')
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [userPasswordHash]
    );
    const userId = userRes.rows[0].id;
    console.log(`Users verified. Admin ID: ${adminId}, User ID: ${userId}`);

    // Map categories
    const catMap = {};
    const allCats = await db.query('SELECT id, name, type FROM categories');
    allCats.rows.forEach((c) => {
      catMap[`${c.type}:${c.name}`] = c.id;
    });

    // 3. Transactions for Demo User
    // Clear old test transactions for demo user to ensure clean seed
    await db.query('DELETE FROM transactions WHERE user_id = $1', [userId]);

    const now = new Date();
    const currYear = now.getFullYear();
    const currMonth = now.getMonth() + 1;

    // Helper for date string with automatic month/year wrapping
    const dStr = (y, m, d) => {
      const dt = new Date(y, m - 1, d);
      return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, '0')}-${String(dt.getDate()).padStart(2, '0')}`;
    };

    const sampleTransactions = [
      // Current Month Incomes
      { cat: 'income:Salary', type: 'income', amt: 65000, date: dStr(currYear, currMonth, 1), method: 'Bank Transfer', desc: 'Monthly Salary Credit - Tech Corp' },
      { cat: 'income:Freelancing', type: 'income', amt: 18500, date: dStr(currYear, currMonth, 10), method: 'UPI', desc: 'Flutter App UI Design Project' },
      { cat: 'income:Investment income', type: 'income', amt: 3200, date: dStr(currYear, currMonth, 14), method: 'Bank Transfer', desc: 'Mutual Fund Quarterly Dividend' },

      // Current Month Expenses
      { cat: 'expense:Rent', type: 'expense', amt: 18000, date: dStr(currYear, currMonth, 2), method: 'Net Banking', desc: 'Apartment Monthly Rent' },
      { cat: 'expense:Electricity', type: 'expense', amt: 1850, date: dStr(currYear, currMonth, 5), method: 'UPI', desc: 'TNEB Electricity Bill' },
      { cat: 'expense:Petrol / Fuel', type: 'expense', amt: 2200, date: dStr(currYear, currMonth, 3), method: 'UPI', desc: 'Bharat Petroleum Full Tank' },
      { cat: 'expense:Petrol / Fuel', type: 'expense', amt: 1500, date: dStr(currYear, currMonth, 12), method: 'UPI', desc: 'HP Petrol Pump Refill' },
      { cat: 'expense:Groceries', type: 'expense', amt: 4650, date: dStr(currYear, currMonth, 4), method: 'Debit Card', desc: 'DMart Supermarket Monthly Groceries' },
      { cat: 'expense:Food', type: 'expense', amt: 680, date: dStr(currYear, currMonth, 6), method: 'UPI', desc: 'Swiggy Weekend Dinner' },
      { cat: 'expense:Food', type: 'expense', amt: 420, date: dStr(currYear, currMonth, 9), method: 'UPI', desc: 'Cafe Coffee Day Meet' },
      { cat: 'expense:Food', type: 'expense', amt: 850, date: dStr(currYear, currMonth, 13), method: 'Credit Card', desc: 'Barbeque Nation Family Dinner' },
      { cat: 'expense:EMI', type: 'expense', amt: 4500, date: dStr(currYear, currMonth, 8), method: 'Bank Transfer', desc: 'Royal Enfield Bike EMI' },
      { cat: 'expense:Medical', type: 'expense', amt: 1250, date: dStr(currYear, currMonth, 11), method: 'UPI', desc: 'Apollo Pharmacy Health Supplements' },
      { cat: 'expense:Entertainment', type: 'expense', amt: 950, date: dStr(currYear, currMonth, 7), method: 'UPI', desc: 'IMAX Movie Tickets & Snacks' },
      { cat: 'expense:Shopping', type: 'expense', amt: 2800, date: dStr(currYear, currMonth, 14), method: 'Credit Card', desc: 'Zara Casual Shirts' },

      // Previous Month
      { cat: 'income:Salary', type: 'income', amt: 65000, date: dStr(currYear, currMonth - 1, 1), method: 'Bank Transfer', desc: 'Previous Month Salary' },
      { cat: 'income:Freelancing', type: 'income', amt: 12000, date: dStr(currYear, currMonth - 1, 15), method: 'UPI', desc: 'React Website Migration' },
      { cat: 'expense:Rent', type: 'expense', amt: 18000, date: dStr(currYear, currMonth - 1, 2), method: 'Net Banking', desc: 'Previous Month Rent' },
      { cat: 'expense:EMI', type: 'expense', amt: 4500, date: dStr(currYear, currMonth - 1, 8), method: 'Bank Transfer', desc: 'Royal Enfield Bike EMI' },
      { cat: 'expense:Groceries', type: 'expense', amt: 5200, date: dStr(currYear, currMonth - 1, 6), method: 'Debit Card', desc: 'Monthly Provisions' },
      { cat: 'expense:Petrol / Fuel', type: 'expense', amt: 3400, date: dStr(currYear, currMonth - 1, 11), method: 'UPI', desc: 'Fuel Expenses' },
      { cat: 'expense:Food', type: 'expense', amt: 3200, date: dStr(currYear, currMonth - 1, 18), method: 'UPI', desc: 'Dining & Food Orders' },
    ];

    for (const tx of sampleTransactions) {
      const catId = catMap[tx.cat];
      if (catId) {
        await db.query(
          `INSERT INTO transactions (user_id, category_id, type, amount, transaction_date, payment_method, description)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [userId, catId, tx.type, tx.amt, tx.date, tx.method, tx.desc]
        );
      }
    }
    console.log(`Inserted ${sampleTransactions.length} realistic sample transactions.`);

    // 4. EMIs
    await db.query('DELETE FROM emi_details WHERE user_id = $1', [userId]);

    const emi1 = await db.query(
      `INSERT INTO emi_details (user_id, emi_name, loan_provider, emi_amount, due_date, payment_frequency, category, total_installments, paid_installments, status)
       VALUES ($1, 'Royal Enfield Hunter 350', 'HDFC Bank', 4500.00, $2, 'monthly', 'Bike Loan', 24, 7, 'active')
       RETURNING id`,
      [userId, dStr(currYear, currMonth, 20)]
    );

    const emi2 = await db.query(
      `INSERT INTO emi_details (user_id, emi_name, loan_provider, emi_amount, due_date, payment_frequency, category, total_installments, paid_installments, status)
       VALUES ($1, 'MacBook Pro M3 Max', 'ICICI Bank', 6250.00, $2, 'monthly', 'Personal Loan', 12, 4, 'active')
       RETURNING id`,
      [userId, dStr(currYear, currMonth, 28)]
    );

    const emi3 = await db.query(
      `INSERT INTO emi_details (user_id, emi_name, loan_provider, emi_amount, due_date, payment_frequency, category, total_installments, paid_installments, status)
       VALUES ($1, 'Airtel Fiber Broadband', 'Airtel Broadband', 1179.00, $2, 'monthly', 'Internet Bill', 12, 11, 'active')
       RETURNING id`,
      [userId, dStr(currYear, currMonth, 25)]
    );

    // Schedule reminders
    await db.query(
      `INSERT INTO reminders (user_id, emi_id, title, reminder_date, reminder_type)
       VALUES 
       ($1, $2, 'Reminder: Royal Enfield Hunter 350 EMI due soon', $3, 'emi'),
       ($1, $4, 'Reminder: MacBook Pro M3 Max EMI due soon', $5, 'emi')`,
      [
        userId,
        emi1.rows[0].id,
        dStr(currYear, currMonth, 18),
        emi2.rows[0].id,
        dStr(currYear, currMonth, 26),
      ]
    );
    console.log('EMI details and reminders created.');

    // 5. Budgets
    await db.query('DELETE FROM budgets WHERE user_id = $1', [userId]);
    const monthYear = `${currYear}-${String(currMonth).padStart(2, '0')}`;

    const sampleBudgets = [
      { cat: 'expense:Food', amt: 6000 },
      { cat: 'expense:Petrol / Fuel', amt: 4000 },
      { cat: 'expense:Shopping', amt: 5000 },
      { cat: 'expense:Entertainment', amt: 2500 },
      { cat: 'expense:Groceries', amt: 6500 },
    ];

    for (const b of sampleBudgets) {
      const catId = catMap[b.cat];
      if (catId) {
        await db.query(
          `INSERT INTO budgets (user_id, category_id, month_year, amount, alert_threshold)
           VALUES ($1, $2, $3, $4, 80.0)`,
          [userId, catId, monthYear, b.amt]
        );
      }
    }
    console.log('Category budgets created.');

    // 6. Savings Goals
    await db.query('DELETE FROM savings_goals WHERE user_id = $1', [userId]);
    await db.query(
      `INSERT INTO savings_goals (user_id, goal_name, target_amount, current_amount, target_date, category, is_completed)
       VALUES 
       ($1, 'Emergency Fund (6 Months)', 150000.00, 55000.00, $2, 'Emergency', false),
       ($1, 'Goa Trip with Friends', 35000.00, 24500.00, $3, 'Travel', false),
       ($1, 'Apple Watch Ultra', 85000.00, 68000.00, $4, 'Gadget', false)`,
      [
        userId,
        dStr(currYear + 1, 6, 30),
        dStr(currYear, currMonth + 2, 15),
        dStr(currYear, currMonth + 1, 20),
      ]
    );
    console.log('Savings goals created.');

    // 7. Scanned Bills
    await db.query('DELETE FROM bill_scans WHERE user_id = $1', [userId]);
    const billRes = await db.query(
      `INSERT INTO bill_scans (user_id, shop_name, bill_number, bill_date, subtotal, gst, discount, final_amount, detected_category_id, raw_ocr_text, status)
       VALUES ($1, 'Bharat Petroleum Fuel Station', 'BPCL-98421', CURRENT_TIMESTAMP - INTERVAL '3 days', 2000.00, 200.00, 0.00, 2200.00, $2, 'BHARAT PETROLEUM\nINVOICE: BPCL-98421\nPETROL POWER: 20.3L\nRATE: 108.30\nTOTAL: 2200.00', 'confirmed')
       RETURNING id`,
      [userId, catMap['expense:Petrol / Fuel']]
    );

    await db.query(
      `INSERT INTO bill_items (bill_scan_id, item_name, quantity, unit_price, total_price)
       VALUES ($1, 'Speed Petrol Fuel', 20.31, 108.32, 2200.00)`,
      [billRes.rows[0].id]
    );

    // 8. Notifications
    await db.query('DELETE FROM notification_logs WHERE user_id = $1', [userId]);
    await db.query(
      `INSERT INTO notification_logs (user_id, title, body, notification_type)
       VALUES 
       ($1, 'Welcome to Smart Finance Manager!', 'Your personal AI-driven financial assistant is ready to help you track spending, prevent wastage, and achieve your goals.', 'system'),
       ($1, 'Upcoming EMI Reminder', 'Your Royal Enfield Hunter 350 EMI of ₹4,500 is due on the 20th of this month.', 'emi'),
       ($1, 'Budget Advisory', 'You have used 65% of your Food dining budget for this month. Stay steady!', 'budget_warning')`,
      [userId]
    );

    console.log('Seeding completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Error during database seed:', err);
    process.exit(1);
  }
}

seedDatabase();
