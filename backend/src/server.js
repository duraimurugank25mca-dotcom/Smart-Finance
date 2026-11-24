const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const errorHandler = require('./middleware/errorHandler');
const { initScheduler } = require('./services/schedulerService');

// Route imports
const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const reportRoutes = require('./routes/reportRoutes');
const emiRoutes = require('./routes/emiRoutes');
const reminderRoutes = require('./routes/reminderRoutes');
const billRoutes = require('./routes/billRoutes');
const aiRoutes = require('./routes/aiRoutes');
const budgetRoutes = require('./routes/budgetRoutes');
const savingsRoutes = require('./routes/savingsRoutes');
const voiceRoutes = require('./routes/voiceRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Middleware
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));
app.use('/uploads', express.static(uploadDir));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    service: 'Smart Finance Manager Backend API',
    timestamp: new Date().toISOString(),
  });
});

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/emi', emiRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/savings', savingsRoutes);
app.use('/api/voice', voiceRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Resource not found at ${req.method} ${req.originalUrl}`,
  });
});

// Centralized Error Handler
app.use(errorHandler);

// Start Server
const server = app.listen(PORT, () => {
  console.log(`===============================================`);
  console.log(`SMART FINANCE MANAGER BACKEND ACTIVE ON PORT ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Database: ${process.env.DB_NAME || 'smart_finance'} on port ${process.env.DB_PORT || '54321'}`);
  console.log(`===============================================`);

  // Initialize automated background tasks
  initScheduler();
});

module.exports = { app, server };
