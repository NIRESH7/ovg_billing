import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../core/constants/api_constants.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allProducts = data.map((item) => Product.fromJson(item)).toList();
        final hasImages = _allProducts.any((p) => p.imageUrl != null);
        debugPrint('Fetched ${_allProducts.length} products. Images found: $hasImages');
        if (hasImages) {
           debugPrint('Sample image: ${_allProducts.firstWhere((p) => p.imageUrl != null).imageUrl}');
        }
        _filteredProducts = _allProducts;
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
