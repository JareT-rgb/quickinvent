class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final double balance; // Positive means debt (credit given to customer)
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.balance = 0.0,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'].toString(),
      name: map['name'] ?? 'Sin nombre',
      phone: map['phone'],
      email: map['email'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
    };
  }
}
