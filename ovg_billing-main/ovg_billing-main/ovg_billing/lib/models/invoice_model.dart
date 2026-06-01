class InvoiceItem {
  final String productId;
  final String productName;
  final String hsnCode;
  final String size;
  final String quality;
  final String category;
  double rate;
  int quantity;
  double discountPercent;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.hsnCode,
    required this.size,
    required this.quality,
    required this.category,
    required this.rate,
    required this.quantity,
    this.discountPercent = 0.0,
  });

  double get taxableAmount {
    final totalInclusive = rate * quantity * (1 - discountPercent / 100);
    // Extract base amount from inclusive total (Total / 1.05 for 5% GST)
    final baseAmount = totalInclusive / 1.05;
    return double.parse(baseAmount.toStringAsFixed(2));
  }

  double get cgstAmount => double.parse((taxableAmount * 0.025).toStringAsFixed(2));
  double get sgstAmount => double.parse((taxableAmount * 0.025).toStringAsFixed(2));
  
  // Total should be exactly the rate * quantity (minus discount)
  double get totalAmount => double.parse((rate * quantity * (1 - discountPercent / 100)).toStringAsFixed(2));

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'hsn_code': hsnCode,
        'size': size,
        'quality': quality,
        'category': category,
        'rate': rate,
        'quantity': quantity,
        'discount_percent': discountPercent,
        'taxable_amount': taxableAmount,
        'cgst_percent': 2.5,
        'sgst_percent': 2.5,
        'cgst_amount': cgstAmount,
        'sgst_amount': sgstAmount,
        'total_amount': totalAmount,
      };
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String customerAddress;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double totalCgst;
  final double totalSgst;
  final double grandTotal;
  final String paymentMode;
  final String createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.items,
    required this.subtotal,
    required this.totalCgst,
    required this.totalSgst,
    required this.grandTotal,
    required this.paymentMode,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerMobile: json['customer_mobile']?.toString() ?? '',
      customerAddress: json['customer_address']?.toString() ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalCgst: (json['total_cgst'] ?? 0).toDouble(),
      totalSgst: (json['total_sgst'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      paymentMode: json['payment_mode'] ?? 'Cash',
      createdAt: json['created_at'] ?? '',
    );
  }
}
