class OcrBillSample {
  final String title;
  final String category;
  final String ocrText;

  OcrBillSample({required this.title, required this.category, required this.ocrText});
}

class OcrService {
  static final List<OcrBillSample> presets = [
    OcrBillSample(
      title: 'Bharat Petroleum Fuel Receipt',
      category: 'Petrol / Fuel',
      ocrText: '''BHARAT PETROLEUM CORP LTD
AUTO CARE CENTRE, CHENNAI
DATE: 14/11/2026 18:32
INVOICE NO: BPCL-98421
PRODUCT: SPEED PETROL
DENSITY: 742.0 KG/M3
VOLUME: 20.31 LTR
RATE: 108.32 INR/L
TOTAL SALE: 2200.00
MODE: UPI / PHONEPE
THANK YOU VISIT AGAIN''',
    ),
    OcrBillSample(
      title: 'DMart Supermarket Grocery Receipt',
      category: 'Groceries',
      ocrText: '''DMART SUPERMARKET
AVENUE SUPERMARTS LTD
BILL NO: DM-55102
DATE: 12/11/2026
ASHIRVAAD ATTA 5KG     1  245.00
FORTUNE SUNFLOWER OIL  2  290.00
TATA SALT 1KG          1   28.00
SURF EXCEL 2KG         1  310.00
AMUL BUTTER 500G       1  275.00
SUBTOTAL: 1148.00
CGST 2.5%: 28.70
SGST 2.5%: 28.70
DISCOUNT: 45.40
TOTAL AMOUNT: 1160.00
ITEMS COUNT: 5''',
    ),
    OcrBillSample(
      title: 'Barbeque Nation Dining Bill',
      category: 'Food',
      ocrText: '''BARBEQUE NATION HOSPITALITY
TAX INVOICE # BBQ-8741
DATE: 10/11/2026 21:15
BUFFET NON VEG     2  1900.00
FRESH LIME SODA    2   180.00
SUBTOTAL: 2080.00
CGST 2.5%: 52.00
SGST 2.5%: 52.00
ROUND OFF: 0.00
GRAND TOTAL: 2184.00
PAID VIA: CREDIT CARD''',
    ),
    OcrBillSample(
      title: 'Apollo Pharmacy Medical Bill',
      category: 'Medical',
      ocrText: '''APOLLO PHARMACY LTD
RETAIL INVOICE: APL-3392
DATE: 08/11/2026
PARACETAMOL 650MG      2   60.00
VITAMIN C CHEWABLE     1  185.00
AZITHROMYCIN 500MG     1  120.00
COUGH SYRUP 100ML      1  115.00
SUBTOTAL: 480.00
GST: 24.00
TOTAL PAYABLE: 504.00
PHARMACIST SIGNED''',
    ),
  ];
}
