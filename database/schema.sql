-- ========================================================
-- SMART FINANCE MANAGER DATABASE SCHEMA (PostgreSQL)
-- Fully normalized with Constraints, Indexes, and Strict Typing
-- ========================================================

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    phone VARCHAR(20),
    preferred_currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 2. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    icon VARCHAR(60) NOT NULL DEFAULT 'category',
    color VARCHAR(20) NOT NULL DEFAULT '#6366F1',
    is_default BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_category_name_type UNIQUE (name, type)
);

CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);

-- 3. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash' CHECK (payment_method IN ('Cash', 'UPI', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Net Banking', 'Other')),
    description TEXT,
    attachment_url TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(user_id, type);
CREATE INDEX IF NOT EXISTS idx_transactions_user_active ON transactions(user_id, is_deleted);

-- 4. EMI DETAILS TABLE
CREATE TABLE IF NOT EXISTS emi_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emi_name VARCHAR(150) NOT NULL,
    loan_provider VARCHAR(150) NOT NULL,
    emi_amount NUMERIC(14, 2) NOT NULL CHECK (emi_amount > 0),
    due_date DATE NOT NULL,
    payment_frequency VARCHAR(30) NOT NULL DEFAULT 'monthly' CHECK (payment_frequency IN ('monthly', 'quarterly', 'yearly')),
    category VARCHAR(60) NOT NULL DEFAULT 'Personal Loan',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paid', 'overdue', 'closed')),
    total_installments INT DEFAULT 12,
    paid_installments INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_emi_user_status ON emi_details(user_id, status);
CREATE INDEX IF NOT EXISTS idx_emi_due_date ON emi_details(due_date);

-- 5. REMINDERS TABLE
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emi_id UUID REFERENCES emi_details(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    reminder_date DATE NOT NULL,
    reminder_time TIME NOT NULL DEFAULT '09:00:00',
    reminder_type VARCHAR(40) NOT NULL DEFAULT 'emi' CHECK (reminder_type IN ('emi', 'bill', 'custom')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'dismissed', 'paid')),
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_date ON reminders(user_id, reminder_date);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON reminders(status, reminder_date);

-- 6. BUDGETS TABLE
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    month_year VARCHAR(7) NOT NULL, -- Format: YYYY-MM
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    alert_threshold NUMERIC(5, 2) NOT NULL DEFAULT 80.00 CHECK (alert_threshold > 0 AND alert_threshold <= 100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_category_month UNIQUE (user_id, category_id, month_year)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON budgets(user_id, month_year);

-- 7. SAVINGS GOALS TABLE
CREATE TABLE IF NOT EXISTS savings_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_name VARCHAR(150) NOT NULL,
    target_amount NUMERIC(14, 2) NOT NULL CHECK (target_amount > 0),
    current_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    target_date DATE NOT NULL,
    category VARCHAR(60) NOT NULL DEFAULT 'General',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_savings_user ON savings_goals(user_id, is_completed);

-- 8. BILL SCANS TABLE
CREATE TABLE IF NOT EXISTS bill_scans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shop_name VARCHAR(200),
    bill_number VARCHAR(100),
    bill_date TIMESTAMP WITH TIME ZONE,
    subtotal NUMERIC(14, 2) DEFAULT 0,
    gst NUMERIC(14, 2) DEFAULT 0,
    discount NUMERIC(14, 2) DEFAULT 0,
    final_amount NUMERIC(14, 2) NOT NULL CHECK (final_amount >= 0),
    detected_category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    image_url TEXT,
    raw_ocr_text TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'scanned' CHECK (status IN ('scanned', 'confirmed', 'discarded')),
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bills_user_date ON bill_scans(user_id, bill_date);
CREATE INDEX IF NOT EXISTS idx_bills_shop ON bill_scans(user_id, shop_name);

-- 9. BILL ITEMS TABLE
CREATE TABLE IF NOT EXISTS bill_items (
    id SERIAL PRIMARY KEY,
    bill_scan_id UUID NOT NULL REFERENCES bill_scans(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (unit_price >= 0),
    total_price NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (total_price >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bill_items_scan ON bill_items(bill_scan_id);

-- 10. AI INSIGHTS TABLE
CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    insight_type VARCHAR(40) NOT NULL CHECK (insight_type IN ('wastage', 'income_improvement', 'monthly_summary', 'anomaly', 'budget_alert')),
    title VARCHAR(255) NOT NULL,
    content JSONB NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high')),
    period VARCHAR(20) NOT NULL, -- e.g. '2026-11'
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_user_type ON ai_insights(user_id, insight_type);
CREATE INDEX IF NOT EXISTS idx_ai_insights_period ON ai_insights(user_id, period);

-- 11. NOTIFICATION LOGS TABLE
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(40) NOT NULL DEFAULT 'system' CHECK (notification_type IN ('emi', 'budget_warning', 'system', 'bill_scan', 'ai_report')),
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notification_user ON notification_logs(user_id, is_read, sent_at DESC);
