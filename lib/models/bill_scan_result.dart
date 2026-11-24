class ScannedBillItem {
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  ScannedBillItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ScannedBillItem.fromJson(Map<String, dynamic> json) {
    return ScannedBillItem(
      itemName: json['item_name'] ?? json['itemName'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BillScanResult {
  final String id;
  final String shopName;
  final String billNumber;
  final DateTime billDate;
  final double subtotal;
  final double gst;
  final double discount;
  final double finalAmount;
  final String detectedCategory;
  final int categoryId;
  final bool isDuplicate;
  final List<ScannedBillItem> items;

  BillScanResult({
    required this.id,
    required this.shopName,
    required this.billNumber,
    required this.billDate,
    required this.subtotal,
    required this.gst,
    required this.discount,
    required this.finalAmount,
    required this.detectedCategory,
    required this.categoryId,
    this.isDuplicate = false,
    required this.items,
  });

  factory BillScanResult.fromJson(Map<String, dynamic> json) {
    final billScan = json['billScan'] ?? json;
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((i) => ScannedBillItem.fromJson(i))
        .toList();

    return BillScanResult(
      id: billScan['id'] ?? '',
      shopName: billScan['shop_name'] ?? json['shopName'] ?? 'Store',
      billNumber: billScan['bill_number'] ?? json['billNumber'] ?? '',
      billDate: billScan['bill_date'] != null
          ? DateTime.tryParse(billScan['bill_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      subtotal: double.tryParse(billScan['subtotal']?.toString() ?? '0') ?? 0.0,
      gst: double.tryParse(billScan['gst']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(billScan['discount']?.toString() ?? '0') ?? 0.0,
      finalAmount: double.tryParse(billScan['final_amount']?.toString() ?? '0') ?? 0.0,
      detectedCategory: json['detectedCategory'] ?? 'Shopping',
      categoryId: json['categoryId'] is int
          ? json['categoryId']
          : int.tryParse(json['categoryId']?.toString() ?? '8') ?? 8,
      isDuplicate: json['isDuplicate'] ?? false,
      items: itemsList,
    );
  }
}
