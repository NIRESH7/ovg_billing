import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/api_service.dart';
import '../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import 'billing_screen.dart';
import 'pdf_view_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final ApiService _apiService = ApiService();
  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await _apiService.getInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Invoices')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('No invoices found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    return Card(
                      child: ListTile(
                        title: Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.customerName),
                            Text('₹${inv.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A)),
                              tooltip: 'Edit Invoice',
                              onPressed: () {
                                context.read<BillingProvider>().loadInvoiceForEditing(inv);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BillingScreen()),
                                ).then((_) => context.read<BillingProvider>().fetchInvoices()).then((_) => _loadInvoices());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: AppTheme.danger),
                              onPressed: () async {
                                final url = await _apiService.getInvoicePdfUrl(inv.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewScreen(
                                      url: url,
                                      invoiceNumber: inv.invoiceNumber,
                                      invoice: inv,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
