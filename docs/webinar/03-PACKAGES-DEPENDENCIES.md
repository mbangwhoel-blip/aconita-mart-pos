# Packages & Dependencies

## Daftar Isi
1. [Overview Dependencies](#overview-dependencies)
2. [Core Dependencies](#core-dependencies)
3. [State Management](#state-management)
4. [Database & Storage](#database--storage)
5. [Networking & Connectivity](#networking--connectivity)
6. [UI & Theming](#ui--theming)
7. [Utilities](#utilities)
8. [Printing & Export](#printing--export)
9. [Dev Dependencies](#dev-dependencies)

---

## Overview Dependencies

```yaml
# pubspec.yaml

environment:
  sdk: ^3.10.1

dependencies:
  # Supabase (Backend)
  supabase_flutter: ^2.8.4

  # Connectivity
  connectivity_plus: ^6.1.4

  # Environment
  flutter_dotenv: ^5.2.1

  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.8

  # Local Database
  sqflite: ^2.4.2
  path: ^1.9.1
  shared_preferences: ^2.5.4

  # UI & Charts
  fl_chart: ^1.1.1
  google_fonts: ^7.0.2

  # Utilities
  intl: ^0.20.2
  crypto: ^3.0.6
  uuid: ^4.5.2
  path_provider: ^2.1.5
  permission_handler: ^12.0.1
  url_launcher: ^6.3.2

  # Printing & Export
  print_bluetooth_thermal: ^1.1.9
  esc_pos_utils_plus: ^2.0.3
  excel: ^4.0.6
  share_plus: ^12.0.1
```

---

## Core Dependencies

### 1. Flutter SDK
```yaml
flutter:
  sdk: flutter
```
Framework utama untuk membangun UI cross-platform.

### 2. Cupertino Icons
```yaml
cupertino_icons: ^1.0.8
```
Icon set iOS-style dari Apple untuk Material dan Cupertino widgets.

---

## State Management

### 1. flutter_bloc
```yaml
flutter_bloc: ^9.1.1
```

**Fungsi:** State management pattern yang predictable dan testable.

**Penggunaan di project:**
```dart
// Cubit untuk mengelola state orders
class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(OrderInitial());

  Future<void> loadOrders() async {
    emit(OrderLoading());
    try {
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders: orders));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }
}

// Di UI
BlocBuilder<OrderCubit, OrderState>(
  builder: (context, state) {
    if (state is OrderLoading) return CircularProgressIndicator();
    if (state is OrderLoaded) return OrderList(orders: state.orders);
    return ErrorWidget();
  },
)
```

### 2. equatable
```yaml
equatable: ^2.0.8
```

**Fungsi:** Simplify equality comparisons untuk state classes.

**Penggunaan:**
```dart
class OrderLoaded extends OrderState {
  final List<Order> orders;
  OrderLoaded({required this.orders});

  @override
  List<Object?> get props => [orders]; // Auto-implement == and hashCode
}
```

---

## Database & Storage

### 1. sqflite
```yaml
sqflite: ^2.4.2
```

**Fungsi:** SQLite database untuk penyimpanan lokal offline.

**Penggunaan di project:**
```dart
// lib/data/database/database_helper.dart
class DatabaseHelper {
  Future<Database> _initDB(String filePath) async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT UNIQUE NOT NULL,
        customer_name TEXT NOT NULL,
        total_price INTEGER NOT NULL,
        ...
      )
    ''');
  }
}
```

### 2. path
```yaml
path: ^1.9.1
```

**Fungsi:** Manipulasi path untuk lokasi database file.

**Penggunaan:**
```dart
final dbPath = await getDatabasesPath();
final path = join(dbPath, 'laundry.db');
```

### 3. shared_preferences
```yaml
shared_preferences: ^2.5.4
```

**Fungsi:** Key-value storage untuk settings sederhana.

**Penggunaan:**
```dart
// Simpan onboarding status
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('onboarding_complete', true);

// Baca
final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
```

### 4. path_provider
```yaml
path_provider: ^2.1.5
```

**Fungsi:** Akses ke direktori system (documents, cache, temp).

**Penggunaan:**
```dart
final directory = await getApplicationDocumentsDirectory();
final filePath = '${directory.path}/report.xlsx';
```

---

## Networking & Connectivity

### 1. supabase_flutter
```yaml
supabase_flutter: ^2.8.4
```

**Fungsi:** Official Supabase SDK untuk Flutter - authentication, database, realtime, storage.

**Penggunaan di project:**
```dart
// lib/core/services/supabase_service.dart
class SupabaseService {
  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  // Authentication
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Database operations
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    return await client.from(table).insert(data).select().single();
  }

  // Realtime subscriptions
  RealtimeChannel subscribeToTable(String table, {...}) {
    return client.channel('public:$table')
      .onPostgresChanges(event: PostgresChangeEvent.insert, ...)
      .subscribe();
  }
}
```

### 2. connectivity_plus
```yaml
connectivity_plus: ^6.1.4
```

**Fungsi:** Monitor status koneksi internet.

**Penggunaan di project:**
```dart
// lib/core/services/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);

    _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
```

### 3. flutter_dotenv
```yaml
flutter_dotenv: ^5.2.1
```

**Fungsi:** Load environment variables dari file `.env`.

**Penggunaan:**
```dart
// .env file
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJI...

// main.dart
await dotenv.load(fileName: '.env');

// Akses
final url = dotenv.env['SUPABASE_URL']!;
```

---

## UI & Theming

### 1. google_fonts
```yaml
google_fonts: ^7.0.2
```

**Fungsi:** Akses ke 1000+ Google Fonts tanpa download manual.

**Penggunaan:**
```dart
// lib/core/theme/app_theme.dart
class AppTypography {
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
}
```

### 2. fl_chart
```yaml
fl_chart: ^1.1.1
```

**Fungsi:** Chart library untuk visualisasi data (bar, line, pie charts).

**Penggunaan di project:**
```dart
// lib/presentation/screens/reports/report_screen.dart
BarChart(
  BarChartData(
    barGroups: data.dailyRevenue.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.revenue.toDouble(),
            gradient: AppThemeColors.primaryGradient,
          ),
        ],
      );
    }).toList(),
  ),
)
```

---

## Utilities

### 1. intl
```yaml
intl: ^0.20.2
```

**Fungsi:** Internationalization dan formatting (tanggal, angka, currency).

**Penggunaan:**
```dart
// lib/core/utils/currency_formatter.dart
class CurrencyFormatter {
  static final _formatter = NumberFormat('#,###', 'id_ID');

  static String format(int amount) {
    return 'Rp ${_formatter.format(amount)}';
  }
}

// lib/core/utils/date_formatter.dart
class DateFormatter {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
}
```

### 2. crypto
```yaml
crypto: ^3.0.6
```

**Fungsi:** Cryptographic functions untuk hashing password.

**Penggunaan:**
```dart
// lib/core/utils/password_helper.dart
class PasswordHelper {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
```

### 3. uuid
```yaml
uuid: ^4.5.2
```

**Fungsi:** Generate unique identifiers.

**Penggunaan:**
```dart
final uuid = Uuid();
final id = uuid.v4(); // "550e8400-e29b-41d4-a716-446655440000"
```

### 4. permission_handler
```yaml
permission_handler: ^12.0.1
```

**Fungsi:** Request dan check permissions (bluetooth, storage, dll).

**Penggunaan:**
```dart
// Request bluetooth permission untuk printer
if (await Permission.bluetooth.isDenied) {
  await Permission.bluetooth.request();
}
if (await Permission.bluetoothConnect.isDenied) {
  await Permission.bluetoothConnect.request();
}
```

### 5. url_launcher
```yaml
url_launcher: ^6.3.2
```

**Fungsi:** Launch URLs, email, phone, WhatsApp.

**Penggunaan:**
```dart
// lib/core/services/whatsapp_service.dart
class WhatsAppService {
  static Future<void> sendMessage(String phone, String message) async {
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
```

---

## Printing & Export

### 1. print_bluetooth_thermal
```yaml
print_bluetooth_thermal: ^1.1.9
```

**Fungsi:** Print ke thermal printer via Bluetooth.

**Penggunaan:**
```dart
// lib/core/services/printer_service.dart
class PrinterService {
  Future<bool> connect(String address) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: address);
  }

  Future<void> printReceipt(List<int> bytes) async {
    await PrintBluetoothThermal.writeBytes(bytes);
  }
}
```

### 2. esc_pos_utils_plus
```yaml
esc_pos_utils_plus: ^2.0.3
```

**Fungsi:** Generate ESC/POS commands untuk thermal printer.

**Penggunaan:**
```dart
// lib/core/services/laundry_print.dart
Future<List<int>> generateReceipt(Order order) async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm58, profile);
  List<int> bytes = [];

  bytes += generator.text('LAUNDRY JAGOFLUTTER',
    styles: PosStyles(align: PosAlign.center, bold: true));
  bytes += generator.text('Invoice: ${order.invoiceNo}');
  bytes += generator.text('Customer: ${order.customerName}');
  // ...
  bytes += generator.cut();

  return bytes;
}
```

### 3. excel
```yaml
excel: ^4.0.6
```

**Fungsi:** Create dan manipulasi file Excel (.xlsx).

**Penggunaan:**
```dart
// lib/core/services/export_service.dart
Future<String> exportReportToExcel(ReportData data) async {
  final excel = Excel.createExcel();
  final sheet = excel['Report'];

  // Header
  sheet.appendRow(['Tanggal', 'Invoice', 'Customer', 'Total']);

  // Data rows
  for (final order in data.orders) {
    sheet.appendRow([
      order.orderDate.toString(),
      order.invoiceNo,
      order.customerName,
      order.totalPrice,
    ]);
  }

  // Save file
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/report.xlsx';
  File(filePath).writeAsBytesSync(excel.encode()!);

  return filePath;
}
```

### 4. share_plus
```yaml
share_plus: ^12.0.1
```

**Fungsi:** Share files dan text ke aplikasi lain.

**Penggunaan:**
```dart
// Share exported Excel file
await Share.shareXFiles(
  [XFile(filePath)],
  text: 'Laporan Laundry',
);
```

---

## Dev Dependencies

### 1. flutter_lints
```yaml
flutter_lints: ^6.0.0
```
Lint rules untuk code quality.

### 2. flutter_launcher_icons
```yaml
flutter_launcher_icons: ^0.14.3
```
Generate app icons untuk Android dan iOS.

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/logolaundry.png"
```

### 3. change_app_package_name
```yaml
change_app_package_name: ^1.5.0
```
Ubah package name aplikasi dengan mudah.

```bash
flutter pub run change_app_package_name:main com.jagoflutter.laundryoffline
```

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │ STATE MANAGEMENT │    │   UI / THEMING   │                   │
│  │  flutter_bloc    │    │  google_fonts    │                   │
│  │  equatable       │    │  fl_chart        │                   │
│  └────────┬─────────┘    └────────┬─────────┘                   │
│           │                       │                              │
│           └───────────┬───────────┘                              │
│                       │                                          │
│  ┌────────────────────┴────────────────────┐                    │
│  │              DATA LAYER                  │                    │
│  │                                          │                    │
│  │  ┌─────────────┐    ┌─────────────────┐ │                    │
│  │  │   LOCAL     │    │     REMOTE      │ │                    │
│  │  │  sqflite    │◄──►│ supabase_flutter│ │                    │
│  │  │  shared_pref│    │ connectivity_plus│ │                   │
│  │  │  path       │    │ flutter_dotenv  │ │                    │
│  │  └─────────────┘    └─────────────────┘ │                    │
│  │                                          │                    │
│  └──────────────────────────────────────────┘                    │
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │    UTILITIES     │    │  PRINT & EXPORT  │                   │
│  │  intl            │    │ print_bluetooth  │                   │
│  │  crypto          │    │ esc_pos_utils    │                   │
│  │  uuid            │    │ excel            │                   │
│  │  url_launcher    │    │ share_plus       │                   │
│  │  path_provider   │    │                  │                   │
│  │  permission_handler   └──────────────────┘                   │
│  └──────────────────┘                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tips Memilih Package

1. **Popularity** - Lihat likes, pub points, dan popularity di pub.dev
2. **Maintenance** - Cek kapan terakhir update
3. **Documentation** - Package dengan docs bagus lebih mudah digunakan
4. **Issues** - Cek open issues di GitHub
5. **Null Safety** - Pastikan mendukung null safety
6. **Size** - Pertimbangkan impact ke app size
