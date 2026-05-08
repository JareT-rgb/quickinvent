import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../repositories/products_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsRepositoryProvider).getProducts();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(productsRepositoryProvider).fetchCategories();
});
