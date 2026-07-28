import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pos_app/presentation/screens/inventory_barcode_flow.dart';

void main() {
  group('Inventory barcode flow', () {
    test('normalizes a scanned barcode value', () {
      expect(InventoryBarcodeFlow.normalizeBarcode('  1234567890  '), '1234567890');
    });

    test('returns null for empty barcode input', () {
      expect(InventoryBarcodeFlow.normalizeBarcode('   '), isNull);
      expect(InventoryBarcodeFlow.normalizeBarcode(null), isNull);
    });
  });
}
