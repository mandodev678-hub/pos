import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? notes;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menu_id': product.id,
      'quantity': quantity,
      'unit_price': product.price,
      'total_price': totalPrice,
      'notes': notes,
    };
  }
}
