# Architecture Project: Laundry Offline App

## Daftar Isi
1. [Overview Architecture](#overview-architecture)
2. [Folder Structure](#folder-structure)
3. [Clean Architecture Layers](#clean-architecture-layers)
4. [State Management: BLoC/Cubit](#state-management-bloccubit)
5. [Database Design](#database-design)
6. [Data Flow](#data-flow)

---

## Overview Architecture

Aplikasi ini menggunakan **Clean Architecture** yang dimodifikasi untuk Flutter dengan pattern **BLoC/Cubit** untuk state management.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                      PRESENTATION LAYER                          │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│   │   Screens   │  │   Widgets   │  │   Cubits/BLoCs      │    │
│   │  (UI Pages) │  │ (Reusable)  │  │ (State Management)  │    │
│   └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘    │
│          │                │                     │                │
├──────────┼────────────────┼─────────────────────┼────────────────┤
│          │                │                     │                │
│          │         LOGIC/DOMAIN LAYER           │                │
│          │    ┌─────────────────────────┐      │                │
│          └────┤      Cubits/BLoCs       ├──────┘                │
│               │   (Business Logic)      │                       │
│               └───────────┬─────────────┘                       │
│                           │                                      │
├───────────────────────────┼──────────────────────────────────────┤
│                           │                                      │
│                      DATA LAYER                                  │
│   ┌─────────────┐  ┌──────┴──────┐  ┌─────────────────────┐    │
│   │   Models    │  │ Repositories │  │    Datasources     │    │
│   │  (Entities) │  │  (Abstraction)│  │ (Local & Remote)  │    │
│   └─────────────┘  └─────────────┘  └─────────────────────┘    │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│                      CORE LAYER                                  │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│   │  Services   │  │   Utils     │  │   Constants/Theme   │    │
│   │ (Supabase,  │  │ (Formatter, │  │  (Colors, Strings)  │    │
│   │  Sync, etc) │  │  Helpers)   │  │                     │    │
│   └─────────────┘  └─────────────┘  └─────────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                      # Entry point aplikasi
│
├── core/                          # CORE LAYER
│   ├── constants/
│   │   ├── app_constants.dart     # Konstanta aplikasi
│   │   └── colors.dart            # Warna-warna
│   │
│   ├── exceptions/
│   │   └── database_exception.dart
│   │
│   ├── services/                  # Business Services
│   │   ├── connectivity_service.dart   # Monitor koneksi internet
│   │   ├── supabase_service.dart       # Supabase client wrapper
│   │   ├── sync_service.dart           # Sync local ↔ remote
│   │   ├── restore_service.dart        # Backup & restore
│   │   ├── printer_service.dart        # Bluetooth printer
│   │   ├── whatsapp_service.dart       # WhatsApp integration
│   │   ├── export_service.dart         # Export to Excel
│   │   ├── session_service.dart        # User session
│   │   └── outlet_service.dart         # Multi-outlet context management
│   │
│   ├── theme/
│   │   └── app_theme.dart         # Material theme, colors, typography
│   │
│   └── utils/                     # Helper utilities
│       ├── currency_formatter.dart
│       ├── date_formatter.dart
│       ├── invoice_generator.dart
│       ├── password_helper.dart
│       └── thousand_separator_formatter.dart
│
├── data/                          # DATA LAYER
│   ├── database/
│   │   └── database_helper.dart   # SQLite database setup & migrations
│   │
│   ├── datasources/
│   │   ├── local/
│   │   │   └── local_datasource.dart   # SQLite operations
│   │   └── remote/
│   │       └── remote_datasource.dart  # Supabase operations
│   │
│   ├── models/                    # Data entities
│   │   ├── customer.dart
│   │   ├── order.dart
│   │   ├── order_item.dart
│   │   ├── outlet.dart            # Multi-outlet support
│   │   ├── payment.dart
│   │   ├── service.dart
│   │   ├── user.dart
│   │   └── app_setting.dart
│   │
│   └── repositories/              # Data repositories
│       ├── auth_repository.dart
│       ├── customer_repository.dart
│       ├── order_repository.dart
│       ├── payment_repository.dart
│       ├── outlet_repository.dart       # Multi-outlet CRUD
│       ├── report_repository.dart
│       ├── service_repository.dart
│       ├── settings_repository.dart
│       ├── user_repository.dart
│       │
│       │  # Supabase-specific repositories
│       ├── supabase_auth_repository.dart
│       ├── supabase_customer_repository.dart
│       ├── supabase_order_repository.dart
│       └── supabase_service_repository.dart
│
├── logic/                         # LOGIC LAYER (State Management)
│   └── cubits/
│       ├── auth/
│       │   ├── auth_cubit.dart
│       │   └── auth_state.dart
│       ├── customer/
│       │   ├── customer_cubit.dart
│       │   └── customer_state.dart
│       ├── dashboard/
│       │   ├── dashboard_cubit.dart
│       │   └── dashboard_state.dart
│       ├── order/
│       │   ├── order_cubit.dart
│       │   └── order_state.dart
│       ├── outlet/                 # Multi-outlet state management
│       │   ├── outlet_cubit.dart
│       │   └── outlet_state.dart
│       ├── printer/
│       │   ├── printer_cubit.dart
│       │   └── printer_state.dart
│       ├── report/
│       │   ├── report_cubit.dart
│       │   └── report_state.dart
│       ├── service/
│       │   ├── service_cubit.dart
│       │   └── service_state.dart
│       ├── settings/
│       │   ├── settings_cubit.dart
│       │   └── settings_state.dart
│       ├── sync/
│       │   ├── sync_cubit.dart
│       │   └── sync_state.dart
│       └── user/
│           ├── user_cubit.dart
│           └── user_state.dart
│
└── presentation/                  # PRESENTATION LAYER
    ├── screens/
    │   ├── auth/
    │   │   └── login_screen.dart
    │   ├── customers/
    │   │   ├── customer_list_screen.dart
    │   │   ├── customer_form_screen.dart
    │   │   └── customer_detail_screen.dart
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart
    │   ├── onboarding/
    │   │   └── onboarding_screen.dart
    │   ├── orders/
    │   │   ├── order_list_screen.dart
    │   │   ├── order_form_screen.dart
    │   │   └── order_detail_screen.dart
    │   ├── reports/
    │   │   └── report_screen.dart
    │   ├── services/
    │   │   ├── service_list_screen.dart
    │   │   └── service_form_screen.dart
    │   ├── settings/
    │   │   ├── settings_screen.dart
    │   │   ├── online_settings_screen.dart
    │   │   ├── printer_settings_screen.dart
    │   │   ├── outlet_management_screen.dart  # Multi-outlet management
    │   │   ├── user_management_screen.dart
    │   │   └── user_form_screen.dart
    │   └── main_screen.dart       # Bottom navigation wrapper
    │
    └── widgets/                   # Reusable widgets
        ├── connectivity_status_widget.dart
        ├── custom_button.dart
        ├── custom_card.dart
        ├── custom_text_field.dart
        ├── order_card.dart
        ├── outlet_selector_widget.dart  # Outlet switcher widget
        └── status_badge.dart
```

---

## Clean Architecture Layers

### 1. Presentation Layer
Berisi UI dan state management. Tidak ada business logic di sini.

```dart
// Contoh: Screen menggunakan Cubit
class OrderListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return CircularProgressIndicator();
        }
        if (state is OrderLoaded) {
          return ListView.builder(
            itemCount: state.orders.length,
            itemBuilder: (ctx, i) => OrderCard(order: state.orders[i]),
          );
        }
        return ErrorWidget();
      },
    );
  }
}
```

### 2. Logic Layer (Cubits)
Berisi business logic dan state management.

```dart
// Contoh: Cubit dengan business logic
class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repository;

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

  Future<void> createOrder(Order order, List<OrderItem> items) async {
    // Business logic: validasi, generate invoice, dll
    final invoiceNo = await InvoiceGenerator.generate();
    final newOrder = order.copyWith(invoiceNo: invoiceNo);
    await _repository.createOrder(order: newOrder, items: items);
  }
}
```

### 3. Data Layer
Berisi models, repositories, dan datasources.

```dart
// Model
class Order {
  final int? id;
  final String invoiceNo;
  final String customerName;
  final int totalPrice;
  // ...
}

// Repository (abstraction)
class OrderRepository {
  final DatabaseHelper _db;

  Future<List<Order>> getAllOrders() async {
    final result = await _db.query('orders');
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<void> createOrder({required Order order, required List<OrderItem> items}) async {
    // Simpan ke SQLite lokal
    // Queue untuk sync ke Supabase
  }
}
```

### 4. Core Layer
Berisi services, utilities, dan constants yang digunakan di semua layer.

```dart
// Service
class ConnectivityService {
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;
}

// Utility
class CurrencyFormatter {
  static String format(int amount) {
    return 'Rp ${NumberFormat('#,###').format(amount)}';
  }
}
```

---

## State Management: BLoC/Cubit

### Mengapa Cubit?
- Lebih simple dari BLoC (tidak perlu Event class)
- Cukup untuk kebanyakan use case
- Testable dan predictable

### Pattern State

```dart
// State classes dengan Equatable
abstract class OrderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  OrderLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrderError extends OrderState {
  final String message;
  OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}
```

### Diagram State Flow

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│   UI (Screen/Widget)                                    │
│        │                                                │
│        │ User Action (tap button, etc)                  │
│        ▼                                                │
│   ┌─────────────────┐                                   │
│   │     Cubit       │                                   │
│   │  ┌───────────┐  │                                   │
│   │  │  Method   │  │  loadOrders()                     │
│   │  │  Called   │  │  createOrder()                    │
│   │  └─────┬─────┘  │                                   │
│   │        │        │                                   │
│   │        ▼        │                                   │
│   │  ┌───────────┐  │                                   │
│   │  │   emit()  │  │  emit(OrderLoading())             │
│   │  │   State   │  │  emit(OrderLoaded(orders))        │
│   │  └─────┬─────┘  │                                   │
│   └────────┼────────┘                                   │
│            │                                            │
│            ▼                                            │
│   ┌─────────────────┐                                   │
│   │  BlocBuilder    │                                   │
│   │  rebuilds UI    │                                   │
│   │  based on state │                                   │
│   └─────────────────┘                                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Database Design

### Local SQLite Schema

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   outlets    │     │    users     │     │   services   │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ remote_id    │     │ username     │     │ outlet_id(FK)│
│ name         │     │ password_hash│     │ name         │
│ address      │     │ name         │     │ unit         │
│ phone        │     │ role         │     │ price        │
│ invoice_prefix│    │ is_active    │     │ duration_days│
│ owner_id     │     │ outlet_id    │     │ is_active    │
└──────────────┘     └──────────────┘     │ remote_id    │
                                          └──────────────┘

┌──────────────┐
│  customers   │
├──────────────┤
│ id (PK)      │
│ outlet_id(FK)│
│ name         │
│ phone        │
│ address      │
│ total_orders │
│ total_spent  │
│ remote_id    │
└──────────────┘
                                                │
                                                │ 1:N
                                                ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   orders     │────▶│ order_items  │     │  payments    │
├──────────────┤ 1:N ├──────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ invoice_no   │     │ order_id(FK) │     │ order_id(FK) │
│ customer_id  │◀────│ service_name │     │ amount       │
│ customer_name│     │ quantity     │     │ change       │
│ order_date   │     │ unit         │     │ payment_date │
│ due_date     │     │ price_per_unit│    │ payment_method│
│ status       │     │ subtotal     │     │ remote_id    │
│ total_price  │     │ remote_id    │     └──────────────┘
│ paid         │     └──────────────┘            ▲
│ remote_id    │                                 │ 1:N
└──────────────┘─────────────────────────────────┘

┌──────────────┐     ┌──────────────┐
│ app_settings │     │ sync_queue   │
├──────────────┤     ├──────────────┤
│ key (PK)     │     │ id (PK)      │
│ value        │     │ table_name   │
└──────────────┘     │ record_id    │
                     │ operation    │
                     │ data (JSON)  │
                     │ synced_at    │
                     └──────────────┘
```

### Supabase Schema

Same structure dengan tambahan:
- `UUID` sebagai primary key (bukan integer)
- `outlet_id` untuk multi-tenant/multi-outlet
- Row Level Security (RLS) policies
- `outlets` table sebagai parent untuk semua data per-outlet

---

## Data Flow

### Offline-First Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. USER ACTION                                                 │
│     │                                                            │
│     ▼                                                            │
│  2. CUBIT processes action                                      │
│     │                                                            │
│     ▼                                                            │
│  3. REPOSITORY                                                  │
│     │                                                            │
│     ├──────────────────────────────────────┐                    │
│     │                                      │                    │
│     ▼                                      ▼                    │
│  4. SAVE TO SQLite (LOCAL)          5. QUEUE FOR SYNC          │
│     │                                      │                    │
│     │                                      │                    │
│     ▼                                      ▼                    │
│  6. EMIT SUCCESS STATE              7. SYNC SERVICE             │
│     │                                      │                    │
│     │                           ┌─────────┴─────────┐           │
│     │                           │                   │           │
│     │                      Online?             Offline?         │
│     │                           │                   │           │
│     │                           ▼                   ▼           │
│     │                    PUSH TO SUPABASE    KEEP IN QUEUE      │
│     │                           │                   │           │
│     │                           ▼                   │           │
│     │                    UPDATE remote_id           │           │
│     │                           │                   │           │
│     ▼                           ▼                   │           │
│  8. UI UPDATES               COMPLETE          WAIT FOR         │
│                                               CONNECTIVITY       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Sync Queue Mechanism

```
┌─────────────────────────────────────────────────────────────────┐
│                        SYNC QUEUE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  sync_queue table:                                              │
│  ┌────┬────────────┬───────────┬───────────┬──────────────┐    │
│  │ id │ table_name │ record_id │ operation │     data     │    │
│  ├────┼────────────┼───────────┼───────────┼──────────────┤    │
│  │ 1  │ customers  │    15     │  INSERT   │ {name:...}   │    │
│  │ 2  │ orders     │    42     │  INSERT   │ {invoice:..} │    │
│  │ 3  │ payments   │    78     │  INSERT   │ {amount:...} │    │
│  └────┴────────────┴───────────┴───────────┴──────────────┘    │
│                                                                  │
│  Processing order:                                              │
│  1. Customers first (karena orders reference customer)          │
│  2. Orders second                                               │
│  3. Order items & Payments last                                 │
│                                                                  │
│  After sync success:                                            │
│  - Mark as synced (synced_at = NOW)                            │
│  - Update local record with remote_id                          │
│  - Clean up old synced items                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Kesimpulan

Architecture ini memungkinkan:
1. **Offline-first** - Aplikasi selalu bisa digunakan
2. **Testable** - Setiap layer bisa di-test terpisah
3. **Maintainable** - Code terorganisir dengan baik
4. **Scalable** - Mudah menambah fitur baru
5. **Syncable** - Data otomatis sync saat online
6. **Multi-Outlet** - Kelola beberapa cabang dengan data terpisah
