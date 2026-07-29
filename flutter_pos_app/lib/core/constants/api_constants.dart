class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3001/api';
  static const String socketUrl = 'http://10.0.2.2:3001';

  // Auth
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';

  // Menu / Catalog
  static const String categories = '/categories';
  static const String menuItems = '/menu';

  // Orders & Sales
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String payOrder(String id) => '/orders/$id/pay';
  static String completeOrder(String id) => '/orders/$id/complete';

  // Tables
  static const String tables = '/tables';
  static String tableById(String id) => '/tables/$id';
  static String transferTable(String id) => '/tables/$id/transfer';
  static String clearTable(String id) => '/tables/$id/clear';

  // Shifts
  static const String currentShift = '/shifts/current';
  static const String openShift = '/shifts/start';
  static const String closeShift = '/shifts/end';
  static const String resumeOrOpenShift = '/shifts/resume-or-open';
  static const String shifts = '/shifts';

  // Warehouses
  static const String warehouses = '/warehouses';
  static String warehouseById(String id) => '/warehouses/$id';

  // Inventory / Stock
  static const String inventoryStock = '/inventory/stock';
  static const String inventoryAlerts = '/inventory/alerts';
  static const String inventoryMovements = '/inventory/movements';
  static const String inventoryProducts = '/inventory/products';
  static const String inventoryAdjust = '/inventory/adjust';
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryAssemble = '/inventory/assemble';
  static const String inventoryQuickProduct = '/inventory/quick-product';
  static String stockByMenuId(String menuId) => '/inventory/stock/$menuId';
  static String stockSettings(String menuId) => '/inventory/stock/$menuId/settings';

  // Purchases (Direct Receipts)
  static const String purchases = '/purchases';
  static String purchaseById(String id) => '/purchases/$id';

  // Purchase Orders
  static const String purchaseOrders = '/purchase-orders';
  static String purchaseOrderById(String id) => '/purchase-orders/$id';
  static String confirmPurchaseOrder(String id) => '/purchase-orders/$id/confirm';
  static String receivePurchaseOrder(String id) => '/purchase-orders/$id/receive';
  static String cancelPurchaseOrder(String id) => '/purchase-orders/$id/cancel';

  // Suppliers
  static const String suppliers = '/suppliers';
  static String supplierById(String id) => '/suppliers/$id';
  static String supplierPayments(String id) => '/suppliers/$id/payments';
  static String supplierStatement(String id) => '/suppliers/$id/statement';

  // System Settings
  static const String settings = '/settings';
  static String supplierGlBalance(String id) => '/suppliers/$id/gl-balance';

  // Customers
  static const String customers = '/customers';
  static String customerById(String id) => '/customers/$id';

  // Stock Transfers
  static const String transfers = '/transfers';
  static String transferById(String id) => '/transfers/$id';
  static String confirmTransfer(String id) => '/transfers/$id/confirm';
  static String cancelTransfer(String id) => '/transfers/$id/cancel';

  // Stock Issues (صرف بضاعة)
  static const String stockIssues = '/stock-issues';
  static String stockIssueById(String id) => '/stock-issues/$id';
  static String approveStockIssue(String id) => '/stock-issues/$id/approve';
  static String executeStockIssue(String id) => '/stock-issues/$id/issue';
  static String cancelStockIssue(String id) => '/stock-issues/$id/cancel';

  // Reports
  static const String reportsDaily = '/reports/daily';
  static const String reportsRange = '/reports/range';
  static const String reportsBestSellers = '/reports/best-sellers';
  static const String reportsStaffPerformance = '/reports/staff-performance';
  static const String reportsReconciliationDaily = '/reports/reconciliation/daily';

  // Refunds
  static const String refunds = '/refunds';
  static String refundById(String id) => '/refunds/$id';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationReadAll = '/notifications/read-all';
  static const String notificationCleanup = '/notifications/cleanup';
}
