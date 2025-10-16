class Product {
  final String id;      
  final String name;
  final String unitType;
  final double rate;

  Product({
    required this.id,
    required this.name,
    required this.unitType,
    required this.rate,
  });

  // Create Product from API response
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? json['\$id'])?.toString() ?? '', 
      name: json['name'] ?? '',
      unitType: json['unit_type'] ?? '',
      rate: (json['rate'] as num).toDouble(),
    );
  }

  // Send Product to API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit_type': unitType,
      'rate': rate,
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, unitType: $unitType, rate: $rate)';
  }
}
