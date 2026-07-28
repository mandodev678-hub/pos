import 'package:flutter/material.dart';
import '../../core/network/socket_client.dart';

class ReadyOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String? tableNumber;
  final double total;
  final String? customerName;
  final DateTime updatedAt;

  ReadyOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.tableNumber,
    this.total = 0,
    this.customerName,
    required this.updatedAt,
  });

  factory ReadyOrder.fromJson(Map<String, dynamic> json) {
    return ReadyOrder(
      id: json['id'] ?? json['orderId'] ?? '',
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      status: json['status'] ?? '',
      tableNumber: json['table_number'] ?? json['tableNumber'],
      total: (json['total'] as num?)?.toDouble() ?? 0,
      customerName: json['customer_name'] ?? json['customerName'],
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class KdsProvider extends ChangeNotifier {
  final List<ReadyOrder> _readyOrders = [];
  int _newReadyOrders = 0;

  List<ReadyOrder> get readyOrders => List.unmodifiable(_readyOrders);
  int get readyCount => _readyOrders.length;
  int get newReadyCount => _newReadyOrders;

  void init(SocketClient socketClient) {
    socketClient.onOrderUpdated = _handleOrderUpdated;
    socketClient.onOrderNew = _handleOrderNew;
  }

  void _handleOrderUpdated(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final orderId = data['id'] as String? ?? data['orderId'] as String?;

    if (status == 'ready' && orderId != null) {
      final existing = _readyOrders.indexWhere((o) => o.id == orderId);
      if (existing == -1) {
        final order = ReadyOrder.fromJson(data);
        _readyOrders.add(order);
        _newReadyOrders++;
        notifyListeners();
      }
    } else if (orderId != null && (status == 'handed_to_cashier' || status == 'completed' || status == 'cancelled')) {
      _readyOrders.removeWhere((o) => o.id == orderId);
      notifyListeners();
    }
  }

  void _handleOrderNew(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status == 'ready') {
      _handleOrderUpdated(data);
    }
  }

  void acknowledgeReadyOrders() {
    _newReadyOrders = 0;
    notifyListeners();
  }

  void removeReadyOrder(String orderId) {
    _readyOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  void clearAll() {
    _readyOrders.clear();
    _newReadyOrders = 0;
    notifyListeners();
  }
}
