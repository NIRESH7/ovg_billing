class Customer {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String gstin;
  final String whatsappNo;
  final String panNo;
  final String district;
  final String state;
  final String priceType;
  final double discountPercent;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    this.gstin = '',
    this.address = '',
    this.whatsappNo = '',
    this.panNo = '',
    this.district = '',
    this.state = '',
    this.priceType = 'Retail',
    this.discountPercent = 0.0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      whatsappNo: json['whatsapp_no']?.toString() ?? '',
      panNo: json['pan_no']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      priceType: json['price_type']?.toString() ?? 'Retail',
      discountPercent: (json['discount_percent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'gstin': gstin,
      'address': address,
      'whatsapp_no': whatsappNo,
      'pan_no': panNo,
      'district': district,
      'state': state,
      'price_type': priceType,
      'discount_percent': discountPercent,
    };
  }
}
