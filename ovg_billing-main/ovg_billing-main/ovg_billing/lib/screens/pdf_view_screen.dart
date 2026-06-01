import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../models/invoice_model.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import 'billing_screen.dart';

class PdfViewScreen extends StatelessWidget {
  final String url;
  final String invoiceNumber;
  final Invoice invoice;

  const PdfViewScreen({
    super.key,
    required this.url,
    required this.invoiceNumber,
    required this.invoice,
  });

  Future<Uint8List> _fetchPdf() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice: $invoiceNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A)),
            tooltip: 'Edit Invoice',
            onPressed: () {
              context.read<BillingProvider>().loadInvoiceForEditing(invoice);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (format) => _fetchPdf(),
        useActions: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}
