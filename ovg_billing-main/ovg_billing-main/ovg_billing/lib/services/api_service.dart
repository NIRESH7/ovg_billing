import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // ── Products ──────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    final res = await _dio.get(ApiConstants.products);
    return (res.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<String>> getCategories() async {
    final res = await _dio.get(ApiConstants.productCategories);
    return List<String>.from(res.data);
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final res = await _dio.get('${ApiConstants.products}/category/$category');
    return (res.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final res = await _dio.get('${ApiConstants.products}/search', queryParameters: {'q': query});
    return (res.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final res = await _dio.post(ApiConstants.products, data: productData);
    return Product.fromJson(res.data);
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('${ApiConstants.products}/$id');
  }

  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    await _dio.put('${ApiConstants.products}/$id', data: productData);
  }

  // ── Customers ─────────────────────────────────────────────────────────────
  Future<List<Customer>> getCustomers() async {
    final res = await _dio.get(ApiConstants.customers);
    return (res.data as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final res = await _dio.post(ApiConstants.customers, data: customer.toJson());
    return Customer.fromJson(res.data);
  }

  Future<void> deleteCustomer(String id) async {
    await _dio.delete('${ApiConstants.customers}/$id');
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    await _dio.put('${ApiConstants.customers}/$id', data: customer.toJson());
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final res = await _dio.get('${ApiConstants.customers}/search', queryParameters: {'q': query});
    return (res.data as List).map((e) => Customer.fromJson(e)).toList();
  }

  // ── Invoices ──────────────────────────────────────────────────────────────
  Future<Invoice> createInvoice(Map<String, dynamic> invoiceData) async {
    final res = await _dio.post(ApiConstants.invoices, data: invoiceData);
    return Invoice.fromJson(res.data);
  }

  Future<List<Invoice>> getInvoices({int skip = 0, int limit = 50}) async {
    final res = await _dio.get(ApiConstants.invoices,
        queryParameters: {'skip': skip, 'limit': limit});
    return (res.data as List).map((e) => Invoice.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final res = await _dio.get(ApiConstants.todayStats);
    return Map<String, dynamic>.from(res.data);
  }

  Future<String> getInvoicePdfUrl(String invoiceId) {
    return Future.value('${ApiConstants.baseUrl}/invoices/$invoiceId/pdf');
  }

  Future<List<int>> getInvoicePdf(String invoiceId) async {
    final res = await _dio.get(
      '${ApiConstants.baseUrl}/invoices/$invoiceId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data;
  }

  Future<void> deleteInvoice(String id) async {
    await _dio.delete('${ApiConstants.invoices}/$id');
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> invoiceData) async {
    await _dio.put('${ApiConstants.invoices}/$id', data: invoiceData);
  }

  // ── Image Upload ──────────────────────────────────────────────────────────
  Future<String> uploadImage(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post('${ApiConstants.baseUrl}/upload', data: formData);
      return '${ApiConstants.baseUrl}${res.data['url']}';
    } catch (e) {
      print('Upload Error: $e');
      return '';
    }
  }

  // ── Speech to Text ────────────────────────────────────────────────────────
  Future<String> speechToText(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        final size = await file.length();
        print('Sending STT request. File size: $size bytes');
      }
      print('Sending STT request to: ${ApiConstants.baseUrl}/stt');
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath, filename: 'audio.wav'),
      });
      final res = await _dio.post('${ApiConstants.baseUrl}/stt', data: formData);
      print('STT Response: ${res.data}');
      return res.data['text'];
    } catch (e) {
      print('STT Error: $e');
      return '';
    }
  }

  // ── Scanned Bills ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBills() async {
    final res = await _dio.get(ApiConstants.bills);
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> uploadBill(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      FormData formData = FormData.fromMap({
        'bill': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final res = await _dio.post(ApiConstants.billUpload, data: formData);
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('Bill Upload Error: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> deleteBill(String id) async {
    await _dio.delete('${ApiConstants.bills}/$id');
  }

  Future<void> updateBillData(String id, Map<String, dynamic> data) async {
    await _dio.put('${ApiConstants.bills}/$id', data: {'parsedData': data});
  }
}
