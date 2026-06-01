import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/billing_provider.dart';
import 'billing_screen.dart';
import 'pdf_view_screen.dart';
import 'reports_screen.dart';
import 'items_screen.dart';
import 'party_list_screen.dart';
import 'party_master_screen.dart';
import 'product_master_screen.dart';
import 'new_master_flow_screen.dart';
import 'login_screen.dart';
import 'scanned_bills_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillingProvider>();
      provider.fetchInvoices();
      provider.init(); // Fetch products to ensure images show up
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Lighter background for contrast
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('OVG Dashboard', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_rounded, color: Color(0xFF1E3A8A)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF1E3A8A)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
            onPressed: () => context.read<BillingProvider>().fetchInvoices(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text('OVG Billing Master', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Tirupur, India', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.auto_fix_high_rounded, 'New Master Flow', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMasterFlowScreen()));
            }),
            _buildDrawerItem(Icons.person_add_alt_1_rounded, 'Party Master', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
            }),
            _buildDrawerItem(Icons.add_business_rounded, 'Product Master', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()));
            }),
            _buildDrawerItem(Icons.camera_alt_rounded, 'Scanned Bills (OCR)', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannedBillsScreen()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.bar_chart_rounded, 'Sales Reports', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
            const Divider(),
            _buildDrawerItem(Icons.logout_rounded, 'Logout', () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }),
          ],
        ),
      ),
      body: Consumer<BillingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final prodSales = provider.productSales;
          final todayVal = provider.getProductSalesStats(_selectedProduct, 'today');
          final weeklyVal = provider.getProductSalesStats(_selectedProduct, 'weekly');
          final monthlyVal = provider.getProductSalesStats(_selectedProduct, 'monthly');

          return RefreshIndicator(
            onRefresh: () => provider.fetchInvoices(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Product Filter ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedProduct,
                        hint: const Text('All Products Sales'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Show All Products')),
                          ...prodSales.keys.map((name) => DropdownMenuItem(value: name, child: Text(name))),
                        ],
                        onChanged: (val) => setState(() => _selectedProduct = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Minimalist Stats Grid ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard('Today', '₹${todayVal.toStringAsFixed(0)}', Icons.today_rounded, Colors.indigo),
                      _buildStatCard('Weekly', '₹${weeklyVal.toStringAsFixed(0)}', Icons.date_range_rounded, Colors.blue),
                      _buildStatCard('Monthly', '₹${monthlyVal.toStringAsFixed(0)}', Icons.calendar_month_rounded, Colors.teal),
                      _buildStatCard('Total Bills', '${provider.invoices.length}', Icons.description_outlined, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Top Products ---
                  if (prodSales.isNotEmpty && _selectedProduct == null) ...[
                    const Text('Top Products Sold', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: prodSales.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final name = prodSales.keys.elementAt(index);
                          final qty = prodSales.values.elementAt(index);
                          final imageUrl = provider.getProductImage(name);
                          
                          return InkWell(
                            onTap: () => setState(() => _selectedProduct = name),
                            child: Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: imageUrl != null 
                                          ? Image.network(
                                              ApiConstants.getImageUrl(imageUrl),
                                              fit: BoxFit.cover, 
                                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E3A8A))
                                            )
                                          : const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                                        const SizedBox(height: 4),
                                        Text('$qty NOS', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // --- Recent Invoices ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedProduct == null ? 'Recent Invoices' : 'Invoices for $_selectedProduct', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      if (_selectedProduct != null)
                        TextButton(onPressed: () => setState(() => _selectedProduct = null), child: const Text('Clear Filter')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (provider.invoices.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('No history found')))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final inv = provider.invoices[index];
                        if (_selectedProduct != null && !inv.items.any((item) => item['product_name'] == _selectedProduct)) {
                          return const SizedBox.shrink();
                        }
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text(inv.invoiceNumber, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${inv.grandTotal.toStringAsFixed(2)}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 16)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF1E3A8A)),
                                          onPressed: () => _launchWhatsApp(inv.customerMobile, inv.invoiceNumber),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            context.read<BillingProvider>().loadInvoiceForEditing(inv);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => BillingScreen()),
                                            ).then((_) => context.read<BillingProvider>().fetchInvoices());
                                          },
                                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A), size: 22),
                                          tooltip: 'Edit Invoice',
                                        ),
                                        IconButton(onPressed: () => _viewPdf(inv.id), icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blueAccent, size: 20)),
                                        IconButton(onPressed: () => _confirmDelete(inv.id), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<BillingProvider>().clearCart();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()))
              .then((_) => context.read<BillingProvider>().fetchInvoices());
        },
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: accentColor.withOpacity(0.9), fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      onTap: onTap,
    );
  }

  Future<void> _viewPdf(String id) async {
    final inv = context.read<BillingProvider>().invoices.firstWhere((i) => i.id == id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewScreen(
          url: '${ApiConstants.baseUrl}/invoices/$id/pdf',
          invoiceNumber: inv.invoiceNumber,
          invoice: inv,
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('This will permanently remove the bill record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { context.read<BillingProvider>().deleteInvoice(id); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
