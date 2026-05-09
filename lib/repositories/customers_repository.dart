import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Customer>> getCustomers() async {
    final response = await _client.from('customers').select().order('name');
    return (response as List<dynamic>).map((e) => Customer.fromMap(e)).toList();
  }

  Future<void> addCustomer(Customer customer) async {
    await _client.from('customers').insert(customer.toMap());
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _client.from('customers').update(data).eq('id', int.parse(id));
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', int.parse(id));
  }

  Future<void> updateBalance(String id, double amountChange) async {
    final response = await _client.from('customers').select('balance').eq('id', int.parse(id)).single();
    final currentBalance = (response['balance'] as num).toDouble();
    await _client.from('customers').update({'balance': currentBalance + amountChange}).eq('id', int.parse(id));
  }

  Future<void> processPayment(String customerId, double amount, String customerName) async {
    // 1. Decrease balance
    await updateBalance(customerId, -amount);

    // 2. Register as a sale/income so it counts in the cash register
    final user = _client.auth.currentUser;
    await _client.from('sales').insert({
      'total_amount': amount,
      'payment_method': 'Efectivo',
      'received_amount': amount,
      'change': 0,
      'item_count': 0,
      'customer_id': int.parse(customerId),
      'notes': 'Abono de cliente: $customerName',
      if (user != null) 'user_id': user.id,
    });
  }
}

final customersRepositoryProvider = Provider((ref) => CustomersRepository());
