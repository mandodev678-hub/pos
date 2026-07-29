import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardStatsModel> fetchDashboardData() async {
    try {
      final results = await Future.wait([
        _apiClient.dio.get(ApiConstants.reportsDaily),
        _apiClient.dio.get(ApiConstants.inventoryAlerts),
        _apiClient.dio.get(ApiConstants.orders, queryParameters: {
          'status': 'active',
          'limit': 100,
        }),
      ]);

      List safeList(dynamic input) {
        if (input is List) return input;
        if (input is Map) {
          if (input.containsKey('data') && input['data'] is List) return input['data'] as List;
          if (input.containsKey('alerts') && input['alerts'] is List) return input['alerts'] as List;
          if (input.containsKey('orders') && input['orders'] is List) return input['orders'] as List;
          if (input.containsKey('items') && input['items'] is List) return input['items'] as List;
          if (input.containsKey('lowStock') && input['lowStock'] is List) return input['lowStock'] as List;
          if (input.containsKey('outOfStock') && input['outOfStock'] is List) {
            return [
              ...(input['lowStock'] is List ? input['lowStock'] as List : []),
              ...input['outOfStock'] as List,
            ];
          }
        }
        return [];
      }

      final dailyMap = results[0].data is Map ? results[0].data : {};
      final dailyData = dailyMap['data'] is Map ? dailyMap['data'] : dailyMap;
      final alertsData = safeList(results[1].data);
      final ordersData = safeList(results[2].data);

      final summary = dailyData['summary'] is Map ? dailyData['summary'] : {};
      final topItems = safeList(dailyData['topItems']);
      final hourly = safeList(dailyData['hourlyBreakdown']);
      final allOrders = safeList(dailyData['orders']);

      int activeCount = 0;
      activeCount = ordersData.where((o) {
        if (o is! Map) return false;
        final s = (o['status'] ?? '').toString();
        return ['pending', 'confirmed', 'preparing', 'ready'].contains(s);
      }).length;

      final parsedSummary = DailySummary.fromJson(summary, activeCount: activeCount);
      final parsedTopItems = topItems.map((e) => TopItem.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      final parsedHourly = hourly.map((e) => HourlyData.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      final parsedRecentOrders = allOrders.take(5).map((e) => RecentOrder.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      final parsedAlerts = alertsData.map((e) => StockAlert.fromJson(e is Map<String, dynamic> ? e : {})).toList();

      final financial = FinancialSummary(
        totalPayments: parsedSummary.totalSales,
        totalExpenses: 0,
        todayExpenses: 0,
        totalCredit: parsedSummary.totalSales - parsedSummary.cashSales - parsedSummary.cardSales - parsedSummary.onlineSales,
        totalRefunds: parsedSummary.refundAmount,
      );

      return DashboardStatsModel(
        summary: parsedSummary,
        hourlyBreakdown: parsedHourly,
        topItems: parsedTopItems,
        recentOrders: parsedRecentOrders,
        stockAlerts: parsedAlerts,
        financial: financial,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل جلب بيانات لوحة التحكم: $e');
    }
  }

  Future<String?> fetchStoreName() async {
    try {
      final response = await _apiClient.dio.get('/settings/public');
      return response.data['data']?['storeName'];
    } catch (_) {
      return null;
    }
  }
}
