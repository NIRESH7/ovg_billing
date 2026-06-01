import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class PartyMasterScreen extends StatefulWidget {
  final Customer? customer;
  const PartyMasterScreen({super.key, this.customer});

  @override
  State<PartyMasterScreen> createState() => _PartyMasterScreenState();
}

class _PartyMasterScreenState extends State<PartyMasterScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  
  String _priceType = 'Retail';

  final List<String> _priceTypes = ['Company', 'Distributor', 'Wholesale', 'Retail'];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _mobileController.text = widget.customer!.mobile;
      _whatsappController.text = widget.customer!.whatsappNo ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _gstinController.text = widget.customer!.gstin ?? '';
      _panController.text = widget.customer!.panNo ?? '';
      _districtController.text = widget.customer!.district ?? '';
      _stateController.text = widget.customer!.state ?? 'Tamil Nadu';
      _discountController.text = (widget.customer!.discountPercent ?? 0).toString();
      _priceType = widget.customer!.priceType ?? 'Retail';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: _nameController.text,
      mobile: _mobileController.text,
      address: _addressController.text,
      gstin: _gstinController.text,
      whatsappNo: _whatsappController.text,
      panNo: _panController.text,
      district: _districtController.text,
      state: _stateController.text,
      priceType: _priceType,
      discountPercent: double.tryParse(_discountController.text) ?? 0.0,
    );

    try {
      if (widget.customer != null) {
        await _apiService.updateCustomer(widget.customer!.id, customer);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party updated successfully!')));
      } else {
        await _apiService.createCustomer(customer);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party created successfully!')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer != null ? 'Edit Party' : 'Party Master')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Party Name *', _nameController, Icons.person, required: true),
              const SizedBox(height: 16),
              _buildField('Mobile Number *', _mobileController, Icons.phone, required: true, keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('WhatsApp Number', _whatsappController, Icons.message, keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Address', _addressController, Icons.location_on),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('GST Number', _gstinController, Icons.tag)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('PAN Number', _panController, Icons.credit_card)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('District', _districtController, Icons.map)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('State', _stateController, Icons.public)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Default Discount (%)', _discountController, Icons.percent, keyboard: TextInputType.number),
              const SizedBox(height: 24),
              const Text('Select Price Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              _buildPriceTypeDropdown(),
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
                  child: const Text('Save Party Master', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool required = false, TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? (val) => (val == null || val.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildPriceTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Price Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _priceType,
              isExpanded: true,
              items: _priceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _priceType = val!),
            ),
          ),
        ),
      ],
    );
  }
}
