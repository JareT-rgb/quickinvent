import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'product.dart';
import 'category.dart';
import 'product_return.dart';
import 'sale_detail_item.dart';

class ProductsRepository {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    final response = await _client.from('products').select();
    return (response as List<dynamic>).map((e) => Product.fromMap(e)).toList();
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required int minStock,
    required bool isActive,
    String? barcode,
    String? categoryId,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
      'is_active': isActive,
      'category_id': categoryId != null ? int.tryParse(categoryId) : null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required double price,
    required int stockQuantity,
    required int minStock,
    required bool isActive,
    String? barcode,
    String? categoryId,
  }) async {
    await _client.from('products').update({
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'barcode': barcode,
      'is_active': isActive,
      'category_id': categoryId != null ? int.tryParse(categoryId) : null,
    }).eq('id', int.parse(productId));
  }

  Future<List<ProductReturn>> fetchReturns() async {
    final response = await _client.from('returns').select('*, products(name)');
    return (response as List<dynamic>).map((e) {
      return ProductReturn(
        id: e['id'].toString(),
        productId: e['product_id'].toString(),
        productName: e['products']?['name'] ?? 'Producto desconocido',
        quantity: e['quantity'] as int,
        amountReturned: (e['amount_returned'] as num).toDouble(),
        reason: e['reason'] as String?,
        createdAt: DateTime.parse(e['created_at']),
      );
    }).toList();
  }

  Future<List<SaleDetailItem>> fetchSaleDetails(int saleId) async {
    final response = await _client
        .from('sale_items')
        .select('*, products(name)')
        .eq('sale_id', saleId);
    return (response as List<dynamic>)
        .map((e) => SaleDetailItem.fromMap(e))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _client.from('categories').select();
    return (response as List<dynamic>)
        .map((e) => Category.fromMap(e))
        .toList();
  }

  Future<void> addCategory(String name) async {
    await _client.from('categories').insert({
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateCategory(int id, String newName) async {
    await _client.from('categories').update({'name': newName}).eq('id', id);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}

final productsRepositoryProvider = Provider((ref) => ProductsRepository());
