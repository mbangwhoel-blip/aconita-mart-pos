import 'package:equatable/equatable.dart';
import 'package:aconita_mart_pos/data/models/product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double unitPrice;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;
  double get profit => (unitPrice - product.costPrice) * quantity;

  CartItem copyWith({int? quantity, double? unitPrice}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity, unitPrice];
}
