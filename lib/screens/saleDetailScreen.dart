import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/api_service.dart';
import 'edit_sale_screen.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;

  const SaleDetailScreen({super.key, required this.sale});

  String _formatQuantity(Sale sale) {
    final pricingType = sale.productType.toLowerCase();
    if (pricingType == 'kg') {
      double totalWeight = sale.numUnits * sale.weightPerUnit;
      return "${totalWeight.toStringAsFixed(2)} kg";
    } else if (pricingType == 'piece' || pricingType == 'unit') {
      return "${sale.numUnits} pcs";
    } else {
      return "${sale.numUnits} x ${sale.weightPerUnit}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sale Details"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditSaleScreen(sale: sale)),
              ).then((value) {
                if (value == true) Navigator.pop(context, true);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Sale"),
                  content: const Text("Are you sure you want to delete this sale?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete")),
                  ],
                ),
              );
              if (confirmed == true) {
                await ApiService.deleteSale(sale.id);
                if (context.mounted) Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _receiptRow("Product", sale.productName),
                _receiptRow("Quantity", _formatQuantity(sale)),
                _receiptRow("Rate", "KES ${sale.ratePerKg.toStringAsFixed(2)}"),
                _receiptRow("Total", "KES ${sale.totalPrice.toStringAsFixed(2)}"),
                _receiptRow("Customer", sale.customerName),
                _receiptRow("Date", DateFormat('dd MMM yyyy – hh:mm a').format(sale.date)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
