import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class EditSaleScreen extends StatefulWidget {
  final Sale sale;

  const EditSaleScreen({super.key, required this.sale});

  @override
  State<EditSaleScreen> createState() => _EditSaleScreenState();
}

class _EditSaleScreenState extends State<EditSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();

  Product? _selectedProduct;
  double _inputValue = 0;
  double? _totalPrice;
  bool _loading = false;
  List<Product> _products = [];

  final Color primaryColor = const Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _customerController.text = widget.sale.customerName;
    _inputValue = widget.sale.productType == 'kg'
        ? widget.sale.weightPerUnit
        : widget.sale.numUnits.toDouble();
    _totalPrice = widget.sale.totalPrice;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final user = await AuthService.getUser();
    final products = await ApiService.getProducts(userId: user!.$id);
    final product = products.firstWhere(
      (p) => p.name == widget.sale.productName,
      orElse: () => products.first,
    );

    setState(() {
      _products = products;
      _selectedProduct = product;
    });
  }

  void _calculateTotal() {
    if (_selectedProduct != null) {
      setState(() {
        _totalPrice = _inputValue * _selectedProduct!.rate;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate() &&
        _selectedProduct != null &&
        _totalPrice != null) {
      setState(() => _loading = true);

      final payload = {
        'product_id': _selectedProduct!.id,
        'weight_per_unit':
            _selectedProduct!.unitType == 'kg' ? _inputValue.toInt() : 0,
        'num_units':
            _selectedProduct!.unitType == 'kg' ? 1 : _inputValue.toInt(),
        'customer_name': _customerController.text.trim(),
        'total_price': _totalPrice!,
      };

      try {
        await ApiService.updateSale(widget.sale.id, payload);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Sale"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text(
                            "Update Sale Details",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _customerController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Product>(
                            value: _selectedProduct,
                            items: _products.map((product) {
                              return DropdownMenuItem<Product>(
                                value: product,
                                child: Text(product.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProduct = value;
                                _totalPrice = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Product',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value == null ? 'Please select a product' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedProduct != null)
                            Text(
                              "Pricing: ${_selectedProduct!.unitType} @ KES ${_selectedProduct!.rate.toStringAsFixed(2)} per ${_selectedProduct!.unitType}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _inputValue.toString(),
                            decoration: InputDecoration(
                              labelText: _selectedProduct?.unitType == 'kg'
                                  ? 'Enter weight (kg)'
                                  : 'Enter quantity (units)',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter a value';
                              }
                              final val = double.tryParse(value);
                              if (val == null || val <= 0) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _inputValue = double.tryParse(value) ?? 0;
                                _totalPrice = null;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _calculateTotal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Calculate Total'),
                          ),
                          if (_totalPrice != null)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Total: KES ${_totalPrice!.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _submitUpdate,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Update Sale'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
