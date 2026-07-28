# مهندس النظام — برومت شامل للمشروع

> **المشروع**: نظام إدارة مطعم متكامل (Restaurant Management System)
> **الاسم**: زمام POS
> **الحالة**: قيد التطوير النشط — وظائف أساسية مكتملة، تطوير واجهات الموبايل مستمر

---

## 1. ملخص المشروع

نظام متكامل لإدارة المطاعم يتكون من 6 تطبيقات:

| التطبيق | التقنية | البورت | الوصف |
|---------|---------|--------|-------|
| **Backend** | Node.js + Express + Sequelize | `3001` | API رئيسي + Socket.io |
| **Website** | React PWA | `3000` | طلب أونلاين للعملاء |
| **POS Terminal** | React + Redux + MUI | `3002` | شاشة الكاشير للويب |
| **KDS** | React | `3003` | شاشة المطبخ |
| **Flutter POS** | Flutter + Provider | — | تطبيق الموبايل/Tablet للكاشير والمدير |
| **Flutter Rider** | Flutter + BLoC | — | تطبيق الموبايل لكابتن التوصيل |

**تشغيل النظام**: `node start-all.js` يشغّل الـ Backend على 3001 + الواجهات الثلاثة على 3000/3002/3003 مع Proxy.

---

## 2. بنية Backend

### التقنيات
- **Runtime**: Node.js + Express 4.18
- **Database**: MySQL 8 (إنتاج) / SQLite (تطوير) عبر Sequelize 6
- **Real-time**: Socket.io
- **Auth**: JWT + bcryptjs + RBAC (قائمة صلاحيات)
- **المدفوعات**: Stripe, Paymob, Moyasar, Fawry
- **الفاتورة الضريبية**: ZATCA Phase 1 (QR Code TLV + Base64)
- **التوثيق**: Swagger

### المجلدات الرئيسية
```
backend/
├── src/
│   ├── routes/          # 35 ملف route (API endpoints)
│   ├── models/          # 67 ملف model (Sequelize)
│   ├── services/        # 21 خدمة (business logic)
│   ├── middleware/       # auth, validation, rate limiting, idempotency
│   ├── config/          # database.js, permissions.js, swagger.js
│   ├── socket/          # Socket.io event handlers
│   ├── validators/      # Input validators
│   ├── migrations/      # SQL + JS migrations
│   ├── scripts/         # 60+ operational scripts
│   └── utils/           # barcode, sku, menuOptions
├── data/                # tables.json, settings.json
└── package.json
```

### Routes الرئيسية (35 ملف)

| Route | Prefix | الوصف |
|-------|--------|-------|
| `auth.js` | `/api/auth` | تسجيل دخول/خروج، تحديث Token |
| `order.js` | `/api/orders` | دورة حياة الطلب كاملة |
| `payment.js` | `/api/payments` | معالجة الدفع مع Webhook |
| `menu.js` | `/api/menu` | إدارة قائمة الوجبات (CRUD) |
| `category.js` | `/api/categories` | إدارة الأقسام |
| `customer.js` | `/api/customers` | إدارة العملاء |
| `inventory.js` | `/api/inventory` | المخزون والمستودعات |
| `shifts.js` | `/api/shifts` | إدارة الورديات |
| `reports.js` | `/api/reports` | التقارير اليومية/المالية |
| `tables.js` | `/api/tables` | إدارة الطاولات |
| `purchases.js` | `/api/purchases` | فواتير الشراء |
| `purchaseOrders.js` | `/api/purchase-orders` | أوامر الشراء |
| `suppliers.js` | `/api/suppliers` | الموردين |
| `delivery.js` | `/api/delivery` | التوصيل و Riders |
| `refunds.js` | `/api/refunds` | الاسترداد |
| `accounting.js` | `/api/accounting` | المحاسبة المزدوجة |
| `hr.js` | `/api/hr` | الموارد البشرية |
| `settings.js` | `/api/settings` | إعدادات النظام |
| + 17 routes أخرى | | branches, warehouses, transfers, stockIssues, etc. |

### Models الرئيسية (67 ملف)

| الفئة | Models |
|-------|--------|
| **الأعمال** | `Order`, `OrderItem`, `OrderPayment`, `Customer`, `Menu`, `MenuIngredient`, `Category`, `Shift` |
| **المستخدمين** | `User`, `RefreshToken`, `Branch` |
| **المخزون** | `Stock`, `StockMovement`, `StockAdjustment`, `Warehouse`, `StockTransfer`, `StockIssue` |
| **المشتريات** | `Supplier`, `PurchaseOrder`, `PurchaseReceipt`, `SupplierPayment`, `PurchaseReturn` |
| **المحاسبة** | `Account`, `JournalEntry`, `JournalLine`, `FiscalPeriod`, `Company` |
| **التسعير** | `PriceList`, `PromotionRule`, `Coupon`, `LoyaltyLedger` |
| **الHR** | `Employee`, `Department`, `HRAttendance`, `LeaveRequest`, `PerformanceReview` |
| **البنية** | `IdempotencyKey`, `AuditLog`, `Notification`, `Device`, `PrintTemplate` |

### Services (21 خدمة)

| الخدمة | الوظيفة |
|--------|---------|
| `accountingService.js` | القيود المزدوجة، ميزان المراجعة، قائمة الدخل |
| `accountingHooks.js` | توليد قيود تلقائية من الأحداث التجارية |
| `orderFinalizationService.js` | إتمام الطلب: خصم المخزون + قيد محاسبي |
| `stockService.js` | FIFO خصم المخزون، التحويلات، الصرف |
| `pricingService.js` | قوائم الأسعار، الكوبونات، الولاء |
| `printService.js` | طباعة إيصالات حرارية ESC/POS |
| `shiftService.js` | ترحيل الورديات والمطابقة |
| `orderPaymentService.js` | تسجيل المدفوعات والدفع المقسم |
| + 13 خدمات أخرى | |

### Middleware

| الملف | الوظيفة |
|-------|---------|
| `auth.js` | JWT + RBAC + Permissions |
| `validate.js` | Express Validator |
| `rateLimiter.js` | تحديد المعدل |
| `idempotency.js` | حماية التكرار |
| `discountControl.js` | التحكم بالخصومات |
| `maintenance.js` | وضع الصيانة |
| `activityAudit.js` | تدقيق الأنشطة |

### Environment Variables
```env
PORT=3001
DB_DIALECT=sqlite
DB_STORAGE=./data/restaurant.db
JWT_SECRET=zamam-secret-key
JWT_REFRESH_SECRET=zamam-refresh-secret
CORS_ORIGIN=*
```

---

## 3. تطبيق Flutter POS (`flutter_pos_app`)

### التقنيات
- **SDK**: Dart 3.12.2+ / Flutter 3.44.8
- **State Management**: Provider
- **HTTP**: Dio (عبر `ApiClient`)
- **Real-time**: socket_io_client
- **Charts**: fl_chart
- **Fonts**: google_fonts (Cairo)
- **Storage**: flutter_secure_storage
- **QR**: qr_flutter (ZATCA)

### pubspec.yaml
```yaml
dependencies:
  dio: ^5.8.0+1
  provider: ^6.1.2
  google_fonts: ^6.2.1
  flutter_secure_storage: ^9.2.4
  intl: ^0.20.2
  qr_flutter: ^4.1.0
  socket_io_client: ^2.0.3+1
  fl_chart: ^1.2.0  # أُضيف لاحقاً
```

### بنية المجلدات
```
lib/
├── main.dart                          # نقطة الدخول
├── core/
│   ├── constants/api_constants.dart   # ثوابت API endpoints
│   ├── network/
│   │   ├── api_client.dart            # Dio wrapper مع JWT refresh
│   │   └── socket_client.dart         # Socket.io client (مفرد)
│   └── utils/
│       └── zatca_qr.dart             # TLV + Base64 للفاتورة الضريبية
├── data/
│   ├── models/                        # 13 model
│   │   ├── user_model.dart
│   │   ├── order_model.dart
│   │   ├── product_model.dart
│   │   ├── category_model.dart
│   │   ├── cart_item_model.dart
│   │   ├── shift_model.dart
│   │   ├── table_model.dart
│   │   ├── customer_model.dart
│   │   ├── stock_item_model.dart
│   │   ├── warehouse_model.dart
│   │   ├── purchase_model.dart
│   │   ├── supplier_model.dart
│   │   └── dashboard_stats_model.dart  # Dashboard
│   └── repositories/                  # 12 repository
│       ├── auth_repository.dart
│       ├── pos_repository.dart
│       ├── orders_repository.dart
│       ├── customers_repository.dart
│       ├── inventory_repository.dart
│       ├── purchases_repository.dart
│       ├── settings_repository.dart
│       ├── shift_repository.dart
│       ├── table_repository.dart
│       ├── transfers_repository.dart
│       └── dashboard_repository.dart   # Dashboard
└── presentation/
    ├── providers/                     # 3 provider
    │   ├── cart_provider.dart
    │   ├── shift_provider.dart
    │   └── kds_provider.dart
    └── screens/                       # 12 شاشة
        ├── login_screen.dart
        ├── home_shell.dart             # الحاوية الرئيسية مع Bottom Nav + Drawer
        ├── dashboard_screen.dart       # لوحة التحكم ⭐
        ├── pos_main_screen.dart
        ├── checkout_modal.dart
        ├── tables_screen.dart
        ├── inventory_screen.dart
        ├── purchases_screen.dart
        ├── customers_screen.dart
        ├── reports_screen.dart
        ├── settings_screen.dart
        └── shift_screen.dart
```

### الشاشات والتنقل

**HomeShell** هو الحاوية الرئيسية:
- **Bottom NavigationBar** مع 6 تبويبات:
  - Index 0: الرئيسية (DashboardScreen)
  - Index 1: الكاشير (PosMainScreen)
  - Index 2: التقارير (ReportsScreen)
  - Index 3: المخزون (InventoryScreen)
  - Index 4: المشتريات (PurchasesScreen)
  - Index 5: العملاء (CustomersScreen)
- **Drawer**侧边栏 مع شجرة تنقل لكل الأقسام
- **Settings** (Index 6) يظهر فقط من Drawer (بدون Bottom Nav)

### أنماط الكود المهمة

#### 1. استدعاءات API
```dart
// استخدام _apiClient.dio (وليس Dio مباشرة)
final _apiClient = ApiClient();
final response = await _apiClient.dio.get(ApiConstants.reportsDaily);
```

#### 2. Socket.io
```dart
// SocketClient مفرد (Singleton)
final socket = SocketClient();
socket.initSocket(branchId: ..., role: ...);
socket.onOrderUpdated = (data) { ... };
```

#### 3. النماذج (Models)
```dart
// كل model يحتوي on fromJson factory
// يدعم snake_case و camelCase
// النصوص بالعربية دائماً
```

#### 4. RTL + Cairo Font
```dart
// كل شاشة تبدأ بـ:
Directionality(
  textDirection: TextDirection.rtl,
  child: Scaffold(...)
)

// النصوص بخط Cairo:
Text('...', style: GoogleFonts.cairo(...))

// ⚠️ تحذير مهم: intl package يعرّف TextDirection خاص به
// يجب إخفاؤه: import 'package:intl/intl.dart' hide TextDirection;
```

#### 5. الألوان
```dart
class AppColors {
  static const primary = Color(0xFF1A237E);     // نيلي غامق
  static const primaryDark = Color(0xFF0D1642);
  static const secondary = Color(0xFF2E7D32);   // أخضر
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFEF6C00);     // برتقالي
  static const background = Color(0xFFF5F6FA);  // رمادي فاتح
  static const textPrimary = Color(0xFF212121);
}
```

### Backend API Endpoints المطلوبة للـ Dashboard

```javascript
// 1. التقرير اليومي
GET /api/reports/daily?date=2026-07-28
// Response:
{
  data: {
    date: "2026-07-28",
    summary: {
      totalOrders: 45,
      cancelledOrders: 2,
      totalSales: "1250.00",
      totalTax: "187.50",
      netSales: "1062.50",
      cashSales: "800.00",
      cardSales: "300.00",
      onlineSales: "150.00",
      totalReceipts: "1250.00",
      cancelledAmount: "50.00",
      refundCount: 1,
      refundAmount: "25.00",
      netRevenue: "1225.00",
      averageOrderValue: "27.78"
    },
    topItems: [
      { name: "شاورما دجاج", quantity: 15, revenue: 120.00 }
    ],
    hourlyBreakdown: [
      { hour: 12, orders: 8, revenue: 240.00 }
    ],
    orders: [
      { id: 1, order_number: "ORD-1001", total: 45.00, payment_method: "cash", status: "completed", created_at: "..." }
    ]
  }
}

// 2. تنبيهات المخزون
GET /api/inventory/alerts
// Response: { data: [{ name: "...", current_stock: 2, min_stock: 5, unit: "kg" }] }

// 3. الطلبات النشطة
GET /api/orders?status=active&limit=100

// 4. الإعدادات العامة
GET /api/settings/public
// Response: { data: { storeName: "مطعم زمام", taxRate: 15, ... } }
```

---

## 4. تطبيق Flutter Rider (`flutter_rider_app`)

### التقنيات
- **State Management**: flutter_bloc (مختلف عن POS)
- **GPS**: geolocator
- **URL**: url_launcher

### الشاشات (4 شاشات)
- `LoginScreen` — تسجيل دخول الكابتن
- `HomeScreen` — لوحة التحكم + قائمة التوصيلات النشطة
- `OrderDetailsScreen` — تفاصيل الطلب + تحديث الحالة + فتح الخريطة
- `SettlementScreen` — تسوية نهاية اليوم (نقدي/بطاقة)

---

## 5. الواجهات الويب

### POS Terminal (`pos/`) — React + Redux + MUI
- **48 صفحة** (Login, Dashboard, NewOrder, Orders, Menu, Inventory, Reports, Accounting, HR, etc.)
- **State**: Redux Toolkit (auth, cart, menu, order, shift slices)
- **API**: `pos/src/services/api.js` — Axios client
- **Socket**: `pos/src/services/socket.js`
- **RTL**: `stylis-plugin-rtl` + Arabic locale `pos/src/locales/ar.json`

### Website (`website/`) — React PWA
- 4 صفحات: Home, Checkout, TrackOrder, PaymentCallback
- Cart drawer, Product details modal

### KDS (`kds/`) — React
- `App.jsx` — عرض الطلبات مع مؤقتات وتنبيهات صوتية
- Dark theme optimized للمطبخ

---

## 6. الإعدادات المشتركة

### `start-all.js` — سكربت التشغيل
```javascript
// يشغّل 4خدمات في عملية واحدة:
// 1. Backend (port 3001) — require('./backend/src/server.js')
// 2. POS (port 3002) — serve pos/dist + proxy /api → 3001
// 3. Website (port 3000) — serve website/dist + proxy /api → 3001
// 4. KDS (port 3003) — serve kds/dist + proxy /api → 3001
```

### `ecosystem.config.js` — PM2 Production
### `docker-compose.yml` — MySQL + Backend + POS + Website + KDS + Nginx

---

## 7. ما تم إنجازه حاليًا

### ✅ مكتمل
- **Backend**: 35 route + 67 model + 21 service — متكامل وشغّال
- **Web Dashboard** (React): 1494 سطر — ميزات كاملة
- **POS Terminal Web**: 48 صفحة — متكامل
- **KDS**: يعمل مع dark theme + timers + audio
- **Website**: PWA للطلب أونلاين
- **Flutter POS — الكاشير**: شاشة الطلب + السلة + الدفع + ZATCA QR
- **Flutter POS — التوصيل**: `order:assigned` socket event
- **Flutter POS — التسوية**: `delivery/my-stats` + settlement_screen.dart
- **Flutter POS — KDS Integration**: SocketClient + KdsProvider + Badge + SnackBar
- **Flutter POS — الطابعة الحرارية**: ESC/POS printService.js + checkout_modal.dart
- **Flutter POS — Dashboard Screen**: ✅ مكتمل (dashboard_stats_model + dashboard_repository + dashboard_screen)
- **Flutter Rider**: 4 شاشات مكتملة
- **إصلاحات tables.js**: إضافة Customer include مع `attributes: ['name']`
- **fl_chart**: أُضيف إلى pubspec.yaml واستُخدم في Dashboard

### ⚠️ ملاحظات تقنية مهمة
1. **intl TextDirection conflict**: `import 'package:intl/intl.dart' hide TextDirection;` — إلزامي
2. **ApiClient**: استخدام `_apiClient.dio` وليس `Dio()` مباشرة
3. **SocketClient**: مفرد (Singleton) — `SocketClient()`
4. **AppColors**: معرّف في `main.dart`
5. **flutter_lints v6**: يكتشف أخطاء صارمة — يجب تشغيل `flutter analyze` دائماً
6. **Dart 3.12.2**: يدعم wildcard `_` في closures — `(_, _)` بدلاً من `(_, __)`
7. **`withOpacity` deprecated**: استخدام `withValues(alpha: ...)` بدلاً منه

---

## 8. بنية ملفات Dashboard المُنجزة

### `lib/data/models/dashboard_stats_model.dart` (262 سطر)
- `DashboardStatsModel` — النموذج الرئيسي
- `DailySummary` — ملخص المبيعات (14 حقل)
- `HourlyData` — بيانات الساعة
- `TopItem` — صنف مباع
- `RecentOrder` — طلب أخير مع labels عربية
- `StockAlert` — تنبيه مخزون
- `FinancialSummary` — ملخص مالي (5 حقول)

### `lib/data/repositories/dashboard_repository.dart` (81 سطر)
- `fetchDashboardData()` — Future.wait مع 3 endpoints بالتوازي
- `fetchStoreName()` — جلب اسم المتجر
- `safeList()` — دالة مساعدة للتعامل مع الاستجابات المختلفة

### `lib/presentation/screens/dashboard_screen.dart` (1010 سطر)
- **Header**: gradient + مرحباً + اسم + آخر تحديث + زر Drawer
- **Stock Alert Banner**: برتقالي + قائمة + زر انتقال
- **Quick Actions**: 8 أزرار (Grid 4×2)
- **Sales KPIs**: 4 بطاقات (إجمالي، نشطة، مكتملة، إيراد)
- **Financial KPIs**: 4 بطاقات (مدفوعات، مصروفات، مصروفات اليوم، آجلة)
- **Hourly Chart**: fl_chart LineChart + area gradient + dot peak + tooltips
- **Top 5 Items**: مرتبة 1-5 + LinearProgressIndicator + ألوان
- **Recent Orders**: آخر 5 + حالة الدفع + لون الحالة
- **Drawer**: قائمة متنقلة كاملة

### `home_shell.dart` — التعديلات
- أُضيف Dashboard كـ Index 0
- All other screens shifted +1
- Bottom nav: 6 destinations
- Drawer: Dashboard item أُضيف في الأعلى

---

## 9. أوامر مهمة

```bash
# تشغيل Backend فقط
cd backend && npm run dev

# تشغيل النظام الكامل
node start-all.js

# بناء Flutter POS
cd flutter_pos_app && flutter build apk --debug

# تحليل Dart
cd flutter_pos_app && flutter analyze

# بناء Flutter Rider
cd flutter_rider_app && flutter build apk --debug

# تشغيل على emulator
flutter emulators --launch Pixel_6
flutter run

# تثبيت APK على emulator
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk

# بناء الواجهات الويب
cd pos && npm run build
cd website && npm run build
cd kds && npm run build
```

---

## 10. بنية API للمشروع

### الألوان والثوابت (main.dart)
```dart
class AppColors {
  static const primary = Color(0xFF1A237E);
  static const primaryDark = Color(0xFF0D1642);
  static const secondary = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFEF6C00);
  static const background = Color(0xFFF5F6FA);
  static const textPrimary = Color(0xFF212121);
}
```

### ApiConstants (api_constants.dart)
```dart
class ApiConstants {
  static const baseUrl = 'http://10.0.2.2:3001/api';  // Android emulator
  static const socketUrl = 'http://10.0.2.2:3001';
  // ... 60+ endpoint constants
}
```

### Permissions (backend/src/config/permissions.js)
```javascript
const PERMISSIONS = {
  ORDERS_VIEW: 'orders:view',
  ORDERS_CREATE: 'orders:create',
  ORDERS_CANCEL: 'orders:cancel',
  REPORTS_VIEW: 'reports:view',
  INVENTORY_VIEW: 'inventory:view',
  INVENTORY_MANAGE: 'inventory:manage',
  // ... 40+ permissions
}
```

### Roles
`admin`, `manager`, `cashier`, `chef`, `supervisor`, `rider`, `accountant`, `hr_manager`

---

## 11. تعليمات للأเจنت التالي

### عند إضافة شاشة جديدة في Flutter POS:
1. أنشئ Model في `lib/data/models/`
2. أنشئ Repository في `lib/data/repositories/`
3. أنشئ Screen في `lib/presentation/screens/`
4. أضف import في `home_shell.dart`
5. أضف route في Drawer + Bottom Nav (إذا كان رئيسي)
6. شغّل `flutter analyze` و `flutter build apk --debug`

### عند إضافة endpoint جديد في Backend:
1. أنشئ Route في `backend/src/routes/`
2. أنشئ Model في `backend/src/models/`
3. سجّل الـ route في `backend/src/server.js`
4. أضيف الـ endpoint في `api_constants.dart`
5. أضيف Socket event إذا كان هناك real-time update

### قواعد الكود المهمة:
- **RTL دائماً**: `Directionality(textDirection: TextDirection.rtl, ...)`
- **خط Cairo**: `GoogleFonts.cairo(...)` لكل النصوص
- **العربية**: كل النصوص والتصنيفات بالعربية
- **`flutter analyze`**: يجب أن يُرجع `No issues found` قبل البناء
- **`withOpacity` ممنوع**: استخدام `withValues(alpha: ...)` بدلاً
- **intl**: `import 'package:intl/intl.dart' hide TextDirection;`
- **Provider**: استخدام `context.watch<T>()` و `context.read<T>()`
- **API Error Handling**: try/catch مع `throw Exception('رسالة')`

### بيانات تجريبية افتراضية:
- **Login**: `admin` / `admin123`
- **Port Backend**: 3001
- **Emulator URL**: `http://10.0.2.2:3001/api`
- **Device URL**: `http://<device-ip>:3001/api`

---

## 12. مرجع سريع لملفات مهمة

| الملف | المسار |
|-------|--------|
| API Client | `flutter_pos_app/lib/core/network/api_client.dart` |
| Socket Client | `flutter_pos_app/lib/core/network/socket_client.dart` |
| API Constants | `flutter_pos_app/lib/core/constants/api_constants.dart` |
| App Colors | `flutter_pos_app/lib/main.dart` |
| Home Shell | `flutter_pos_app/lib/presentation/screens/home_shell.dart` |
| Dashboard Screen | `flutter_pos_app/lib/presentation/screens/dashboard_screen.dart` |
| Dashboard Model | `flutter_pos_app/lib/data/models/dashboard_stats_model.dart` |
| Dashboard Repository | `flutter_pos_app/lib/data/repositories/dashboard_repository.dart` |
| Backend Reports | `backend/src/routes/reports.js` |
| Backend Inventory | `backend/src/routes/inventory.js` |
| Backend Settings | `backend/src/routes/settings.js` |
| Web Dashboard (مرجع) | `pos/src/pages/Dashboard.jsx` |
| Backend Models Index | `backend/src/models/index.js` |
| Backend Server Entry | `backend/src/server.js` |
| Start All | `start-all.js` |
| Rider App Entry | `flutter_rider_app/lib/main.dart` |
| Delivery Repository | `flutter_rider_app/lib/data/repositories/delivery_repository.dart` |
