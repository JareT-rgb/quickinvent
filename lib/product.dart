class Product {
  final String id;
  final String name;
  final double price;
  final int stockQuantity;
  final int minStock;
  final bool isActive; // Corresponde a 'activo' en el esquema relacional
  final String? barcode; // Corresponde a 'codigo_barras'
  final String? categoryId; // Corresponde a 'categoria'
  final String? imagePath; // ¡Este es el campo que falta!
  final DateTime createdAt; // ¡Este es el otro campo que falta!

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.minStock,
    this.isActive = true, // Valor por defecto según el esquema
    this.barcode,
    this.categoryId,
    this.imagePath, // Hazlo opcional si no siempre habrá imagen
    required this.createdAt, // Hazlo requerido ya que es importante para auditoría
  });

  // Opcional: Puedes añadir un método copyWith para facilitar las actualizaciones
  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stockQuantity,
    int? minStock,
    bool? isActive,
    String? barcode,
    String? categoryId,
    String? imagePath,
    DateTime? createdAt,
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
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'] as int,
      minStock: 0, // La BD actual no tiene min_stock
      isActive: map['is_active'] as bool? ?? true,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id']?.toString(),
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'barcode': barcode,
      'category_id': categoryId != null ? int.tryParse(categoryId!) : null,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
