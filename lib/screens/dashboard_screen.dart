import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;

import '../models/sale.dart';
import '../services/api_service.dart';
import 'add_sale_screen.dart';
import 'edit_sale_screen.dart';
import 'product_screen.dart';
import 'sales_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  String _sortOption = 'Last 7 Days';

  final Color primaryColor = Colors.blue;
  final Color revenueColor = Colors.green;

  String? userName; // <- dynamic user name

  @override
  void initState() {
    super.initState();
    _fetchSales();
    _fetchUser(); // also grab user on load
  }

  Future<void> _fetchUser() async {
    try {
      final client = Client()
        ..setEndpoint('https://cloud.appwrite.io/v1') // your endpoint
        ..setProject('YOUR_PROJECT_ID'); // your project ID

      final account = Account(client);
      final appwrite_models.User user = await account.get();
      setState(() {
        // Appwrite has user.name, or you could fall back to email
        userName = user.name.isNotEmpty ? user.name : user.email;
      });
    } catch (e) {
      debugPrint("Failed to fetch user: $e");
      setState(() {
        userName = "User"; // fallback
      });
    }
  }

  Future<void> _fetchSales() async {
    try {
      final user = await AuthService.getUser();
final sales = await ApiService.fetchSales(userId: user!.$id);
setState(() {
  _allSales = sales;
  _applyFilter(_sortOption);
  _isLoading = false;
});
    } catch (e) {
      debugPrint("Failed to load sales: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String option) {
    DateTime now = DateTime.now();
    List<Sale> filtered;

    if (option == 'Last 7 Days') {
      final cutoff = now.subtract(const Duration(days: 7));
      filtered = _allSales.where((sale) => sale.date.isAfter(cutoff)).toList();
    } else if (option == 'This Month') {
      filtered = _allSales
          .where((sale) =>
              sale.date.year == now.year && sale.date.month == now.month)
          .toList();
    } else {
      filtered = List.from(_allSales);
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _sortOption = option;
      _filteredSales = filtered;
    });
  }

  Future<void> _deleteSale(String saleId) async {
    try {
      await ApiService.deleteSale(saleId);
      _fetchSales();
    } catch (e) {
      debugPrint("Error deleting sale: $e");
    }
  }

  String _formatQuantity(Sale sale) {
    if (sale.productType == 'piece' || sale.productType == 'unit') {
      return "${sale.numUnits.toStringAsFixed(0)}";
    } else if (sale.productType == 'kg') {
      double totalWeight = sale.numUnits * sale.weightPerUnit;
      return "${totalWeight.toStringAsFixed(2)} kg";
    } else {
      return "${sale.numUnits} x ${sale.weightPerUnit}";
    }
  }

  double _calculateTotalRevenue() {
    return _filteredSales.fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  Widget _buildSalesList() {
    return ListView.builder(
      itemCount: _filteredSales.length,
      itemBuilder: (context, index) {
        final sale = _filteredSales[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.shopping_bag, color: primaryColor),
            ),
            title: Text(
              sale.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "Quantity: ${_formatQuantity(sale)} • KES ${sale.totalPrice.toStringAsFixed(2)}\n"
              "Customer: ${sale.customerName} • ${DateFormat('dd MMM yyyy').format(sale.date)}",
              style: const TextStyle(fontSize: 14),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade600),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditSaleScreen(sale: sale)),
                    ).then((value) {
                      if (value == true) _fetchSales();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSale(sale.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardBody() {
    final totalRevenue = _calculateTotalRevenue();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Sales Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Sale',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSaleScreen()),
              ).then((value) {
                if (value == true) _fetchSales();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              DropdownButton<String>(
                value: _sortOption,
                items: const [
                  DropdownMenuItem(
                      value: 'Last 7 Days', child: Text('Last 7 Days')),
                  DropdownMenuItem(
                      value: 'This Month', child: Text('This Month')),
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                ],
                onChanged: (value) {
                  if (value != null) _applyFilter(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? const Center(
                        child: Text("No sales recorded in this range."))
                    : _buildSalesList(),
          ),
          if (!_isLoading && _filteredSales.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: revenueColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Revenue",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      "KES ${totalRevenue.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  List<Widget> get _screens => [
        _buildDashboardBody(),
        const ProductScreen(),
        const SalesScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront),
            SizedBox(width: 8),
            Text(
              'Inventory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  userName != null
                      ? "Welcome, $userName"
                      : "Loading...", // now dynamic
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Sales"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
