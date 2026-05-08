import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../repositories/products_repository.dart';

/// Stream that listens to real-time changes on the products table.
final productsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('products')
      .stream(primaryKey: ['id']);
});

/// Stream that listens to real-time changes on the categories table.
final categoriesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('categories')
      .stream(primaryKey: ['id']);
});

/// Products provider that uses the Realtime stream data directly.
final productsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final streamAsync = ref.watch(productsStreamProvider);
  
  return streamAsync.when(
    data: (data) => AsyncValue.data(
      data.map((e) => Product.fromMap(e)).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

/// Categories provider that uses the Realtime stream data directly.
final categoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final streamAsync = ref.watch(categoriesStreamProvider);
  
  return streamAsync.when(
    data: (data) => AsyncValue.data(
      data.map((e) => Category.fromMap(e)).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
