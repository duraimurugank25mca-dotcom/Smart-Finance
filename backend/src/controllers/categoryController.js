const db = require('../config/db');

// List categories
const getCategories = async (req, res, next) => {
  try {
    const { type } = req.query;
    let query = 'SELECT id, name, type, icon, color, is_default FROM categories';
    const params = [];

    if (type) {
      query += ' WHERE type = $1';
      params.push(type);
    }

    query += ' ORDER BY type ASC, name ASC';
    const result = await db.query(query, params);

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Create custom category
const createCategory = async (req, res, next) => {
  try {
    const { name, type, icon, color } = req.body;

    if (!name || !type) {
      return res.status(400).json({ success: false, message: 'Category name and type are required.' });
    }

    if (!['income', 'expense'].includes(type)) {
      return res.status(400).json({ success: false, message: 'Type must be either income or expense.' });
    }

    const inserted = await db.query(
      `INSERT INTO categories (name, type, icon, color, is_default)
       VALUES ($1, $2, $3, $4, FALSE)
       ON CONFLICT (name, type) DO UPDATE SET is_default = categories.is_default
       RETURNING id, name, type, icon, color, is_default`,
      [name.trim(), type, icon || 'category', color || '#6366F1']
    );

    res.status(201).json({
      success: true,
      message: 'Category created successfully.',
      data: inserted.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategories,
  createCategory,
};
