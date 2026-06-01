import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class BillingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<String> _categories = [];
  List<InvoiceItem> _cartItems = [];
  List<Invoice> _invoices = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _editingInvoiceId;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  List<InvoiceItem> get cartItems => _cartItems;
  List<Invoice> get invoices => _invoices;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get editingInvoiceId => _editingInvoiceId;

  // Stats
  double get todaySales {
    final today = DateTime.now().toString().split(' ')[0];
    return _invoices
        .where((inv) => inv.createdAt.startsWith(today))
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  double get weeklySales {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _invoices
        .where((inv) => DateTime.parse(inv.createdAt).isAfter(weekAgo))
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  double get monthlySales {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _invoices
        .where((inv) => DateTime.parse(inv.createdAt).isAfter(monthAgo))
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  Map<String, int> get productSales {
    final sales = <String, int>{};
    for (var inv in _invoices) {
      for (var item in inv.items) {
        final name = item['product_name'] ?? 'Unknown';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        sales[name] = (sales[name] ?? 0) + qty;
      }
    }
    return sales;
  }

  String? getProductImage(String name) {
    try {
      return _products.firstWhere((p) => p.name == name).imageUrl;
    } catch (e) {
      return null;
    }
  }

  double getProductSalesStats(String? productName, String period) {
    DateTime now = DateTime.now();
    DateTime filterDate;

    if (period == 'today') {
      filterDate = DateTime(now.year, now.month, now.day);
    } else if (period == 'weekly') {
      filterDate = now.subtract(const Duration(days: 7));
    } else {
      filterDate = now.subtract(const Duration(days: 30));
    }

    return _invoices
        .where((inv) => DateTime.parse(inv.createdAt).isAfter(filterDate))
        .fold(0.0, (sum, inv) {
          double productTotal = 0;
          for (var item in inv.items) {
            if (productName == null || item['product_name'] == productName) {
              productTotal += (item['total_amount'] as num?)?.toDouble() ?? 0.0;
            }
          }
          return sum + productTotal;
        });
  }

  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _invoices = await _apiService.getInvoices();
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _apiService.deleteInvoice(id);
      _invoices.removeWhere((inv) => inv.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
    }
  }

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.taxableAmount);
  double get totalCgst => _cartItems.fold(0, (sum, item) => sum + item.cgstAmount);
  double get totalSgst => _cartItems.fold(0, (sum, item) => sum + item.sgstAmount);
  double get grandTotal => _cartItems.fold(0, (sum, item) => sum + item.totalAmount);

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _apiService.getProducts();
      _categories = await _apiService.getCategories();
    } catch (e) {
      debugPrint('Error initializing: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void setCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addToCart(Product product, String size, int quantity, double discount, {double? manualRate}) {
    final index = _cartItems.indexWhere(
      (item) => item.productId == product.id && item.size == size
    );

    final sp = product.sizePrices.firstWhere((s) => s.size == size);
    final rateToUse = manualRate ?? sp.getPriceByType(_selectedCustomer?.priceType ?? 'Retail');

    if (index != -1) {
      _cartItems[index].quantity += quantity;
      _cartItems[index].discountPercent = discount;
      _cartItems[index].rate = rateToUse; // Update rate if changed
    } else {
      _cartItems.add(InvoiceItem(
        productId: product.id,
        productName: product.name,
        hsnCode: product.hsnCode,
        size: size,
        quality: product.quality,
        category: product.category,
        quantity: quantity,
        rate: rateToUse,
        discountPercent: discount,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void updateCartItem(int index, int quantity, double rate, double discount) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].quantity = quantity;
      _cartItems[index].rate = rate;
      _cartItems[index].discountPercent = discount;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems = [];
    _selectedCustomer = null;
    _editingInvoiceId = null;
    notifyListeners();
  }

  void loadInvoiceForEditing(Invoice inv) {
    _editingInvoiceId = inv.id;
    _selectedCustomer = Customer(
      id: '',
      name: inv.customerName,
      mobile: inv.customerMobile,
      gstin: inv.items.isNotEmpty ? (inv.items[0]['customer_gstin'] ?? '') : '', // fallback
      address: inv.customerAddress,
    );
    
    _cartItems = inv.items.map((e) => InvoiceItem(
      productId: e['product_id'] ?? '',
      productName: e['product_name'] ?? '',
      hsnCode: e['hsn_code'] ?? '',
      size: e['size'] ?? '',
      quality: e['quality'] ?? '',
      category: e['category'] ?? '',
      rate: (e['rate'] ?? 0).toDouble(),
      quantity: (e['quantity'] ?? 0).toInt(),
      discountPercent: (e['discount_percent'] ?? 0).toDouble(),
    )).toList();
    
    notifyListeners();
  }

  Future<Invoice?> submitInvoice(String paymentMode, {Map<String, dynamic>? extraData}) async {
    if (_cartItems.isEmpty || _selectedCustomer == null) return null;

    final invoiceData = {
      'customer_id': _selectedCustomer!.id,
      'customer_name': _selectedCustomer!.name,
      'customer_mobile': _selectedCustomer!.mobile,
      'customer_address': _selectedCustomer!.address,
      'customer_gstin': _selectedCustomer!.gstin,
      'items': _cartItems.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'total_cgst': totalCgst,
      'total_sgst': totalSgst,
      'grand_total': grandTotal,
      'payment_mode': paymentMode,
      ...?extraData,
    };

    try {
      if (_editingInvoiceId != null) {
        await _apiService.updateInvoice(_editingInvoiceId!, invoiceData);
        // We need to return an Invoice object for the UI to navigate
        final updatedInvoice = Invoice(
          id: _editingInvoiceId!,
          invoiceNumber: _invoices.firstWhere((i) => i.id == _editingInvoiceId).invoiceNumber,
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          customerMobile: _selectedCustomer!.mobile,
          customerAddress: _selectedCustomer!.address,
          items: _cartItems.map((e) => e.toJson()).toList(),
          subtotal: subtotal,
          totalCgst: totalCgst,
          totalSgst: totalSgst,
          grandTotal: grandTotal,
          paymentMode: paymentMode,
          createdAt: _invoices.firstWhere((i) => i.id == _editingInvoiceId).createdAt,
        );
        clearCart();
        return updatedInvoice;
      } else {
        final invoice = await _apiService.createInvoice(invoiceData);
        clearCart();
        return invoice;
      }
    } catch (e) {
      debugPrint('Error submitting invoice: $e');
      return null;
    }
  }
}
