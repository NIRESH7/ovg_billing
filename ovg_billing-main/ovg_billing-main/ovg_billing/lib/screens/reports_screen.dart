import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/billing_provider.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import 'pdf_view_screen.dart';
import 'billing_screen.dart';
import '../core/constants/api_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProduct;
  String _periodType = 'Daily'; 
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _selectedWeekStart;
  List<Customer> _allCustomers = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().fetchInvoices();
      _fetchCustomers();
    });
  }

  Future<void> _fetchCustomers() async {
    try {
      final custs = await _apiService.getCustomers();
      setState(() => _allCustomers = custs);
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    }
  }

  Future<void> _launchWhatsApp(String? mobile, String invoiceNo) async {
    if (mobile == null || mobile.isEmpty) return;
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final message = "Hello, this is Om Vinayagar Garments. Your bill $invoiceNo has been generated.";
    final url = "https://wa.me/91$cleanMobile?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  List<Invoice> _getFilteredInvoices(List<Invoice> invoices) {
    return invoices.where((inv) {
      DateTime invDate = DateTime.parse(inv.createdAt);
      
      bool dateMatch = true;
      if (_periodType == 'Daily') {
        DateTime now = DateTime.now();
        dateMatch = invDate.year == now.year && invDate.month == now.month && invDate.day == now.day;
      } else if (_periodType == 'Weekly') {
        if (_selectedWeekStart != null) {
          DateTime weekEnd = _selectedWeekStart!.add(const Duration(days: 6));
          dateMatch = invDate.isAfter(_selectedWeekStart!.subtract(const Duration(seconds: 1))) && 
                      invDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }
      } else if (_periodType == 'Monthly') {
        dateMatch = invDate.year == _selectedYear && invDate.month == _selectedMonth;
      } else if (_periodType == 'Yearly') {
        dateMatch = invDate.year == _selectedYear;
      } else if (_periodType == 'Custom') {
        if (_startDate != null && _endDate != null) {
          dateMatch = invDate.isAfter(_startDate!) && invDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }
      }

      bool productMatch = true;
      if (_selectedProduct != null) {
        productMatch = inv.items.any((item) => item['product_name'] == _selectedProduct);
      }

      return dateMatch && productMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sales Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          tabs: const [
            Tab(text: 'Bills List', icon: Icon(Icons.description_outlined)),
            Tab(text: 'Party Wise', icon: Icon(Icons.person_pin_rounded)),
            Tab(text: 'Product Wise', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Geography', icon: Icon(Icons.map_outlined)),
          ],
        ),
      ),
      body: Consumer<BillingProvider>(
        builder: (context, provider, _) {
          final filteredInvoices = _getFilteredInvoices(provider.invoices);
          final products = provider.productSales.keys.toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _periodType,
                            decoration: const InputDecoration(labelText: 'Period Type', border: OutlineInputBorder()),
                            items: ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) => setState(() {
                              _periodType = val!;
                              if (val == 'Weekly') _selectedWeekStart = _getWeeks().first;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_periodType == 'Monthly' || _periodType == 'Yearly' || _periodType == 'Weekly')
                          Expanded(child: _buildSubFilterDropdown()),
                        if (_periodType == 'Custom')
                          IconButton(onPressed: _selectDateRange, icon: const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillsTable(filteredInvoices),
                    _buildPartyWiseReport(filteredInvoices),
                    _buildProductWiseReport(filteredInvoices),
                    _buildGeographyReport(filteredInvoices),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF1E3A8A), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items: ${filteredInvoices.fold(0, (sum, inv) => sum + inv.items.length)}', style: const TextStyle(color: Colors.white)),
                    Text('Grand Total: ₹${filteredInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBillsTable(List<Invoice> filteredInvoices) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFF1E3A8A)),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Bill No')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Action')),
              ],
              rows: filteredInvoices.map((inv) {
                return DataRow(cells: [
                  DataCell(Text(inv.createdAt.split('T')[0])),
                  DataCell(Text(inv.invoiceNumber)),
                  DataCell(Text(inv.customerName)),
                  DataCell(Text('₹${inv.grandTotal.toStringAsFixed(2)}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.green),
                          onPressed: () => _launchWhatsApp(inv.customerMobile, inv.invoiceNumber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A)),
                          onPressed: () {
                            context.read<BillingProvider>().loadInvoiceForEditing(inv);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BillingScreen()),
                            ).then((_) => context.read<BillingProvider>().fetchInvoices());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blueAccent),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewScreen(
                                url: '${ApiConstants.baseUrl}/invoices/${inv.id}/pdf',
                                invoiceNumber: inv.invoiceNumber,
                                invoice: inv,
                              ),
                            ),
                          ).then((_) => context.read<BillingProvider>().fetchInvoices()),
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyWiseReport(List<Invoice> filteredInvoices) {
    final Map<String, double> partySales = {};
    for (var inv in filteredInvoices) {
      partySales[inv.customerName] = (partySales[inv.customerName] ?? 0.0) + inv.grandTotal;
    }
    final sortedParties = partySales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedParties.length,
      itemBuilder: (context, index) {
        final entry = sortedParties[index];
        return _buildReportCard(entry.key, entry.value, Icons.person, Colors.blue);
      },
    );
  }

  Widget _buildProductWiseReport(List<Invoice> filteredInvoices) {
    final Map<String, double> productSales = {};
    for (var inv in filteredInvoices) {
      for (var item in inv.items) {
        final name = item['product_name'] ?? 'Unknown';
        final total = (item['total_amount'] as num?)?.toDouble() ?? 0.0;
        productSales[name] = (productSales[name] ?? 0.0) + total;
      }
    }
    final sortedProducts = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final entry = sortedProducts[index];
        return _buildReportCard(entry.key, entry.value, Icons.inventory_2, Colors.teal);
      },
    );
  }

  Widget _buildGeographyReport(List<Invoice> filteredInvoices) {
    final Map<String, double> districtSales = {};
    final Map<String, double> stateSales = {};

    for (var inv in filteredInvoices) {
      final customer = _allCustomers.cast<Customer?>().firstWhere(
        (c) => c?.id == inv.customerId || c?.name == inv.customerName,
        orElse: () => null,
      );
      
      final district = customer?.district ?? 'Unknown';
      final state = customer?.state ?? 'Unknown';
      
      districtSales[district] = (districtSales[district] ?? 0.0) + inv.grandTotal;
      stateSales[state] = (stateSales[state] ?? 0.0) + inv.grandTotal;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('District Wise Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...districtSales.entries.map((e) => _buildReportCard(e.key, e.value, Icons.location_city, Colors.indigo)),
          const SizedBox(height: 32),
          const Text('State Wise Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...stateSales.entries.map((e) => _buildReportCard(e.key, e.value, Icons.public, Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, double amount, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildSubFilterDropdown() {
    if (_periodType == 'Monthly') {
      return DropdownButtonFormField<int>(
        value: _selectedMonth,
        decoration: const InputDecoration(labelText: 'Select Month', border: OutlineInputBorder()),
        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM').format(DateTime(2024, i + 1))))),
        onChanged: (val) => setState(() => _selectedMonth = val!),
      );
    } else if (_periodType == 'Yearly') {
      return DropdownButtonFormField<int>(
        value: _selectedYear,
        decoration: const InputDecoration(labelText: 'Select Year', border: OutlineInputBorder()),
        items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
        onChanged: (val) => setState(() => _selectedYear = val!),
      );
    } else if (_periodType == 'Weekly') {
      final weeks = _getWeeks();
      return DropdownButtonFormField<DateTime>(
        value: _selectedWeekStart,
        decoration: const InputDecoration(labelText: 'Select Week', border: OutlineInputBorder()),
        items: weeks.map((w) {
          final end = w.add(const Duration(days: 6));
          return DropdownMenuItem(value: w, child: Text('${DateFormat('MMM dd').format(w)} - ${DateFormat('MMM dd').format(end)}'));
        }).toList(),
        onChanged: (val) => setState(() => _selectedWeekStart = val!),
      );
    }
    return const SizedBox.shrink();
  }

  List<DateTime> _getWeeks() {
    DateTime firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    DateTime lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    
    List<DateTime> weeks = [];
    DateTime current = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    
    while (current.isBefore(lastDayOfMonth)) {
      weeks.add(current);
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; _periodType = 'Custom'; });
  }
}
