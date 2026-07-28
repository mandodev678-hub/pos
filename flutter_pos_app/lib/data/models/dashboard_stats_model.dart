class DashboardStatsModel {
  final DailySummary summary;
  final List<HourlyData> hourlyBreakdown;
  final List<TopItem> topItems;
  final List<RecentOrder> recentOrders;
  final List<StockAlert> stockAlerts;
  final FinancialSummary financial;
  final String? storeName;
  final DateTime lastUpdated;

  DashboardStatsModel({
    required this.summary,
    required this.hourlyBreakdown,
    required this.topItems,
    required this.recentOrders,
    required this.stockAlerts,
    required this.financial,
    this.storeName,
    required this.lastUpdated,
  });

  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      summary: DailySummary.empty(),
      hourlyBreakdown: [],
      topItems: [],
      recentOrders: [],
      stockAlerts: [],
      financial: FinancialSummary.empty(),
      lastUpdated: DateTime.now(),
    );
  }
}

class DailySummary {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSales;
  final double totalTax;
  final double netSales;
  final double cashSales;
  final double cardSales;
  final double onlineSales;
  final double averageOrderValue;
  final double refundAmount;
  final int refundCount;
  final double netRevenue;

  DailySummary({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.totalTax,
    required this.netSales,
    required this.cashSales,
    required this.cardSales,
    required this.onlineSales,
    required this.averageOrderValue,
    required this.refundAmount,
    required this.refundCount,
    required this.netRevenue,
  });

  factory DailySummary.empty() {
    return DailySummary(
      totalOrders: 0,
      activeOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      totalSales: 0,
      totalTax: 0,
      netSales: 0,
      cashSales: 0,
      cardSales: 0,
      onlineSales: 0,
      averageOrderValue: 0,
      refundAmount: 0,
      refundCount: 0,
      netRevenue: 0,
    );
  }

  factory DailySummary.fromJson(Map<String, dynamic> json, {int activeCount = 0}) {
    return DailySummary(
      totalOrders: _parseInt(json['totalOrders'] ?? json['total_orders']),
      activeOrders: activeCount,
      completedOrders: _parseInt(json['totalOrders'] ?? json['total_orders']),
      cancelledOrders: _parseInt(json['cancelledOrders'] ?? json['cancelled_orders']),
      totalSales: _parseDouble(json['totalSales'] ?? json['total_sales']),
      totalTax: _parseDouble(json['totalTax'] ?? json['total_tax']),
      netSales: _parseDouble(json['netSales'] ?? json['net_sales']),
      cashSales: _parseDouble(json['cashSales'] ?? json['cash_sales']),
      cardSales: _parseDouble(json['cardSales'] ?? json['card_sales']),
      onlineSales: _parseDouble(json['onlineSales'] ?? json['online_sales']),
      averageOrderValue: _parseDouble(json['averageOrderValue'] ?? json['average_order_value']),
      refundAmount: _parseDouble(json['refundAmount'] ?? json['refund_amount']),
      refundCount: _parseInt(json['refundCount'] ?? json['refund_count']),
      netRevenue: _parseDouble(json['netRevenue'] ?? json['net_revenue']),
    );
  }

  static int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static double _parseDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

class HourlyData {
  final int hour;
  final int orders;
  final double revenue;

  HourlyData({required this.hour, required this.orders, required this.revenue});

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'] ?? 0,
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class TopItem {
  final String name;
  final int quantity;
  final double revenue;

  TopItem({required this.name, required this.quantity, required this.revenue});

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class RecentOrder {
  final String id;
  final String orderNumber;
  final double total;
  final String paymentMethod;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;
  final String? customerName;

  RecentOrder({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.paymentStatus,
    this.createdAt,
    this.customerName,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id'].toString(),
      orderNumber: json['order_number']?.toString() ?? json['id'].toString(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      customerName: json['customer_name'] ?? json['Customer']?['name'],
    );
  }

  String get paymentStatusAr {
    switch (paymentStatus) {
      case 'paid': return 'مدفوع';
      case 'pending': return 'معلق';
      case 'refunded': return 'مسترجع';
      case 'partially_refunded': return 'مسترجع جزئياً';
      default: return paymentStatus;
    }
  }

  String get paymentMethodAr {
    switch (paymentMethod) {
      case 'cash': return 'نقدي';
      case 'card': return 'بطاقة';
      case 'online': return 'إلكتروني';
      case 'credit': return 'آجل';
      default: return paymentMethod;
    }
  }

  String get statusAr {
    switch (status) {
      case 'pending': return 'معلق';
      case 'confirmed': return 'مؤكد';
      case 'preparing': return 'يُحضّر';
      case 'ready': return 'جاهز';
      case 'delivered': return 'مسلّم';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

class StockAlert {
  final String name;
  final double currentStock;
  final double minStock;
  final String unit;

  StockAlert({required this.name, required this.currentStock, required this.minStock, required this.unit});

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      name: json['name'] ?? json['item_name'] ?? '',
      currentStock: (json['current_stock'] ?? json['quantity'] ?? 0).toDouble(),
      minStock: (json['min_stock'] ?? json['minLevel'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'قطعة',
    );
  }
}

class FinancialSummary {
  final double totalPayments;
  final double totalExpenses;
  final double todayExpenses;
  final double totalCredit;
  final double totalRefunds;

  FinancialSummary({
    required this.totalPayments,
    required this.totalExpenses,
    required this.todayExpenses,
    required this.totalCredit,
    required this.totalRefunds,
  });

  factory FinancialSummary.empty() {
    return FinancialSummary(
      totalPayments: 0,
      totalExpenses: 0,
      todayExpenses: 0,
      totalCredit: 0,
      totalRefunds: 0,
    );
  }

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalPayments: (json['total_payments'] ?? json['totalPayments'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? json['totalExpenses'] ?? 0).toDouble(),
      todayExpenses: (json['today_expenses'] ?? json['todayExpenses'] ?? 0).toDouble(),
      totalCredit: (json['total_credit'] ?? json['totalCredit'] ?? 0).toDouble(),
      totalRefunds: (json['total_refunds'] ?? json['totalRefunds'] ?? 0).toDouble(),
    );
  }
}
