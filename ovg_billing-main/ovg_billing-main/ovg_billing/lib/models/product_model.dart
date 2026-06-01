class Product {
  final String id;
  final int sno;
  final String name;
  final String category;
  final String sheet;
  final String quality;
  final int pkg;
  final String hsnCode;
  final double gstPercent;
  final List<SizePrice> sizePrices;
  final String? imageUrl;
  final String color;

  Product({
    required this.id,
    required this.sno,
    required this.name,
    required this.category,
    required this.sheet,
    required this.quality,
    required this.pkg,
    required this.hsnCode,
    required this.gstPercent,
    required this.sizePrices,
    this.imageUrl,
    this.color = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      sno: (json['sno'] is String ? int.tryParse(json['sno']) : json['sno']) ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      sheet: json['sheet']?.toString() ?? '',
      quality: json['quality']?.toString() ?? '',
      pkg: (json['pkg'] is String ? int.tryParse(json['pkg']) : json['pkg']) ?? 10,
      hsnCode: json['hsn_code']?.toString() ?? '61112000',
      gstPercent: (json['gst_percent'] ?? 5.0).toDouble(),
      sizePrices: (json['size_prices'] as List<dynamic>? ?? [])
          .map((e) => SizePrice.fromJson(e))
          .toList(),
      imageUrl: json['imageUrl']?.toString(),
      color: json['color']?.toString() ?? '',
    );
  }

  String get displayName => '$name (${quality})';
}

class SizePrice {
  final String size;
  final double companyPrice;
  final double distributorPrice;
  final double wholesalePrice;
  final double retailPrice;

  SizePrice({
    required this.size,
    required this.companyPrice,
    required this.distributorPrice,
    required this.wholesalePrice,
    required this.retailPrice,
  });

  factory SizePrice.fromJson(Map<String, dynamic> json) {
    // Fallback for old data where only 'price' exists
    double basePrice = (json['price'] ?? 0).toDouble();
    return SizePrice(
      size: json['size'] ?? '',
      companyPrice: (json['company_price'] ?? basePrice).toDouble(),
      distributorPrice: (json['distributor_price'] ?? basePrice).toDouble(),
      wholesalePrice: (json['wholesale_price'] ?? basePrice).toDouble(),
      retailPrice: (json['retail_price'] ?? basePrice).toDouble(),
    );
  }

  double getPriceByType(String type) {
    switch (type) {
      case 'Company':
        return companyPrice;
      case 'Distributor':
        return distributorPrice;
      case 'Wholesale':
        return wholesalePrice;
      case 'Retail':
      default:
        return retailPrice;
    }
  }

  Map<String, dynamic> toJson() => {
    'size': size,
    'company_price': companyPrice,
    'distributor_price': distributorPrice,
    'wholesale_price': wholesalePrice,
    'retail_price': retailPrice,
  };
}
