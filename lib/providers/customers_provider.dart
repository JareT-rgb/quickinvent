import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../repositories/customers_repository.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  return ref.watch(customersRepositoryProvider).getCustomers();
});
