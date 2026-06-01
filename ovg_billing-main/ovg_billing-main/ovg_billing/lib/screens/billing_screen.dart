import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/billing_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../core/widgets/voice_search_button.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'pdf_view_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _custNameController = TextEditingController();
  final TextEditingController _custMobileController = TextEditingController();
  final TextEditingController _custGstinController = TextEditingController();
  final TextEditingController _custAddressController = TextEditingController();
  String _paymentType = 'Online Payment';
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _otherRefController = TextEditingController(text: '10 BOXES, 1 BUNDLE');

  // GSTIN type: 'Unregistered' or 'Registered'
  String _gstinType = 'Unregistered';
  bool _isSubmitting = false; // guard against double-tap

  Future<void> _launchWhatsApp(String mobile, String invoiceNo) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final message = "Hello, this is Om Vinayagar Garments. Your bill $invoiceNo has been generated.";
    final url = "https://wa.me/91$cleanMobile?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().init();
      context.read<ProductProvider>().fetchProducts();

      // Populate controllers if a customer is selected (e.g. from Master Flow) or editing
      final provider = context.read<BillingProvider>();
      if (provider.selectedCustomer != null) {
        _custNameController.text = provider.selectedCustomer!.name;
        _custMobileController.text = provider.selectedCustomer!.mobile;
        _custGstinController.text = provider.selectedCustomer!.gstin;
        _custAddressController.text = provider.selectedCustomer!.address;
        setState(() {
          _gstinType = provider.selectedCustomer!.gstin.isEmpty ? 'Unregistered' : 'Registered';
        });
      }
    });
  }

  void _showProductSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                suffixIcon: VoiceSearchButton(
                  onResult: (text) {
                    context.read<ProductProvider>().searchProducts(text);
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) => context.read<ProductProvider>().searchProducts(val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  return ListView.separated(
                    itemCount: provider.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final p = provider.products[index];
                      return ListTile(
                        leading: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imageUrl != null 
                              ? Image.network(
                                  ApiConstants.getImageUrl(p.imageUrl),
                                  fit: BoxFit.cover, 
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E3A8A))
                                )
                              : const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${p.quality} • ${p.sheet}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          _showSizeSelection(p);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSizeSelection(Product product) {
    String selectedSize = product.sizePrices.first.size;
    final provider = context.read<BillingProvider>();
    final qtyController = TextEditingController(text: '10');
    final discountController = TextEditingController(text: (provider.selectedCustomer?.discountPercent ?? 0).toString());
    final sp = product.sizePrices.first;
    final rateController = TextEditingController(
      text: sp.getPriceByType(provider.selectedCustomer?.priceType ?? 'Retail').toString()
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Select Size', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: product.sizePrices.map((sp) {
                  bool isSelected = selectedSize == sp.size;
                  return ChoiceChip(
                    label: Text(sp.size),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E3A8A),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (val) {
                      setModalState(() {
                        selectedSize = sp.size;
                        rateController.text = sp.getPriceByType(provider.selectedCustomer?.priceType ?? 'Retail').toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate (₹)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Price',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Disc (%)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            prefixIcon: const Icon(Icons.percent, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text) ?? 10;
                    final disc = double.tryParse(discountController.text) ?? 0;
                    final rate = double.tryParse(rateController.text) ?? 0;
                    
                    context.read<BillingProvider>().addToCart(
                      product, 
                      selectedSize, 
                      qty, 
                      disc,
                      manualRate: rate > 0 ? rate : null
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(int index, InvoiceItem item) {
    final qtyController = TextEditingController(text: item.quantity.toString());
    final discountController = TextEditingController(text: item.discountPercent.toString());
    final rateController = TextEditingController(text: item.rate.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${item.productName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Size: ${item.size}', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Qty',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rate (₹)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Price',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disc (%)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          prefixIcon: const Icon(Icons.percent, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final qty = int.tryParse(qtyController.text) ?? item.quantity;
                  final disc = double.tryParse(discountController.text) ?? item.discountPercent;
                  final rate = double.tryParse(rateController.text) ?? item.rate;
                  
                  context.read<BillingProvider>().updateCartItem(index, qty, rate, disc);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Update Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _clearAllFields() {
    _custNameController.clear();
    _custGstinController.clear();
    _custAddressController.clear();
    _paymentType = 'Online Payment';
    _destinationController.clear();
    _vehicleNoController.clear();
    _otherRefController.text = '10 BOXES, 1 BUNDLE';
    setState(() => _gstinType = 'Unregistered');
    context.read<BillingProvider>().clearCart();
  }

  Future<void> _submitInvoice() async {
    // ── Guard: prevent double submission ──────────────────────
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<BillingProvider>();
    if (provider.cartItems.isEmpty) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (_custNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    provider.setCustomer(Customer(
      id: '',
      name: _custNameController.text,
      mobile: _custMobileController.text,
      gstin: _custGstinController.text,
      address: _custAddressController.text,
    ));

    try {
      final invoice = await provider.submitInvoice('Cash', extraData: {
        'payment_type': _paymentType,
        'destination': _destinationController.text,
        'vehicle_number': _vehicleNoController.text,
        'other_reference': _otherRefController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.editingInvoiceId != null
                ? 'Invoice Updated Successfully'
                : 'Invoice Generated: ${invoice?.invoiceNumber}'),
          ),
        );

        if (invoice != null && mounted) {
          final mobile = _custMobileController.text;
          final invNo = invoice.invoiceNumber;
          _clearAllFields();
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          if (mobile.isNotEmpty) {
            _launchWhatsApp(mobile, invNo);
          }
        } else {
          _clearAllFields();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating bill: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.watch<BillingProvider>().editingInvoiceId != null 
            ? 'Edit Invoice' 
            : 'New Invoice', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
            onPressed: _clearAllFields,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Customer Details',
              icon: Icons.person_pin_rounded,
              children: [
                _buildField('Customer Name', _custNameController, Icons.person_outline),
                const SizedBox(height: 12),
                _buildField('Mobile Number', _custMobileController, Icons.phone_android_outlined),
                const SizedBox(height: 12),
                _buildGstinField(),
                const SizedBox(height: 12),
                _buildField('Address', _custAddressController, Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPaymentTypeDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Destination', _destinationController, Icons.map_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Vehicle Number', _vehicleNoController, Icons.directions_car_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Other Reference', _otherRefController, Icons.notes_rounded)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E3A8A), size: 28),
                              SizedBox(width: 12),
                              Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showProductSearch,
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1E3A8A)),
                          label: const Text('Add Product', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Consumer<BillingProvider>(
                      builder: (context, provider, _) {
                        if (provider.cartItems.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('No items added yet', style: TextStyle(color: Color(0xFF64748B))),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.cartItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = provider.cartItems[index];
                            return ListTile(
                              onTap: () => _showEditItemDialog(index, item),
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${item.size} • ${item.quantity} units${item.discountPercent > 0 ? ' • ${item.discountPercent}% Disc.' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (item.discountPercent > 0)
                                        Text('₹${(item.rate * item.quantity).toStringAsFixed(2)}', 
                                          style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: Colors.grey)),
                                      Text('₹${item.taxableAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => provider.removeFromCart(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<BillingProvider>(
              builder: (context, provider, _) => Card(
                color: const Color(0xFF1E3A8A),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _summaryRow('Subtotal', '₹${provider.subtotal.toStringAsFixed(2)}', Colors.white70),
                      const SizedBox(height: 8),
                      _summaryRow('GST (5%)', '₹${(provider.totalCgst + provider.totalSgst).toStringAsFixed(2)}', Colors.white70),
                      const Divider(height: 24, color: Colors.white24),
                      _summaryRow('Grand Total', '₹${provider.grandTotal.toStringAsFixed(2)}', Colors.white, isBold: true),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitInvoice,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Generate Invoice PDF', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        suffixIcon: VoiceSearchButton(
          onResult: (text) {
            setState(() {
              controller.text = text;
            });
          },
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        alignLabelWithHint: true,
      ),
    );
  }

  // ── GSTIN field with Registered / Unregistered dropdown ────────────────────
  Widget _buildGstinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown row
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gstinType,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Unregistered',
                        child: Text('Unregistered'),
                      ),
                      DropdownMenuItem(
                        value: 'Registered',
                        child: Text('Registered'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _gstinType = val!;
                        if (val == 'Unregistered') {
                          _custGstinController.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              // Badge chip showing selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gstinType == 'Registered'
                      ? const Color(0xFF1E3A8A).withOpacity(0.1)
                      : const Color(0xFF64748B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _gstinType == 'Registered' ? 'GST' : 'No GST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _gstinType == 'Registered'
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Conditional GSTIN number input
        if (_gstinType == 'Registered') ...
          [
            const SizedBox(height: 8),
            TextField(
              controller: _custGstinController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'GSTIN Number',
                hintText: 'e.g. 33ABCDE1234F1Z5',
                prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: VoiceSearchButton(
                  onResult: (text) => setState(() => _custGstinController.text = text.toUpperCase()),
                ),
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildPaymentTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Type', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.payment_outlined, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentType,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Online Payment',
                        child: Text('Online Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'Hand Delivery',
                        child: Text('Hand Delivery'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _paymentType = val!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 16)),
        Text(value, style: TextStyle(color: color, fontSize: isBold ? 20 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
