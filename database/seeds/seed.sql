-- ========================================================
-- DEFAULT SEED DATA FOR SMART FINANCE MANAGER
-- ========================================================

-- Categories Seed
INSERT INTO categories (name, type, icon, color, is_default) VALUES
-- Income Categories
('Salary', 'income', 'payments', '#10B981', TRUE),
('Business income', 'income', 'business_center', '#059669', TRUE),
('Freelancing', 'income', 'laptop', '#34D399', TRUE),
('Investment income', 'income', 'trending_up', '#14B8A6', TRUE),
('Other income', 'income', 'savings', '#06B6D4', TRUE),

-- Expense Categories
('Food', 'expense', 'restaurant', '#F59E0B', TRUE),
('Petrol / Fuel', 'expense', 'local_gas_station', '#EF4444', TRUE),
('Shopping', 'expense', 'shopping_bag', '#EC4899', TRUE),
('Groceries', 'expense', 'shopping_cart', '#8B5CF6', TRUE),
('Rent', 'expense', 'home', '#3B82F6', TRUE),
('Electricity', 'expense', 'bolt', '#F97316', TRUE),
('Medical', 'expense', 'local_hospital', '#DC2626', TRUE),
('Travel', 'expense', 'directions_car', '#6366F1', TRUE),
('EMI', 'expense', 'account_balance', '#4F46E5', TRUE),
('Entertainment', 'expense', 'movie', '#A855F7', TRUE),
('Other expenses', 'expense', 'more_horiz', '#6B7280', TRUE)
ON CONFLICT (name, type) DO NOTHING;
