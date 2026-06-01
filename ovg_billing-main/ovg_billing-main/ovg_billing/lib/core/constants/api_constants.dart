import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for Web
  static const String baseUrl = 'http://3.85.106.47:8000';

  static const String products = '$baseUrl/products';
  static const String productCategories = '$baseUrl/products/categories';
  static const String customers = '$baseUrl/customers';
  static const String invoices = '$baseUrl/invoices';
  static const String todayStats = '$baseUrl/invoices/stats/today';
  static const String monthlyStats = '$baseUrl/invoices/stats/monthly';
  static const String bills = '$baseUrl/bills';
  static const String billUpload = '$baseUrl/bills/upload';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Ensure path starts with / if it's not a full URL
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
}
