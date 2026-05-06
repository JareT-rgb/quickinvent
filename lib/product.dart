class Product {
  final String id;
  final String name;
  final double price;
  final int stockQuantity;
  final int minStock;
  final bool isActive;
  final String? barcode;
  final String? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isActive = true,
    this.barcode,
    this.categoryId,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'].toString(),
      name: data['name'] ?? 'Sin nombre',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: data['stock_quantity'] as int? ?? 0,
      minStock: data['min_stock'] as int? ?? 0,
      isActive: data['is_active'] as bool? ?? true,
      barcode: data['barcode'] as String?,
      categoryId: data['category_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'min_stock': minStock,
      'is_active': isActive,
      'barcode': barcode,
      'category_id': categoryId != null ? int.tryParse(categoryId!) : null,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stockQuantity,
    int? minStock,
    bool? isActive,
    String? barcode,
    String? categoryId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
