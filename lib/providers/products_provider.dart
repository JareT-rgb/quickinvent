import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Stream that listens to real-time changes on the products table.
final productsProvider = StreamProvider<List<Product>>((ref) {
  return Supabase.instance.client
      .from('products')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((e) => Product.fromMap(e)).toList());
});
