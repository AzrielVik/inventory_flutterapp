import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../services/mpesa_service.dart';


class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _mpesaController = TextEditingController();
  Product? _selectedProduct;
  List<TextEditingController> _quantityControllers = [];
  double? _totalPrice;
  bool _loading = false;
  bool _isMpesa = false;
  List<Product> _products = [];

  String? _checkoutRequestId;
  bool _promptSent = false;

  final Color primaryColor = const Color(0xFFF57C00); // brand color

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _addQuantityField();
  }

  Future<void> _fetchProducts() async {
    final currentUser = await AuthService.getUser();
    if (currentUser == null) return;

    final products = await ApiService.getProducts(userId: currentUser.$id);
    setState(() {
      _products = products;
    });
  }

  void _addQuantityField() {
    setState(() {
      _quantityControllers.add(TextEditingController());
    });
  }

  void _removeQuantityField(int index) {
    setState(() {
      _quantityControllers.removeAt(index);
    });
  }

  void _calculateTotal() {
    if (_selectedProduct == null) return;

    double totalQuantity = 0;
    for (final controller in _quantityControllers) {
      final quantity = double.tryParse(controller.text.trim());
      if (quantity != null && quantity > 0) {
        totalQuantity += quantity;
      }
    }

    setState(() {
      _totalPrice = totalQuantity * _selectedProduct!.rate;
    });
  }

  Future<void> _promptPayment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedProduct == null ||
        _totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields and calculate total before prompting payment")),
      );
      return;
    }

    if (_mpesaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter M-Pesa number")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final mpesaResponse = await MpesaService(baseUrl: 'http://192.168.8.26:5000')
          .promptPayment(
        amount: _totalPrice!,
        phoneNumber: _mpesaController.text.trim(),
      );

      _checkoutRequestId = mpesaResponse['CheckoutRequestID'];
      _promptSent = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("M-Pesa prompt sent. CheckoutRequestID: ${_checkoutRequestId ?? 'pending'}"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Prompt Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitSale() async {
    final currentUser = await AuthService.getUser();
    if (currentUser == null) return;

    if (!_formKey.currentState!.validate() ||
        _selectedProduct == null ||
        _totalPrice == null) return;

    if (_isMpesa && !_promptSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please send M-Pesa prompt first")),
      );
      return;
    }

    setState(() => _loading = true);

    double totalQuantity = 0;
    for (final controller in _quantityControllers) {
      final quantity = double.tryParse(controller.text.trim());
      if (quantity != null && quantity > 0) totalQuantity += quantity;
    }

    try {
      final success = await ApiService.addSale(
        productId: _selectedProduct!.id,
        customerName: _customerController.text.trim(),
        total: _totalPrice!,
        weightPerUnit: _selectedProduct!.unitType == 'kg' ? totalQuantity : null,
        numUnits: _selectedProduct!.unitType != 'kg' ? totalQuantity.toInt() : null,
        mpesaNumber: _isMpesa ? _mpesaController.text.trim() : "",
        userId: currentUser.$id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit sale')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _mpesaController.dispose();
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Sale"),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Customer Info
                    _buildSectionTitle("Customer Info"),
                    _buildCard(
                      child: TextFormField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter customer name'
                                : null,
                      ),
                    ),

                    // Product Info
                    _buildSectionTitle("Product Info"),
                    _buildCard(
                      child: DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                          labelText: 'Select Product',
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
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
                            _quantityControllers = [TextEditingController()];
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a product' : null,
                      ),
                    ),
                    if (_selectedProduct != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          "KES ${_selectedProduct!.rate.toStringAsFixed(2)} per ${_selectedProduct!.unitType}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                    // Payment Method
                    _buildSectionTitle("Payment Method"),
                    _buildCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text("Pay with M-Pesa"),
                              const Spacer(),
                              Switch(
                                activeColor: primaryColor,
                                value: _isMpesa,
                                onChanged: (val) => setState(() {
                                  _isMpesa = val;
                                  _promptSent = false;
                                  _checkoutRequestId = null;
                                }),
                              ),
                            ],
                          ),
                          if (_isMpesa) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mpesaController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Customer M-Pesa Number',
                                prefixIcon: Icon(Icons.phone_android),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_isMpesa &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Enter M-Pesa number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _promptPayment,
                              icon: const Icon(Icons.flash_on),
                              label: const Text("Prompt Payment"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Sale Details
                    if (_selectedProduct != null) ...[
                      _buildSectionTitle("Sale Details"),
                      _buildCard(
                        child: Column(
                          children: [
                            ..._quantityControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: '${_selectedProduct!.unitType}',
                                          prefixIcon: const Icon(Icons.scale),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          final val = double.tryParse(value ?? '');
                                          if (val == null || val <= 0) {
                                            return 'Enter valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_quantityControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => _removeQuantityField(index),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _addQuantityField,
                                icon: const Icon(Icons.add),
                                label: Text("Add another ${_selectedProduct!.unitType}"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Calculate & Total
                    ElevatedButton(
                      onPressed: _selectedProduct != null ? _calculateTotal : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Calculate Total'),
                    ),
                    if (_totalPrice != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "Total: KES ${_totalPrice!.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Submit
                    ElevatedButton.icon(
                      onPressed: _submitSale,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Submit Sale', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
