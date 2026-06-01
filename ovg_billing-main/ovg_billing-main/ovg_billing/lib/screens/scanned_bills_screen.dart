import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../providers/billing_provider.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class ScannedBillsScreen extends StatefulWidget {
  const ScannedBillsScreen({super.key});

  @override
  State<ScannedBillsScreen> createState() => _ScannedBillsScreenState();
}

class _ScannedBillsScreenState extends State<ScannedBillsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    try {
      final bills = await _apiService.getBills();
      setState(() => _bills = bills);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload({bool isPdf = false, ImageSource source = ImageSource.camera}) async {
    XFile? file;
    
    if (isPdf) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Required for Web
      );
      if (result != null) {
        final platformFile = result.files.first;
        if (kIsWeb) {
          file = XFile.fromData(platformFile.bytes!, name: platformFile.name, mimeType: 'application/pdf');
        } else {
          file = XFile(platformFile.path!, name: platformFile.name, mimeType: 'application/pdf');
        }
      }
    } else {
      final ImagePicker picker = ImagePicker();
      file = await picker.pickImage(source: source);
    }
    
    if (file != null) {
      setState(() => _isUploading = true);
      try {
        final result = await _apiService.uploadBill(file);
        if (result.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${result['error']}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill uploaded and parsed successfully!')));
          _fetchBills();
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _convertToInvoice(Map<String, dynamic> billData) {
    final provider = context.read<BillingProvider>();
    final data = billData['parsedData'] ?? {};
    
    // 1. Set Customer (Simplified or search if exists)
    // For now, we create a temporary customer or just set the name
    // This part depends on how robust we want the mapping to be
    
    // 2. Clear current cart
    provider.clearCart();
    
    // 3. Add items to cart
    final items = (data['items'] as List?) ?? [];
    for (var item in items) {
      // Find matching product in provider
      final name = item['name']?.toString() ?? '';
      Product? matchedProduct;
      try {
        matchedProduct = provider.products.firstWhere((p) => p.name.toLowerCase().contains(name.toLowerCase()));
      } catch (_) {}

      if (matchedProduct != null) {
        provider.addToCart(
          matchedProduct, 
          matchedProduct.sizePrices.first.size, 
          (item['qty'] as num?)?.toInt() ?? 1, 
          0,
          manualRate: (item['rate'] as num?)?.toDouble() ?? (item['amount'] as num?)?.toDouble()
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parsed items added to Billing screen!'))
    );
    Navigator.pop(context); // Close details
    // Ideally navigate to Billing screen, but it might already be open in background
  }

  void _editBillData(Map<String, dynamic> bill) {
    final data = Map<String, dynamic>.from(bill['parsedData'] ?? {});
    final Map<String, TextEditingController> controllers = {};
    
    data.forEach((key, value) {
      if (key != 'items') {
        controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bill Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: controllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key.replaceAll('_', ' ').toUpperCase(),
                  border: const OutlineInputBorder(),
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> updatedData = Map.from(data);
              controllers.forEach((key, controller) {
                updatedData[key] = controller.text;
              });
              
              await _apiService.updateBillData(bill['id'], updatedData);
              Navigator.pop(context);
              _fetchBills();
            }, 
            child: const Text('Save Changes')
          ),
        ],
      ),
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    final data = bill['parsedData'] ?? {};
    final items = (data['items'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Parsed Bill Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                        onPressed: () {
                          Navigator.pop(context);
                          _editBillData(bill);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await _apiService.deleteBill(bill['id']);
                          Navigator.pop(context);
                          _fetchBills();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Parsed Fields:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              ...data.entries.where((e) => e.key != 'items').map((entry) => _buildDetailRow(
                entry.key.replaceAll('_', ' ').toUpperCase(), 
                entry.value?.toString() ?? 'N/A'
              )).toList(),
              const Divider(height: 32),
              const Text('Items Extracted:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('No items found', style: TextStyle(color: Colors.grey))
              else
                ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name']?.toString() ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qty: ${item['qty']?.toString() ?? '0'} • Rate: ₹${item['rate']?.toString() ?? '0'}', style: TextStyle(color: Colors.grey[700])),
                          Text('₹${item['amount']?.toString() ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
              const Divider(height: 32),
              const Text('Original Document:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              bill['isPDF'] == true
                ? Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        SizedBox(height: 8),
                        Text('PDF Document', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ApiConstants.getImageUrl(bill['imageUrl']),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _convertToInvoice(bill),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: const Text('Convert to Sales Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Bills & OCR', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBills),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? const Center(child: Text('No scanned bills yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bills.length,
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    final data = bill['parsedData'] ?? {};
                    final date = bill['created_at'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(bill['created_at']))
                        : 'Unknown Date';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: bill['isPDF'] == true
                              ? const Icon(Icons.picture_as_pdf, color: Colors.red)
                              : Image.network(
                                  ApiConstants.getImageUrl(bill['imageUrl']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                ),
                          ),
                        ),
                        title: Text(data['party_name']?.toString() ?? 'Processing...', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ${data['date'] ?? 'N/A'} • Uploaded: $date'),
                        trailing: Text('₹${data['total_amount'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        onTap: () => _showBillDetails(bill),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'pdf',
            onPressed: _isUploading ? null : () => _pickAndUpload(isPdf: true),
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('Upload PDF Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'gallery',
            onPressed: _isUploading ? null : () => _pickAndUpload(isPdf: false, source: ImageSource.gallery),
            backgroundColor: Colors.orangeAccent,
            icon: const Icon(Icons.photo_library, color: Colors.white),
            label: const Text('Gallery Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: _isUploading ? null : () => _pickAndUpload(isPdf: false, source: ImageSource.camera),
            backgroundColor: const Color(0xFF1E3A8A),
            icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(_isUploading ? 'Parsing...' : 'Scan Image Bill', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
