import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class ProductMasterScreen extends StatefulWidget {
  final Product? product;
  const ProductMasterScreen({super.key, this.product});

  @override
  State<ProductMasterScreen> createState() => _ProductMasterScreenState();
}

class _ProductMasterScreenState extends State<ProductMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _qualityController;
  late TextEditingController _colorController;
  late TextEditingController _hsnController;
  late TextEditingController _imageUrlController;

  // For sizes and their 4 prices
  List<Map<String, dynamic>> _sizePricing = [
    {'size': 'S', 'company': '0', 'distributor': '0', 'wholesale': '0', 'retail': '0'}
  ];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _qualityController = TextEditingController(text: widget.product?.quality ?? '');
    _colorController = TextEditingController(text: widget.product?.color ?? '');
    _hsnController = TextEditingController(text: widget.product?.hsnCode ?? '6111');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');

    if (widget.product != null && widget.product!.sizePrices.isNotEmpty) {
      _sizePricing = widget.product!.sizePrices.map((sp) => {
        'size': sp.size,
        'company': sp.companyPrice.toString(),
        'distributor': sp.distributorPrice.toString(),
        'wholesale': sp.wholesalePrice.toString(),
        'retail': sp.retailPrice.toString(),
      }).toList();
    }
  }

  void _addSize() {
    setState(() {
      _sizePricing.add({'size': '', 'company': '0', 'distributor': '0', 'wholesale': '0', 'retail': '0'});
    });
  }

  void _removeSize(int index) {
    if (_sizePricing.length > 1) {
      setState(() => _sizePricing.removeAt(index));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final url = await _apiService.uploadImage(image.path);
        if (url.isNotEmpty) {
          setState(() {
            _imageUrlController.text = url;
          });
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final productData = {
      'name': _nameController.text,
      'category': _categoryController.text,
      'quality': _qualityController.text,
      'color': _colorController.text,
      'hsn_code': _hsnController.text,
      'imageUrl': _imageUrlController.text,
      'size_prices': _sizePricing.map((s) => {
        'size': s['size'],
        'company_price': double.tryParse(s['company']) ?? 0.0,
        'distributor_price': double.tryParse(s['distributor']) ?? 0.0,
        'wholesale_price': double.tryParse(s['wholesale']) ?? 0.0,
        'retail_price': double.tryParse(s['retail']) ?? 0.0,
      }).toList(),
    };

    try {
      if (widget.product != null) {
        await _apiService.updateProduct(widget.product!.id, productData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
      } else {
        await _apiService.createProduct(productData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product created successfully!')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'New Product Creation' : 'Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Product Name *', _nameController, Icons.shopping_bag, required: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Category', _categoryController, Icons.category)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Quality', _qualityController, Icons.high_quality)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Color', _colorController, Icons.color_lens)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('HSN Code', _hsnController, Icons.tag)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Image URL', _imageUrlController, Icons.image)),
                  const SizedBox(width: 12),
                  _isUploading 
                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator())
                    : IconButton.filledTonal(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_rounded),
                        tooltip: 'Upload Image',
                      ),
                ],
              ),
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ApiConstants.getImageUrl(_imageUrlController.text),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('Invalid Image URL')),
                      ),
                    ),
                ),
              ],
              const SizedBox(height: 32),
              const Text('Size & Pricing Master', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              ..._sizePricing.asMap().entries.map((entry) => _buildSizePricingRow(entry.key, entry.value)).toList(),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _addSize,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Another Size'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Product Master', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? (val) => (val == null || val.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildSizePricingRow(int index, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: data['size'],
                    decoration: const InputDecoration(labelText: 'Size (e.g. S, M, L)', border: InputBorder.none),
                    onChanged: (val) => data['size'] = val,
                  ),
                ),
                IconButton(onPressed: () => _removeSize(index), icon: const Icon(Icons.delete_outline, color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                _buildPriceInput('Company', (val) => data['company'] = val, data['company']),
                const SizedBox(width: 8),
                _buildPriceInput('Distributor', (val) => data['distributor'] = val, data['distributor']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriceInput('Wholesale', (val) => data['wholesale'] = val, data['wholesale']),
                const SizedBox(width: 8),
                _buildPriceInput('Retail', (val) => data['retail'] = val, data['retail']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput(String label, Function(String) onChanged, String initialValue) {
    return Expanded(
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₹ ',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
