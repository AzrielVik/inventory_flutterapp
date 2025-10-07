class Sale {
  final String id;              // always String
  final String productType;
  final String productName;
  final double weightPerUnit;
  final int numUnits;
  final double ratePerKg;       // maps from "price_per_unit"
  final String customerName;
  final double totalPrice;
  final DateTime date;

  // New fields
  final String mpesaNumber;     // ✅ required in DB
  final String? checkoutId;     // ✅ optional

  Sale({
    required this.id,
    required this.productType,
    required this.productName,
    required this.weightPerUnit,
    required this.numUnits,
    required this.ratePerKg,
    required this.customerName,
    required this.totalPrice,
    required this.date,
    required this.mpesaNumber,  // ✅ must be passed
    this.checkoutId,            // ✅ optional
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString() ?? json['\$id'] ?? '',
      productType: json['product_type'] ?? '',
      productName: json['product_name'] ?? '',
      weightPerUnit: (json['weight_per_unit'] as num?)?.toDouble() ?? 0.0,
      numUnits: json['num_units'] ?? 0,
      ratePerKg: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customer_name'] ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),

      // New fields
      mpesaNumber: json['mpesaNumber'] ?? '',   // ✅ always string
      checkoutId: json['checkoutId'],           // ✅ may be null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_type': productType,
      'product_name': productName,
      'weight_per_unit': weightPerUnit,
      'num_units': numUnits,
      'price_per_unit': ratePerKg,
      'customer_name': customerName,
      'total_price': totalPrice,
      'date': date.toIso8601String(),

      // New fields
      'mpesaNumber': mpesaNumber,
      if (checkoutId != null) 'checkoutId': checkoutId,
    };
  }

  @override
  String toString() {
    return 'Sale(id: $id, productType: $productType, productName: $productName, weightPerUnit: $weightPerUnit, numUnits: $numUnits, ratePerKg: $ratePerKg, customerName: $customerName, totalPrice: $totalPrice, date: $date, mpesaNumber: $mpesaNumber, checkoutId: $checkoutId)';
  }
}
