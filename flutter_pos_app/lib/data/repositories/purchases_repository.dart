import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/purchase_model.dart';
import '../models/supplier_model.dart';

class PurchasesRepository {
  final ApiClient _apiClient = ApiClient();

  // ─── Suppliers ────────────────────────────────────────────────────────────
  Future<List<SupplierModel>> getSuppliers({String? search, String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null) params['status'] = status;
      final response = await _apiClient.dio.get(
        ApiConstants.suppliers,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => SupplierModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب الموردين: $e');
    }
  }

  Future<Map<String, dynamic>> getSupplierById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.supplierById(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل جلب بيانات المورد: $e');
    }
  }

  Future<SupplierModel> createSupplier({
    required String nameAr,
    String? nameEn,
    String? phone,
    String? email,
    String? address,
    int paymentTerms = 30,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.suppliers,
        data: {
          'name_ar': nameAr,
          'name_en': ?nameEn,
          'phone': ?phone,
          'email': ?email,
          'address': ?address,
          'payment_terms': paymentTerms,
        },
      );
      return SupplierModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      throw Exception('فشل إضافة المورد: $e');
    }
  }

  Future<SupplierModel> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.supplierById(id),
        data: data,
      );
      return SupplierModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      throw Exception('فشل تحديث المورد: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _apiClient.dio.delete(ApiConstants.supplierById(id));
    } catch (e) {
      throw Exception('فشل حذف المورد: $e');
    }
  }

  Future<Map<String, dynamic>> addSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? notes,
    String? purchaseOrderId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.supplierPayments(supplierId),
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'notes': ?notes,
          'purchase_order_id': ?purchaseOrderId,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل تسجيل الدفعة: $e');
    }
  }

  Future<Map<String, dynamic>> getSupplierStatement(
    String id, {
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;
      final response = await _apiClient.dio.get(
        ApiConstants.supplierStatement(id),
        queryParameters: params.isNotEmpty ? params : null,
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل جلب كشف حساب المورد: $e');
    }
  }

  // ─── Direct Purchases (Receipts) ──────────────────────────────────────────
  Future<List<PurchaseModel>> getPurchases({
    String? status,
    String? supplierId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;
      if (supplierId != null) params['supplier_id'] = supplierId;
      final response = await _apiClient.dio.get(
        ApiConstants.purchases,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => PurchaseModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب المشتريات: $e');
    }
  }

  Future<Map<String, dynamic>> createPurchase({
    required String supplierId,
    required String warehouseId,
    required List<Map<String, dynamic>> items,
    String? invoiceNumber,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.purchases,
        data: {
          'supplier_id': supplierId,
          'warehouse_id': warehouseId,
          'items': items,
          'invoice_number': ?invoiceNumber,
          'notes': ?notes,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل إنشاء الفاتورة: $e');
    }
  }

  // ─── Purchase Orders ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPurchaseOrders({
    String? status,
    String? supplierId,
    String? warehouseId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;
      if (supplierId != null) params['supplier_id'] = supplierId;
      if (warehouseId != null) params['warehouse_id'] = warehouseId;
      final response = await _apiClient.dio.get(
        ApiConstants.purchaseOrders,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب أوامر الشراء: $e');
    }
  }

  Future<Map<String, dynamic>> getPurchaseOrderById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.purchaseOrderById(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل جلب أمر الشراء: $e');
    }
  }

  Future<Map<String, dynamic>> createPurchaseOrder({
    required String supplierId,
    required String warehouseId,
    required List<Map<String, dynamic>> items,
    String? expectedDate,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.purchaseOrders,
        data: {
          'supplier_id': supplierId,
          'warehouse_id': warehouseId,
          'items': items,
          'expected_date': ?expectedDate,
          'notes': ?notes,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل إنشاء أمر الشراء: $e');
    }
  }

  Future<Map<String, dynamic>> confirmPurchaseOrder(String id) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.confirmPurchaseOrder(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل تأكيد أمر الشراء: $e');
    }
  }

  Future<Map<String, dynamic>> receivePurchaseOrder(
    String id, {
    required List<Map<String, dynamic>> items,
    String? invoiceNumber,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.receivePurchaseOrder(id),
        data: {
          'items': items,
          'invoice_number': ?invoiceNumber,
          'notes': ?notes,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل استلام البضاعة: $e');
    }
  }

  Future<void> cancelPurchaseOrder(String id, {String? reason}) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.cancelPurchaseOrder(id),
        data: {'reason': ?reason},
      );
    } catch (e) {
      throw Exception('فشل إلغاء أمر الشراء: $e');
    }
  }
}
