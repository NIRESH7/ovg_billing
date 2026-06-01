import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../providers/billing_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import 'billing_screen.dart';

class NewMasterFlowScreen extends StatefulWidget {
  const NewMasterFlowScreen({super.key});

  @override
  State<NewMasterFlowScreen> createState() => _NewMasterFlowScreenState();
}

class _NewMasterFlowScreenState extends State<NewMasterFlowScreen> {
  final _apiService = ApiService();
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final custs = await _apiService.getCustomers();
      setState(() {
        _customers = custs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startBilling() {
    if (_selectedCustomer == null) return;

    final billingProvider = context.read<BillingProvider>();
    billingProvider.clearCart();
    billingProvider.setCustomer(_selectedCustomer!);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Master Flow Billing', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 1: Select Party', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Customer>(
                      isExpanded: true,
                      hint: const Text('Select a Party (Customer)'),
                      value: _selectedCustomer,
                      items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() => _selectedCustomer = val),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_selectedCustomer != null) ...[
                  const Text('Step 2: Party Details (Auto-filled)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  _buildDetailCard(),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _startBilling,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text('Proceed to Billing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Name', _selectedCustomer!.name),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Mobile', _selectedCustomer!.mobile),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, 'District', _selectedCustomer!.district),
            const Divider(height: 24),
            _buildInfoRow(Icons.sell, 'Price Type', _selectedCustomer!.priceType, valueColor: Colors.blue.shade800),
            const Divider(height: 24),
            _buildInfoRow(Icons.verified_user, 'GSTIN', _selectedCustomer!.gstin.isEmpty ? 'N/A' : _selectedCustomer!.gstin),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF1E293B))),
      ],
    );
  }
}
