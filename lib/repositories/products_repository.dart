import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/product.dart';
import '../models/sale_detail_item.dart';
import '../models/category.dart';
import '../models/product_return.dart';

import 'package:image_picker/image_picker.dart';

class ProductsRepository {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;
  static const String _bucketName = 'product-images';

  Future<List<Product>> getProducts() async {
    final response = await _client.from('products').select();
    return (response as List<dynamic>).map((e) => Product.fromMap(e)).toList();
  }

  Future<String?> uploadProductImage(String productName, XFile imageFile) async {
    try {
      // Crear bucket si no existe
      try {
        await _client.storage.createBucket(_bucketName);
      } catch (e) {
        // El bucket ya existe, ignorar error
      }

      final fileExt = imageFile.name.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$productName.$fileExt';
      final filePath = fileName.replaceAll(' ', '_');

      final bytes = await imageFile.readAsBytes();
      await _client.storage.from(_bucketName).uploadBinary(filePath, bytes);

      final imageUrl = _client.storage.from(_bucketName).getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteProductImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final filePath = pathSegments.last;
        await _client.storage.from(_bucketName).remove([filePath]);
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required int stockQuantity,
    required int minStock,
    required bool isActive,
    String? barcode,
    String? categoryId,
    String? imageUrl,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'min_stock': minStock,
      'barcode': barcode,
      'is_active': isActive,
      'category_id': categoryId != null ? int.tryParse(categoryId) : null,
      'image_url': imageUrl,
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
    String? imageUrl,
  }) async {
    await _client
        .from('products')
        .update({
          'name': name,
          'price': price,
          'stock_quantity': stockQuantity,
          'min_stock': minStock,
          'barcode': barcode,
          'is_active': isActive,
          'category_id': categoryId != null ? int.tryParse(categoryId) : null,
          'image_url': imageUrl,
        })
        .eq('id', int.parse(productId));
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', int.parse(id));
  }

  Future<void> updateProductStock(int productId, int quantityChange) async {
    // Para asegurar que la operación es segura en concurrencia (si fuera RPC), pero 
    // en Flutter/Supabase sin RPC haremos una lectura y luego actualización.
    // Idealmente esto debería ser una función RPC en Supabase: "increment_stock"
    final response = await _client
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();
    
    final currentStock = response['stock_quantity'] as int;
    await _client
        .from('products')
        .update({'stock_quantity': currentStock + quantityChange})
        .eq('id', productId);
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
    return (response as List<dynamic>).map((e) => Category.fromMap(e)).toList();
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
