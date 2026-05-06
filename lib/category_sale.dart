class CategorySale {
  final String categoryName;
  final double totalSales;

  CategorySale({required this.categoryName, required this.totalSales});

  factory CategorySale.fromMap(Map<String, dynamic> map) {
    return CategorySale(
      // Si la categoría es nula en la BD, le asignamos un nombre por defecto.
      categoryName: (map['category_name'] as String?) ?? 'Sin Categoría',
      totalSales: (map['total_sales'] as num).toDouble(),
    );
  }
}