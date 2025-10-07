import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> allSales = [];
  List<Sale> filteredSales = [];
  bool isLoading = true;
  String searchQuery = '';
  bool sortAscending = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  Future<void> fetchSales() async {
    try {
      final sales = await ApiService.getSales();
      setState(() {
        allSales = sales;
        filteredSales = sales;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      setState(() => isLoading = false);
    }
  }

  void searchSales(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      applyFilters();
    });
  }

  void sortById() {
    setState(() {
      sortAscending = !sortAscending;
      filteredSales.sort((a, b) =>
          sortAscending ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
    });
  }

  void applyFilters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    filteredSales = allSales.where((sale) {
      final matchesSearch = sale.productName.toLowerCase().contains(searchQuery) ||
          sale.customerName.toLowerCase().contains(searchQuery);

      if (!matchesSearch) return false;

      switch (selectedFilter) {
        case 'Today':
          return sale.date.isAfter(today);
        case 'Last 7 Days':
          return sale.date.isAfter(now.subtract(const Duration(days: 7)));
        case 'This Month':
          return sale.date.month == now.month && sale.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  void updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      applyFilters();
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
                sortAscending ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: 'Sort by ID',
            onPressed: sortById,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 Search bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: searchSales,
                    decoration: const InputDecoration(
                      labelText: 'Search by product or customer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),

                // 🔹 Filter bar
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      buildFilterChip('All'),
                      buildFilterChip('Today'),
                      buildFilterChip('Last 7 Days'),
                      buildFilterChip('This Month'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 🔹 Sales list
                Expanded(
                  child: filteredSales.isEmpty
                      ? const Center(child: Text('No sales found.'))
                      : ListView.builder(
                          itemCount: filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = filteredSales[index];

                            String quantityText;
                            if (sale.productType.toLowerCase() == 'kg') {
                              quantityText =
                                  'Quantity: ${(sale.numUnits * sale.weightPerUnit).toStringAsFixed(2)} kg';
                            } else {
                              quantityText = 'Quantity: ${sale.numUnits}';
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            SaleDetailScreen(sale: sale)),
                                  );
                                },
                                child: ListTile(
                                  title: Text(
                                    '${sale.productName} (${sale.productType})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Customer: ${sale.customerName}'),
                                        Text(quantityText),
                                        Text(
                                            'Rate: Ksh ${sale.ratePerKg.toStringAsFixed(2)} per ${sale.productType}'),
                                        Text('Date: ${formatDate(sale.date)}'),
                                        Text('Sale ID: ${sale.id}'),
                                      ],
                                    ),
                                  ),
                                  trailing: Text(
                                    'Ksh ${sale.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == label,
        onSelected: (_) => updateFilter(label),
        selectedColor: Colors.blue.shade100,
      ),
    );
  }
}

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;
  const SaleDetailScreen({super.key, required this.sale});

  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy – hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    String quantityText;
    if (sale.productType.toLowerCase() == 'kg') {
      quantityText =
          'Quantity: ${(sale.numUnits * sale.weightPerUnit).toStringAsFixed(2)} kg';
    } else {
      quantityText = 'Quantity: ${sale.numUnits}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Receipt'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Inventory App',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 10),

              buildReceiptRow('Product', '${sale.productName} (${sale.productType})'),
              buildReceiptRow('Customer', sale.customerName),
              buildReceiptRow('Quantity', quantityText),
              buildReceiptRow('Rate',
                  'Ksh ${sale.ratePerKg.toStringAsFixed(2)} / ${sale.productType}'),
              const Divider(thickness: 1),
              buildReceiptRow(
                'Total',
                'Ksh ${sale.totalPrice.toStringAsFixed(2)}',
                isBold: true,
              ),
              const Divider(thickness: 1),
              buildReceiptRow('Date', formatDate(sale.date)),
              buildReceiptRow('Sale ID', sale.id.toString()),
              const SizedBox(height: 15),
              const Text(
                'Thank you for your business!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
