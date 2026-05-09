class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) => Category.fromMap(json);

  // Requerido para que el DropdownButton pueda comparar objetos.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}