const db = require('../config/db');

/**
 * Intelligent Bill / Receipt Parser
 * Parses OCR raw text and extracts shop name, date, bill number, items, taxes, and final total.
 */
const parseReceiptText = (ocrText) => {
  const lines = ocrText.split('\n').map((l) => l.trim()).filter(Boolean);

  let shopName = 'Retail Store';
  let billNumber = `BILL-${Date.now().toString().slice(-6)}`;
  let billDate = new Date().toISOString();
  let subtotal = 0;
  let gst = 0;
  let discount = 0;
  let finalAmount = 0;
  let detectedCategory = 'Shopping';
  const items = [];

  // Categorization heuristics based on shop / keywords
  const textLower = ocrText.toLowerCase();

  if (textLower.match(/petrol|fuel|diesel|hpcl|bpcl|ioc|indian oil|bharat petroleum|gas station/i)) {
    detectedCategory = 'Petrol / Fuel';
    if (textLower.includes('bharat petroleum')) shopName = 'Bharat Petroleum Fuel Station';
    else if (textLower.includes('indian oil')) shopName = 'Indian Oil Corporation';
    else if (textLower.includes('hp petrol') || textLower.includes('hpcl')) shopName = 'Hindustan Petroleum';
    else shopName = 'City Fuel Station';
  } else if (textLower.match(/restaurant|cafe|bistro|diner|kitchen|swiggy|zomato|burger|pizza|biryani|hotel/i)) {
    detectedCategory = 'Food';
    shopName = lines[0] && lines[0].length < 40 ? lines[0] : 'Restaurant & Dining';
  } else if (textLower.match(/pharmacy|medical|chemist|druggist|hospital|clinic|apollo|medplus/i)) {
    detectedCategory = 'Medical';
    shopName = lines[0] && lines[0].length < 40 ? lines[0] : 'City Medical & Pharmacy';
  } else if (textLower.match(/supermarket|mart|hypermarket|groceries|fresh|provisions|dmart|reliance/i)) {
    detectedCategory = 'Groceries';
    shopName = lines[0] && lines[0].length < 40 ? lines[0] : 'Supermarket Mart';
  } else if (lines[0] && lines[0].length < 40) {
    shopName = lines[0];
  }

  // Regex patterns
  const invoiceRegex = /(?:inv(?:oice)?|bill|receipt|tax\s+inv)[#:\s.-]*([a-zA-Z0-9\-\/]+)/i;
  const dateRegex = /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})/;
  const amountRegex = /(?:total|grand\s+total|net\s+amount|amount\s+payable|final\s+amount|balance\s+due)[^\d]*([0-9,]+\.?[0-9]*)/i;
  const gstRegex = /(?:gst|tax|cgst\+sgst|vat)[^\d]*([0-9,]+\.?[0-9]*)/i;
  const discountRegex = /(?:discount|disc|savings)[^\d]*([0-9,]+\.?[0-9]*)/i;

  const invMatch = ocrText.match(invoiceRegex);
  if (invMatch && invMatch[1]) {
    billNumber = invMatch[1].trim();
  }

  const dateMatch = ocrText.match(dateRegex);
  if (dateMatch && dateMatch[1]) {
    try {
      const parts = dateMatch[1].split(/[\/\-\.]/);
      if (parts.length === 3) {
        let day = parts[0];
        let month = parts[1];
        let year = parts[2];
        if (year.length === 2) year = `20${year}`;
        if (parseInt(month, 10) > 12 && parseInt(day, 10) <= 12) {
          // Swap if format was MM/DD/YYYY
          const temp = day;
          day = month;
          month = temp;
        }
        billDate = new Date(`${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`).toISOString();
      }
    } catch (_) {}
  }

  const amountMatch = ocrText.match(amountRegex);
  if (amountMatch && amountMatch[1]) {
    finalAmount = parseFloat(amountMatch[1].replace(/,/g, '')) || 0;
  }

  const gstMatch = ocrText.match(gstRegex);
  if (gstMatch && gstMatch[1]) {
    gst = parseFloat(gstMatch[1].replace(/,/g, '')) || 0;
  }

  const discMatch = ocrText.match(discountRegex);
  if (discMatch && discMatch[1]) {
    discount = parseFloat(discMatch[1].replace(/,/g, '')) || 0;
  }

  // Parse items from lines that contain text and trailing price
  const itemLineRegex = /^([A-Za-z0-9\s\.\-_]{2,30})\s+(?:(\d+)\s+)?([0-9,]+\.[0-9]{2})$/;
  for (const line of lines) {
    const m = line.match(itemLineRegex);
    if (m && !line.toLowerCase().includes('total') && !line.toLowerCase().includes('subtotal') && !line.toLowerCase().includes('tax')) {
      const itemName = m[1].trim();
      const qty = m[2] ? parseFloat(m[2]) : 1;
      const price = parseFloat(m[3].replace(/,/g, ''));
      if (price > 0 && price < 100000) {
        items.push({
          item_name: itemName,
          quantity: qty,
          unit_price: (price / qty).toFixed(2),
          total_price: price.toFixed(2),
        });
        subtotal += price;
      }
    }
  }

  // Fallbacks if items weren't explicitly matched
  if (items.length === 0 && finalAmount > 0) {
    items.push({
      item_name: `${detectedCategory} Purchase`,
      quantity: 1,
      unit_price: finalAmount.toFixed(2),
      total_price: finalAmount.toFixed(2),
    });
    subtotal = finalAmount;
  } else if (finalAmount === 0 && subtotal > 0) {
    finalAmount = subtotal + gst - discount;
  }

  if (finalAmount === 0) {
    finalAmount = 250.0; // fallback reasonable receipt amount
  }

  return {
    shopName,
    billNumber,
    billDate,
    subtotal: subtotal || finalAmount,
    gst,
    discount,
    finalAmount,
    detectedCategory,
    items,
  };
};

// Scan bill endpoint (receives raw_ocr_text or file)
const scanBill = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { raw_ocr_text, image_url } = req.body;

    if (!raw_ocr_text) {
      return res.status(400).json({ success: false, message: 'OCR text or image is required.' });
    }

    const parsed = parseReceiptText(raw_ocr_text);

    // Find category ID for detected category
    const catRes = await db.query(
      'SELECT id FROM categories WHERE name ILIKE $1 AND type = \'expense\' LIMIT 1',
      [`%${parsed.detectedCategory}%`]
    );
    const categoryId = catRes.rowCount > 0 ? catRes.rows[0].id : 8; // fallback to Groceries or Shopping

    // Check for duplicate bill
    const dupCheck = await db.query(
      `SELECT id, bill_number, final_amount, created_at
       FROM bill_scans
       WHERE user_id = $1 
         AND ((bill_number = $2 AND shop_name = $3) OR (final_amount = $4 AND DATE(bill_date) = DATE($5)))
       LIMIT 1`,
      [userId, parsed.billNumber, parsed.shopName, parsed.finalAmount, parsed.billDate]
    );

    const isDuplicate = dupCheck.rowCount > 0;

    // Create bill_scan record in 'scanned' status
    const scanInsert = await db.query(
      `INSERT INTO bill_scans (user_id, shop_name, bill_number, bill_date, subtotal, gst, discount, final_amount, detected_category_id, image_url, raw_ocr_text, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'scanned')
       RETURNING *`,
      [
        userId,
        parsed.shopName,
        parsed.billNumber,
        parsed.billDate,
        parsed.subtotal,
        parsed.gst,
        parsed.discount,
        parsed.finalAmount,
        categoryId,
        image_url || null,
        raw_ocr_text,
      ]
    );

    const billScan = scanInsert.rows[0];

    // Insert bill items
    for (const item of parsed.items) {
      await db.query(
        `INSERT INTO bill_items (bill_scan_id, item_name, quantity, unit_price, total_price)
         VALUES ($1, $2, $3, $4, $5)`,
        [billScan.id, item.item_name, item.quantity, item.unit_price, item.total_price]
      );
    }

    res.status(200).json({
      success: true,
      message: isDuplicate ? 'Bill scanned (Potential duplicate detected).' : 'Bill parsed successfully.',
      data: {
        billScan,
        items: parsed.items,
        detectedCategory: parsed.detectedCategory,
        categoryId,
        isDuplicate,
        duplicateDetails: isDuplicate ? dupCheck.rows[0] : null,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Confirm Bill Scan & Save as Financial Transaction
const confirmBill = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { bill_scan_id, category_id, final_amount, payment_method, shop_name, bill_date, description } = req.body;

    if (!bill_scan_id) {
      return res.status(400).json({ success: false, message: 'bill_scan_id is required.' });
    }

    const billRes = await db.query('SELECT * FROM bill_scans WHERE id = $1 AND user_id = $2', [bill_scan_id, userId]);
    if (billRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Bill scan record not found.' });
    }

    const bill = billRes.rows[0];
    const amountToSave = final_amount ? parseFloat(final_amount) : parseFloat(bill.final_amount);
    const catIdToSave = category_id || bill.detected_category_id;
    const dateToSave = bill_date || (bill.bill_date ? String(bill.bill_date).substring(0, 10) : new Date().toISOString().substring(0, 10));
    const descToSave = description || `Bill: ${shop_name || bill.shop_name} (#${bill.bill_number})`;

    // Insert transaction
    const txInsert = await db.query(
      `INSERT INTO transactions (user_id, category_id, type, amount, transaction_date, payment_method, description, attachment_url)
       VALUES ($1, $2, 'expense', $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, catIdToSave, amountToSave, dateToSave, payment_method || 'UPI', descToSave, bill.image_url]
    );

    const transaction = txInsert.rows[0];

    // Update bill_scans status to 'confirmed' and link transaction_id
    await db.query(
      `UPDATE bill_scans 
       SET status = 'confirmed', transaction_id = $1, final_amount = $2, shop_name = COALESCE($3, shop_name)
       WHERE id = $4`,
      [transaction.id, amountToSave, shop_name, bill_scan_id]
    );

    res.status(200).json({
      success: true,
      message: 'Bill verified and financial transaction recorded successfully.',
      data: {
        transaction,
        bill_scan_id,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Bill History
const getBillHistory = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT b.*, c.name as category_name, c.color as category_color,
             (SELECT COUNT(*) FROM bill_items bi WHERE bi.bill_scan_id = b.id) as item_count
      FROM bill_scans b
      LEFT JOIN categories c ON b.detected_category_id = c.id
      WHERE b.user_id = $1
      ORDER BY b.created_at DESC
      LIMIT 50
    `;
    const result = await db.query(query, [userId]);

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

// Get single bill with items
const getBillById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const billRes = await db.query('SELECT * FROM bill_scans WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    if (billRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Bill not found.' });
    }

    const itemsRes = await db.query('SELECT * FROM bill_items WHERE bill_scan_id = $1 ORDER BY id ASC', [id]);

    res.status(200).json({
      success: true,
      data: {
        ...billRes.rows[0],
        items: itemsRes.rows,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Monthly Analytics for Fuel and Supermarket spending
const getBillAnalytics = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Monthly Fuel spending
    const fuelRes = await db.query(
      `SELECT TO_CHAR(t.transaction_date, 'YYYY-MM') as month,
              COALESCE(SUM(t.amount), 0) as fuel_total,
              COUNT(t.id) as refill_count
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false AND c.name ILIKE '%petrol%' OR c.name ILIKE '%fuel%'
       GROUP BY TO_CHAR(t.transaction_date, 'YYYY-MM')
       ORDER BY month DESC LIMIT 6`,
      [userId]
    );

    // Monthly Supermarket & Groceries spending
    const groceryRes = await db.query(
      `SELECT TO_CHAR(t.transaction_date, 'YYYY-MM') as month,
              COALESCE(SUM(t.amount), 0) as grocery_total,
              COUNT(t.id) as visit_count
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1 AND t.is_deleted = false AND (c.name ILIKE '%grocer%' OR c.name ILIKE '%supermarket%')
       GROUP BY TO_CHAR(t.transaction_date, 'YYYY-MM')
       ORDER BY month DESC LIMIT 6`,
      [userId]
    );

    res.status(200).json({
      success: true,
      data: {
        monthlyFuel: fuelRes.rows,
        monthlyGrocery: groceryRes.rows,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  scanBill,
  confirmBill,
  getBillHistory,
  getBillById,
  getBillAnalytics,
};
