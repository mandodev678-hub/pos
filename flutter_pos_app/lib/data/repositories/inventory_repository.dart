import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/warehouse_model.dart';
import '../models/stock_item_model.dart';

class InventoryRepository {
  final ApiClient _apiClient = ApiClient();

  // ─── Warehouses ────────────────────────────────────────────────────────────
  Future<List<WarehouseModel>> getWarehouses() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.warehouses);
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => WarehouseModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب المستودعات: $e');
    }
  }

  // ─── Stock Levels ──────────────────────────────────────────────────────────
  Future<List<StockItemModel>> getStock({
    String? warehouseId,
    String? search,
    bool lowStockOnly = false,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (warehouseId != null) params['warehouse_id'] = warehouseId;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (lowStockOnly) params['low_stock_only'] = 'true';

      final response = await _apiClient.dio.get(
        ApiConstants.inventoryStock,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => StockItemModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب المخزون: $e');
    }
  }

  // ─── Stock Alerts ──────────────────────────────────────────────────────────
  Future<List<StockAlertModel>> getStockAlerts() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.inventoryAlerts);
      final data = response.data['data'] ?? response.data;
      final List<StockAlertModel> alerts = [];

      if (data is Map<String, dynamic>) {
        final low = data['lowStock'] as List? ?? [];
        final out = data['outOfStock'] as List? ?? [];
        for (var item in low) {
          alerts.add(StockAlertModel.fromJson(item, alertType: 'low_stock'));
        }
        for (var item in out) {
          alerts.add(StockAlertModel.fromJson(item, alertType: 'out_of_stock'));
        }
      } else if (data is List) {
        alerts.addAll(data.map((e) => StockAlertModel.fromJson(e)).toList());
      }

      return alerts;
    } catch (e) {
      debugPrint('Error fetching stock alerts: $e');
      return [];
    }
  }

  // ─── Stock Movements ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMovements({
    String? warehouseId,
    String? menuId,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (warehouseId != null) params['warehouse_id'] = warehouseId;
      if (menuId != null) params['menu_id'] = menuId;

      final response = await _apiClient.dio.get(
        ApiConstants.inventoryMovements,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب حركات المخزون: $e');
    }
  }

  // ─── Stock Adjustments List ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAdjustments({
    String? warehouseId,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (warehouseId != null) params['warehouse_id'] = warehouseId;

      final response = await _apiClient.dio.get(
        ApiConstants.inventoryAdjustments,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب التعديلات: $e');
    }
  }

  // ─── Create Stock Adjustment ───────────────────────────────────────────────
  Future<Map<String, dynamic>> adjustStock({
    required String menuId,
    required String warehouseId,
    required double quantityChange,
    required String reason,
    double? unitCost,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.inventoryAdjust,
        data: {
          'menu_id': menuId,
          'warehouse_id': warehouseId,
          'quantity_change': quantityChange,
          'reason': reason,
          'unit_cost': ?unitCost,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل تعديل المخزون: $e');
    }
  }

  // ─── Update Stock Min/Max Settings ────────────────────────────────────────
  Future<void> updateStockSettings({
    required String menuId,
    required String warehouseId,
    double? minStock,
    double? maxStock,
  }) async {
    try {
      await _apiClient.dio.put(
        ApiConstants.stockSettings(menuId),
        data: {
          'warehouse_id': warehouseId,
          'min_stock': ?minStock,
          'max_stock': ?maxStock,
        },
      );
    } catch (e) {
      throw Exception('فشل تحديث إعدادات المخزون: $e');
    }
  }

  // ─── Inventory Products (for purchase forms) ───────────────────────────────
  Future<List<Map<String, dynamic>>> getInventoryProducts({
    String? search,
    String? itemType,
    bool trackStockOnly = false,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (itemType != null) params['item_type'] = itemType;
      if (trackStockOnly) params['track_stock'] = 'true';

      final response = await _apiClient.dio.get(
        ApiConstants.inventoryProducts,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب منتجات المخزون: $e');
    }
  }

  // ─── Quick Create Product ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> quickCreateProduct({
    required String nameAr,
    String? nameEn,
    String? sku,
    String? barcode,
    String itemType = 'raw_material',
    String unitOfMeasure = 'piece',
    double? costPrice,
    double? sellingPrice,
    double minStock = 0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.inventoryQuickProduct,
        data: {
          'name_ar': nameAr,
          if (nameEn != null && nameEn.isNotEmpty) 'name_en': nameEn,
          if (sku != null && sku.isNotEmpty) 'sku': sku,
          if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
          'item_type': itemType,
          'unit_of_measure': unitOfMeasure,
          'cost_price': ?costPrice,
          'selling_price': ?sellingPrice,
          'min_stock': minStock,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل إنشاء المنتج: $e');
    }
  }
}
