class InventoryBarcodeFlow {
  static String? normalizeBarcode(String? rawBarcode) {
    if (rawBarcode == null) return null;
    final normalized = rawBarcode.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
