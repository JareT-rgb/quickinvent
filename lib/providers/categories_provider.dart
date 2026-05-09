import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return Supabase.instance.client
      .from('categories')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((data) => data.map((json) => Category.fromJson(json)).toList());
});
