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
      // Ensure bucket exists and is public
      try {
        await _client.storage.createBucket(_bucketName, const sb.BucketOptions(public: true));
      } catch (_) {
        // Silently continue if bucket already exists
      }

      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${productName.replaceAll(RegExp(r'[^\w\s]+'), '')}.$fileExt';
      final filePath = fileName.replaceAll(' ', '_');

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (fileExt == 'png') contentType = 'image/png';
      if (fileExt == 'gif') contentType = 'image/gif';
      if (fileExt == 'webp') contentType = 'image/webp';

      final bytes = await imageFile.readAsBytes();
      
      await _client.storage.from(_bucketName).uploadBinary(
        filePath, 
        bytes,
        fileOptions: sb.FileOptions(
          contentType: contentType,
          upsert: true,
          cacheControl: '3600',
        ),
      );

      final imageUrl = _client.storage.from(_bucketName).getPublicUrl(filePath);
      
      // Ensure URL is clean (some Supabase versions add query params)
      final cleanUrl = imageUrl.split('?').first;
      debugPrint('Image uploaded successfully: $cleanUrl');
      return cleanUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
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
    double costPrice = 0.0,
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
      'cost_price': costPrice,
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
    double costPrice = 0.0,
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
          'cost_price': costPrice,
        })
        .eq('id', int.parse(productId));
  }

  Future<void> deleteProduct(String id) async {
    // Instead of a hard delete, we perform a "soft delete" by deactivating it.
    // This prevents errors if the product is already linked to sales.
    await _client.from('products').update({
      'is_active': false,
    }).eq('id', int.parse(id));
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

  /// Importa una lista de productos comunes, creando las categorías si no existen.
  Future<void> importCommonProducts(List<Map<String, dynamic>> products) async {
    // 1. Obtener todas las categorías existentes para no duplicar
    final categories = await fetchCategories();
    final categoryMap = {for (var c in categories) c.name.toLowerCase(): c.id};

    for (final item in products) {
      final categoryName = item['category'] as String;
      int? categoryId;

      // 2. Resolver o crear categoría
      if (categoryMap.containsKey(categoryName.toLowerCase())) {
        categoryId = categoryMap[categoryName.toLowerCase()];
      } else {
        // Crear nueva categoría
        final newCatResponse = await _client.from('categories').insert({
          'name': categoryName,
          'created_at': DateTime.now().toIso8601String(),
        }).select('id').single();
        
        categoryId = newCatResponse['id'] as int;
        categoryMap[categoryName.toLowerCase()] = categoryId;
      }

      // 3. Verificar si el código de barras ya existe para evitar errores
      if (item['barcode'] != null) {
        final existing = await _client
            .from('products')
            .select('id')
            .eq('barcode', item['barcode'])
            .maybeSingle();
        
        if (existing != null) {
          // Si ya existe, saltamos este producto
          continue;
        }
      }

      // 4. Insertar producto
      await addProduct(
        name: item['name'],
        price: item['price'],
        stockQuantity: item['stock_quantity'],
        minStock: item['min_stock'],
        isActive: true,
        barcode: item['barcode'],
        categoryId: categoryId?.toString(),
      );
    }
  }

  /// Bulk inserts products from a list of maps.
  /// Bulk inserts products from a list of maps.
  Future<void> bulkInsertProducts(List<Map<String, dynamic>> items) async {
    final Map<String, Map<String, dynamic>> toUpsertMap = {};
    final List<Map<String, dynamic>> toInsertList = [];

    for (var item in items) {
      final barcode = item['barcode']?.toString().trim();
      final Map<String, dynamic> data = {
        'name': item['name'],
        'price': item['price'],
        'stock_quantity': item['stock_quantity'],
        'min_stock': item['min_stock'],
        'barcode': (barcode != null && barcode.isNotEmpty) ? barcode : null,
        'is_active': item['is_active'] ?? true,
        'category_id': item['category_id'] != null ? int.tryParse(item['category_id'].toString()) : null,
        'image_url': item['image_url'],
        'cost_price': item['cost_price'] ?? 0.0,
      };

      if (barcode != null && barcode.isNotEmpty) {
        toUpsertMap[barcode] = data;
      } else {
        toInsertList.add(data);
      }
    }

    // 1. Upsert items with barcodes (updates if exists, creates if not)
    if (toUpsertMap.isNotEmpty) {
      await _client.from('products').upsert(
        toUpsertMap.values.toList(),
        onConflict: 'barcode',
      );
    }

    // 2. Insert items without barcodes (always creates new)
    if (toInsertList.isNotEmpty) {
      await _client.from('products').insert(toInsertList);
    }
  }
}

final productsRepositoryProvider = Provider((ref) => ProductsRepository());
