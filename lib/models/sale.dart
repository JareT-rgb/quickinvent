import 'sale_detail_item.dart';

class Sale {
  final String id;
  final List<SaleDetailItem>? items;
  final double totalAmount;
  final String paymentMethod;
  final double receivedAmount;
  final double change;
  final DateTime createdAt;
  final int? itemCount;
  final String? notes;
  final String? customerId;

  Sale({
    required this.id,
    this.items,
    required this.totalAmount,
    this.paymentMethod = 'Efectivo',
    this.receivedAmount = 0.0,
    this.change = 0.0,
    required this.createdAt,
    this.itemCount,
    this.notes,
    this.customerId,
  });

  bool get hasReturns => items?.any((i) => i.returnedQuantity > 0) ?? false;
  double get totalRefunded => items?.fold<double>(0.0, (sum, i) => sum + (i.returnedQuantity * i.priceAtSale)) ?? 0.0;
  double get netAmount {
    final net = totalAmount - totalRefunded;
    return net < 0 ? 0.0 : net;
  }

  factory Sale.fromMap(Map<String, dynamic> data) {
    final rawItems = data['sale_items'] ?? data['sale_details'] ?? data['items'];
    List<SaleDetailItem>? parsedItems;
    if (rawItems is List) {
      parsedItems = rawItems
          .map((item) => SaleDetailItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    DateTime parsedDate;
    final rawDate = data['created_at'] ?? data['date'];
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate).toLocal();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate.toLocal();
    } else {
      parsedDate = DateTime.now().toLocal();
    }

    return Sale(
      id: data['id'].toString(),
      items: parsedItems,
      totalAmount:
          (data['total_amount'] as num?)?.toDouble() ??
          (data['total'] as num?)?.toDouble() ??
          0.0,
      paymentMethod: data['payment_method'] as String? ?? 'Efectivo',
      receivedAmount: (data['received_amount'] as num?)?.toDouble() ?? 0.0,
      change: (data['change'] as num?)?.toDouble() ?? 0.0,
      createdAt: parsedDate,
      itemCount: data['item_count'] as int? ?? parsedItems?.length,
      notes: data['notes'] as String?,
      customerId: data['customer_id']?.toString() ?? data['customerId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items?.map((item) => item.toMap()).toList() ?? [],
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'received_amount': receivedAmount,
      'change': change,
      'created_at': createdAt.toIso8601String(),
      'item_count': itemCount ?? items?.length ?? 0,
      'notes': notes,
      'customer_id': customerId,
    };
  }

  Sale copyWith({
    String? id,
    List<SaleDetailItem>? items,
    double? totalAmount,
    String? paymentMethod,
    double? receivedAmount,
    double? change,
    DateTime? createdAt,
    int? itemCount,
    String? customerId,
  }) {
    return Sale(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      change: change ?? this.change,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
      customerId: customerId ?? this.customerId,
    );
  }
}
