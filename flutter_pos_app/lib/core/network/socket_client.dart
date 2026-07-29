import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

typedef OrderUpdatedCallback = void Function(Map<String, dynamic> data);
typedef OrderNewCallback = void Function(Map<String, dynamic> data);
typedef NotificationNewCallback = void Function(Map<String, dynamic> data);

class SocketClient {
  static final SocketClient _instance = SocketClient._internal();
  factory SocketClient() => _instance;
  SocketClient._internal();

  io.Socket? socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  OrderUpdatedCallback? onOrderUpdated;
  OrderNewCallback? onOrderNew;
  NotificationNewCallback? onNotificationNew;

  bool _initialized = false;

  Future<void> initSocket({String? branchId, String? role}) async {
    if (_initialized) return;
    _initialized = true;

    final token = await _storage.read(key: 'accessToken');

    socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      if (branchId != null) {
        socket?.emit('join:branch', {'branchId': branchId});
      }
      if (role != null) {
        socket?.emit('join:role', {'role': role});
      }
    });

    socket?.on('order:updated', (data) {
      onOrderUpdated?.call(data as Map<String, dynamic>);
    });

    socket?.on('order:new', (data) {
      onOrderNew?.call(data as Map<String, dynamic>);
    });

    socket?.on('notification:new', (data) {
      onNotificationNew?.call(data as Map<String, dynamic>);
    });
  }

  void disconnect() {
    _initialized = false;
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
