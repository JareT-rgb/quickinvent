/// Representa una venta registrada en el sistema.
class Sale {
  /// El identificador único de la venta.
  final int id;
  /// La fecha y hora en que se creó la venta.
  final DateTime createdAt;
  /// El monto total de la venta.
  final double totalAmount;
  /// El método de pago utilizado ('Efectivo', 'Tarjeta', etc.).
  final String paymentMethod;
  /// Monto recibido del cliente.
  final double receivedAmount;
  /// Cambio entregado al cliente.
  final double change;
  /// Lista de items vendidos.
  final List<dynamic> items;
  /// El número total de artículos en la venta.
  final int? itemCount;

  Sale({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    this.receivedAmount = 0.0,
    this.change = 0.0,
    required this.items,
    this.itemCount,
  });

  /// Crea una instancia de [Sale] a partir de un mapa (JSON).
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      receivedAmount: (map['received_amount'] as num?)?.toDouble() ?? 0.0,
      change: (map['change'] as num?)?.toDouble() ?? 0.0,
      items: map['items'] as List<dynamic>? ?? [],
      itemCount: (map['item_count'] as int?) ?? 0,
    );
  }
}
