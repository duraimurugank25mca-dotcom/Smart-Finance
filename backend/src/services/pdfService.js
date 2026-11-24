const PDFDocument = require('pdfkit');

/**
 * Generates a clean, professional financial PDF report
 * @param {Object} options
 * @param {Object} options.user - User details
 * @param {string} options.startDate - Start Date (YYYY-MM-DD)
 * @param {string} options.endDate - End Date (YYYY-MM-DD)
 * @param {string} options.reportType - 'all' | 'income' | 'expense'
 * @param {Array} options.transactions - List of transactions
 * @param {Object} options.summary - Financial summary (income, expense, net savings)
 * @param {Array} options.categoryBreakdown - Category stats
 * @returns {Promise<Buffer>}
 */
const generateFinancialPdf = ({
  user,
  startDate,
  endDate,
  reportType,
  transactions,
  summary,
  categoryBreakdown,
}) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 40,
        bufferPages: true,
        info: {
          Title: `Smart Finance Statement - ${user.full_name}`,
          Author: 'Smart Finance Manager AI',
        },
      });

      const buffers = [];
      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => {
        const pdfData = Buffer.concat(buffers);
        resolve(pdfData);
      });

      const currency = user.preferred_currency || 'INR';

      // Header Banner
      doc.rect(40, 40, 515, 65).fill('#1E293B'); // Slate 800

      doc.fillColor('#FFFFFF')
        .fontSize(20)
        .font('Helvetica-Bold')
        .text('SMART FINANCE MANAGER', 55, 55);

      doc.fontSize(10)
        .font('Helvetica')
        .fillColor('#94A3B8')
        .text('Financial Statement & Analytics Report', 55, 80);

      doc.fontSize(9)
        .fillColor('#CBD5E1')
        .text(`Generated on: ${new Date().toLocaleDateString('en-GB')}`, 400, 55, { align: 'right' });

      // User & Period Info
      doc.moveDown(3);
      const infoTop = 120;
      doc.rect(40, infoTop, 515, 55).fill('#F8FAFC'); // Light grey border box
      doc.rect(40, infoTop, 515, 55).stroke('#E2E8F0');

      doc.fillColor('#334155').fontSize(10).font('Helvetica-Bold')
        .text('Account Holder:', 55, infoTop + 10)
        .font('Helvetica').text(user.full_name, 150, infoTop + 10)
        .font('Helvetica-Bold').text('Email:', 55, infoTop + 25)
        .font('Helvetica').text(user.email, 150, infoTop + 25);

      doc.font('Helvetica-Bold').text('Statement Period:', 320, infoTop + 10)
        .font('Helvetica').text(`${startDate} to ${endDate}`, 430, infoTop + 10)
        .font('Helvetica-Bold').text('Report Type:', 320, infoTop + 25)
        .font('Helvetica').text(reportType.toUpperCase(), 430, infoTop + 25);

      // Financial Metrics Cards
      const cardTop = 190;
      const cardWidth = 160;

      // Card 1: Total Income
      doc.rect(40, cardTop, cardWidth, 55).fill('#ECFDF5').stroke('#A7F3D0');
      doc.fillColor('#065F46').fontSize(9).font('Helvetica-Bold').text('TOTAL INCOME', 50, cardTop + 10);
      doc.fillColor('#047857').fontSize(14).font('Helvetica-Bold')
        .text(`${currency} ${summary.totalIncome.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 50, cardTop + 25);

      // Card 2: Total Expense
      doc.rect(215, cardTop, cardWidth, 55).fill('#FEF2F2').stroke('#FECACA');
      doc.fillColor('#991B1B').fontSize(9).font('Helvetica-Bold').text('TOTAL EXPENSES', 225, cardTop + 10);
      doc.fillColor('#DC2626').fontSize(14).font('Helvetica-Bold')
        .text(`${currency} ${summary.totalExpenses.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 225, cardTop + 25);

      // Card 3: Net Savings
      const netSavings = summary.netSavings;
      const savingsColor = netSavings >= 0 ? '#1E40AF' : '#991B1B';
      const savingsBg = netSavings >= 0 ? '#EFF6FF' : '#FEF2F2';
      const savingsBorder = netSavings >= 0 ? '#BFDBFE' : '#FECACA';

      doc.rect(390, cardTop, cardWidth, 55).fill(savingsBg).stroke(savingsBorder);
      doc.fillColor(savingsColor).fontSize(9).font('Helvetica-Bold').text('NET SAVINGS', 400, cardTop + 10);
      doc.fillColor(savingsColor).fontSize(14).font('Helvetica-Bold')
        .text(`${currency} ${netSavings.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, 400, cardTop + 25);

      // Category Breakdown Summary
      let currentY = 265;
      if (categoryBreakdown && categoryBreakdown.length > 0) {
        doc.fillColor('#1E293B').fontSize(12).font('Helvetica-Bold').text('Category-Wise Breakdown', 40, currentY);
        currentY += 18;

        categoryBreakdown.slice(0, 6).forEach((cat) => {
          const amt = parseFloat(cat.total_amount);
          const percent = summary.totalExpenses > 0 ? ((amt / summary.totalExpenses) * 100).toFixed(1) : '0';
          doc.fillColor('#475569').fontSize(9).font('Helvetica')
            .text(`${cat.name}:`, 45, currentY)
            .text(`${currency} ${amt.toLocaleString('en-IN', { minimumFractionDigits: 2 })} (${percent}%)`, 200, currentY);
          currentY += 14;
        });
        currentY += 10;
      }

      // Transactions Table Header
      currentY = Math.max(currentY, 340);
      doc.fillColor('#1E293B').fontSize(12).font('Helvetica-Bold').text('Transaction Details', 40, currentY);
      currentY += 18;

      // Table Column headers
      doc.rect(40, currentY, 515, 22).fill('#334155');
      doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold')
        .text('DATE', 45, currentY + 7)
        .text('CATEGORY', 115, currentY + 7)
        .text('TYPE', 220, currentY + 7)
        .text('PAYMENT', 280, currentY + 7)
        .text('DESCRIPTION', 360, currentY + 7)
        .text('AMOUNT', 480, currentY + 7, { align: 'right', width: 65 });

      currentY += 22;

      // Table Rows
      transactions.forEach((tx, idx) => {
        // Page break if near bottom
        if (currentY > 750) {
          doc.addPage();
          currentY = 40;
          // Re-draw table header
          doc.rect(40, currentY, 515, 22).fill('#334155');
          doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold')
            .text('DATE', 45, currentY + 7)
            .text('CATEGORY', 115, currentY + 7)
            .text('TYPE', 220, currentY + 7)
            .text('PAYMENT', 280, currentY + 7)
            .text('DESCRIPTION', 360, currentY + 7)
            .text('AMOUNT', 480, currentY + 7, { align: 'right', width: 65 });
          currentY += 22;
        }

        const isEven = idx % 2 === 0;
        if (isEven) {
          doc.rect(40, currentY, 515, 20).fill('#F8FAFC');
        }

        const txDate = tx.transaction_date ? String(tx.transaction_date).substring(0, 10) : '';
        const isIncome = tx.type === 'income';
        const amtColor = isIncome ? '#047857' : '#DC2626';
        const sign = isIncome ? '+' : '-';

        doc.fillColor('#334155').fontSize(8).font('Helvetica')
          .text(txDate, 45, currentY + 6)
          .text(tx.category_name || 'General', 115, currentY + 6, { width: 100, ellipsis: true })
          .text(tx.type.toUpperCase(), 220, currentY + 6)
          .text(tx.payment_method || 'Cash', 280, currentY + 6, { width: 75, ellipsis: true })
          .text(tx.description || '-', 360, currentY + 6, { width: 110, ellipsis: true });

        doc.fillColor(amtColor).font('Helvetica-Bold')
          .text(`${sign} ${parseFloat(tx.amount).toFixed(2)}`, 480, currentY + 6, { align: 'right', width: 65 });

        currentY += 20;
      });

      // Footer
      try {
        const totalPages = doc.bufferedPageRange().count;
        for (let i = 0; i < totalPages; i++) {
          doc.switchToPage(i);
          doc.fillColor('#94A3B8').fontSize(8).font('Helvetica')
            .text('Generated by Smart Finance Manager AI. Strictly Confidential.', 40, 790)
            .text(`Page ${i + 1} of ${totalPages}`, 450, 790, { align: 'right', width: 105 });
        }
      } catch (_) {}

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
};

module.exports = {
  generateFinancialPdf,
};
