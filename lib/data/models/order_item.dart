import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int? id;
  final int? orderId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;
  final double subtotal;
  final double profit;

  const OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0,
    required this.subtotal,
    this.profit = 0,
  });

  Map<String, dynamic> toMap(int orderId) {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'subtotal': subtotal,
      'profit': profit,
    };
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'subtotal': subtotal,
      'profit': profit,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int,
      productName: (map['product_name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 1,
      unitPrice: ((map['unit_price'] ?? 0) as num).toDouble(),
      costPrice: ((map['cost_price'] ?? 0) as num).toDouble(),
      subtotal: ((map['subtotal'] ?? 0) as num).toDouble(),
      profit: ((map['profit'] ?? 0) as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, orderId, productId, quantity, subtotal];
}
