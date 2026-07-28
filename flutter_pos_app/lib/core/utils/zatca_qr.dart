import 'dart:convert';

class ZatcaQr {
  static String generate({
    required String sellerName,
    required String vatNumber,
    required DateTime timestamp,
    required double totalAmount,
    required double vatAmount,
  }) {
    final bytes = <int>[];

    void writeTlv(int tag, String value) {
      final utf8Bytes = utf8.encode(value);
      bytes.add(tag);
      bytes.add(utf8Bytes.length);
      bytes.addAll(utf8Bytes);
    }

    writeTlv(1, sellerName);
    writeTlv(2, vatNumber);
    writeTlv(3, _formatTimestamp(timestamp));
    writeTlv(4, totalAmount.toStringAsFixed(2));
    writeTlv(5, vatAmount.toStringAsFixed(2));

    return base64Encode(bytes);
  }

  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }
}
