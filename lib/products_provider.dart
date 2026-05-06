import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category.dart';
import 'product.dart';
import 'products_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsRepositoryProvider).getProducts();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(productsRepositoryProvider).fetchCategories();
});
