import 'package:flutter/material.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  String _orderType = 'dine_in'; // 'dine_in', 'takeaway', 'delivery'
  String? _selectedTableNumber;
  String? _customerName;
  String? _customerPhone;
  String? _deliveryAddress;
  double _discount = 0.0;
  final double _taxRate = 0.14; // 14% tax

  List<CartItemModel> get items => List.unmodifiable(_items);
  String get orderType => _orderType;
  String? get selectedTableNumber => _selectedTableNumber;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  String? get deliveryAddress => _deliveryAddress;
  double get discount => _discount;

  int get totalQuantity => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get tax => subtotal * _taxRate;
  double get total => (subtotal + tax - _discount).clamp(0.0, double.infinity);

  void setOrderType(String type) {
    _orderType = type;
    if (type != 'dine_in') {
      _selectedTableNumber = null;
    }
    notifyListeners();
  }

  void setTableNumber(String? tableNum) {
    _selectedTableNumber = tableNum;
    notifyListeners();
  }

  void setCustomerDetails({String? name, String? phone, String? address}) {
    _customerName = name;
    _customerPhone = phone;
    _deliveryAddress = address;
    notifyListeners();
  }

  void setDiscount(double discountAmount) {
    _discount = discountAmount;
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1, String? notes}) {
    final existingIndex = _items.indexWhere((i) => i.product.id == product.id && i.notes == notes);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity, notes: notes));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int newQty) {
    if (newQty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = newQty;
    }
    notifyListeners();
  }

  void updateNotes(int index, String? notes) {
    _items[index].notes = notes;
    notifyListeners();
  }

  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0.0;
    _selectedTableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _deliveryAddress = null;
    notifyListeners();
  }
}
