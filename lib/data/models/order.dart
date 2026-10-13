import 'package:equatable/equatable.dart';
import 'package:aconita_mart_pos/data/models/order_item.dart';

class Order extends Equatable {
  final int? id;
  final String orderNo;
  final int? memberId;
  final String? memberName;
  final DateTime orderDate;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String paymentStatus;
  final double totalProfit;
  final bool isSynced;
  final String? notes;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.orderNo,
    this.memberId,
    this.memberName,
    required this.orderDate,
    required this.totalAmount,
    this.discountAmount = 0,
    required this.finalAmount,
    required this.paidAmount,
    this.changeAmount = 0,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
    this.totalProfit = 0,
    this.isSynced = false,
    this.notes,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_no': orderNo,
      'member_id': memberId,
      'member_name': memberName,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'total_profit': totalProfit,
      'is_synced': isSynced ? 1 : 0,
      'notes': notes,
    };
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'order_no': orderNo,
      'member_id': memberId,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'total_profit': totalProfit,
      'notes': notes,
      'items': items.map((item) => item.toSyncJson()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) {
    return Order(
      id: map['id'] as int?,
      orderNo: map['order_no'] as String,
      memberId: map['member_id'] as int?,
      memberName: map['member_name'] as String?,
      orderDate: DateTime.parse(map['order_date'] as String),
      totalAmount: ((map['total_amount'] ?? 0) as num).toDouble(),
      discountAmount: ((map['discount_amount'] ?? 0) as num).toDouble(),
      finalAmount: ((map['final_amount'] ?? 0) as num).toDouble(),
      paidAmount: ((map['paid_amount'] ?? 0) as num).toDouble(),
      changeAmount: ((map['change_amount'] ?? 0) as num).toDouble(),
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      paymentStatus: (map['payment_status'] as String?) ?? 'paid',
      totalProfit: ((map['total_profit'] ?? 0) as num).toDouble(),
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
      notes: map['notes'] as String?,
      items: items,
    );
  }

  @override
  List<Object?> get props => [id, orderNo, finalAmount, isSynced];
}
