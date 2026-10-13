# Sync Online-Offline: Implementasi Offline-First

## Daftar Isi
1. [Konsep Offline-First](#1-konsep-offline-first)
2. [Architecture Sync](#2-architecture-sync)
3. [Connectivity Service](#3-connectivity-service)
4. [Sync Queue Mechanism](#4-sync-queue-mechanism)
5. [Sync Service Implementation](#5-sync-service-implementation)
6. [Repository Pattern untuk Offline-First](#6-repository-pattern-untuk-offline-first)
7. [Handling Conflicts](#7-handling-conflicts)
8. [UI Feedback](#8-ui-feedback)
9. [Best Practices](#9-best-practices)

---

## 1. Konsep Offline-First

### Apa itu Offline-First?

Offline-First adalah pendekatan development di mana aplikasi **dirancang untuk bekerja tanpa koneksi internet** sebagai kondisi default, dan sync ke server saat online.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   TRADITIONAL APPROACH          OFFLINE-FIRST APPROACH          │
│   ═══════════════════          ═════════════════════           │
│                                                                  │
│   User Action                   User Action                     │
│        │                             │                          │
│        ▼                             ▼                          │
│   ┌─────────┐                   ┌─────────┐                    │
│   │ Server  │  ◀── Internet ──▶ │  Local  │                    │
│   │   API   │                   │   DB    │                    │
│   └────┬────┘                   └────┬────┘                    │
│        │                             │                          │
│        ▼                             ├──── Immediate Response   │
│   Response                           │                          │
│   (depends on internet)              ▼                          │
│                                 ┌─────────┐                    │
│                                 │  Sync   │ ◀── When Online    │
│                                 │ Queue   │                    │
│                                 └────┬────┘                    │
│                                      │                          │
│                                      ▼                          │
│                                 ┌─────────┐                    │
│                                 │ Server  │                    │
│                                 │   API   │                    │
│                                 └─────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Mengapa Offline-First untuk Aplikasi Laundry?

| Skenario | Tanpa Offline-First | Dengan Offline-First |
|----------|---------------------|----------------------|
| Internet mati | ❌ App tidak bisa digunakan | ✅ Tetap bisa transaksi |
| Sinyal lemah | ❌ Loading lama, timeout | ✅ Instant response |
| Data aman | ❌ Data hilang jika gagal kirim | ✅ Data tersimpan lokal |
| Kecepatan | ❌ Tergantung server | ✅ Selalu cepat |

---

## 2. Architecture Sync

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FLUTTER APP                                 │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                      PRESENTATION LAYER                         │ │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │ │
│  │  │   Screen    │    │   Widget    │    │   Connectivity      │ │ │
│  │  │   (UI)      │    │   (Cards)   │    │   Status Widget     │ │ │
│  │  └──────┬──────┘    └──────┬──────┘    └──────────┬──────────┘ │ │
│  └─────────┼─────────────────┼───────────────────────┼────────────┘ │
│            │                 │                       │              │
│            ▼                 ▼                       ▼              │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                        LOGIC LAYER                              │ │
│  │  ┌─────────────────┐         ┌─────────────────────────────┐   │ │
│  │  │   OrderCubit    │         │       SyncCubit             │   │ │
│  │  │   - loadOrders  │         │   - syncStatus              │   │ │
│  │  │   - createOrder │         │   - pendingCount            │   │ │
│  │  └────────┬────────┘         └──────────────┬──────────────┘   │ │
│  └───────────┼──────────────────────────────────┼─────────────────┘ │
│              │                                  │                   │
│              ▼                                  ▼                   │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                        DATA LAYER                               │ │
│  │                                                                 │ │
│  │  ┌─────────────────┐    ┌──────────────────────────────────┐   │ │
│  │  │ OrderRepository │    │         SyncService              │   │ │
│  │  │                 │    │                                  │   │ │
│  │  │ - saveToLocal() │───▶│  - queueForSync()               │   │ │
│  │  │ - getFromLocal()│    │  - syncAll()                    │   │ │
│  │  │                 │    │  - pushLocalChanges()           │   │ │
│  │  └────────┬────────┘    └──────────────┬───────────────────┘   │ │
│  │           │                            │                       │ │
│  │           ▼                            ▼                       │ │
│  │  ┌─────────────────┐         ┌─────────────────────────────┐   │ │
│  │  │   SQLite DB     │         │     sync_queue table        │   │ │
│  │  │   (Local)       │         │  ┌─────┬────────┬────────┐  │   │ │
│  │  │                 │         │  │table│local_id│  data  │  │   │ │
│  │  │ - orders        │         │  ├─────┼────────┼────────┤  │   │ │
│  │  │ - customers     │         │  │order│   42   │{json}  │  │   │ │
│  │  │ - payments      │         │  │pay  │   15   │{json}  │  │   │ │
│  │  └─────────────────┘         │  └─────┴────────┴────────┘  │   │ │
│  │                              └──────────────┬──────────────┘   │ │
│  └───────────────────────────────────────────────┼────────────────┘ │
│                                                  │                  │
│                                                  │ When Online      │
│                                                  ▼                  │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                     CORE SERVICES                               │ │
│  │  ┌─────────────────┐         ┌─────────────────────────────┐   │ │
│  │  │Connectivity     │────────▶│     SupabaseService         │   │ │
│  │  │Service          │         │                             │   │ │
│  │  │                 │         │  - insert()                 │   │ │
│  │  │ - isOnline      │         │  - update()                 │   │ │
│  │  │ - onChanged     │         │  - delete()                 │   │ │
│  │  └─────────────────┘         └──────────────┬──────────────┘   │ │
│  └───────────────────────────────────────────────┼────────────────┘ │
│                                                  │                  │
└──────────────────────────────────────────────────┼──────────────────┘
                                                   │
                                                   ▼
                                          ┌───────────────┐
                                          │   SUPABASE    │
                                          │  (Cloud DB)   │
                                          └───────────────┘
```

---

## 3. Connectivity Service

### File: `lib/core/services/connectivity_service.dart`

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk monitor status koneksi internet
class ConnectivityService {
  // Singleton pattern
  ConnectivityService._();
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();

  bool _isOnline = false;

  /// Status online saat ini
  bool get isOnline => _isOnline;

  /// Stream untuk listen perubahan koneksi
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initialize - panggil di main.dart
  Future<void> initialize() async {
    // Cek koneksi awal
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);

    // Listen perubahan koneksi
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Online jika ada koneksi (bukan none)
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    // Emit hanya jika status berubah
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
    }
  }

  /// Cek koneksi manual
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
```

### Penggunaan di main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();

  // Initialize Supabase
  await SupabaseService.instance.initialize();

  // Initialize sync service
  await SyncService.instance.initialize();

  runApp(const MyApp());
}
```

---

## 4. Sync Queue Mechanism

### Database Schema untuk Sync Queue

```dart
// Di database_helper.dart

await db.execute('''
  CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,      -- nama tabel (orders, customers, dll)
    record_id INTEGER NOT NULL,    -- local ID dari record
    operation TEXT NOT NULL,       -- INSERT, UPDATE, DELETE
    data TEXT,                     -- JSON data untuk sync
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    synced_at TEXT                 -- NULL jika belum sync
  )
''');
```

### Struktur Data di Sync Queue

```
┌────┬────────────┬───────────┬───────────┬────────────────────────────┐
│ id │ table_name │ record_id │ operation │           data             │
├────┼────────────┼───────────┼───────────┼────────────────────────────┤
│ 1  │ customers  │    15     │  INSERT   │ {"name":"Rina","phone":..} │
│ 2  │ orders     │    42     │  INSERT   │ {"invoice_no":"LNDR-.."}   │
│ 3  │ order_items│    101    │  INSERT   │ {"service_name":"Cuci.."} │
│ 4  │ payments   │    78     │  INSERT   │ {"amount":50000,"change":0}│
│ 5  │ orders     │    40     │  UPDATE   │ {"status":"done"}          │
└────┴────────────┴───────────┴───────────┴────────────────────────────┘
```

### Local Datasource Methods

```dart
// lib/data/datasources/local/local_datasource.dart

class LocalDatasource {
  /// Tambah item ke sync queue
  Future<void> addToSyncQueue({
    required String tableName,
    required int recordId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': action,
      'data': json.encode(data),  // Convert map ke JSON string
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ambil semua item yang belum di-sync
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'id ASC',  // FIFO - first in first out
    );
  }

  /// Tandai item sudah di-sync
  Future<void> markSynced(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'sync_queue',
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus item yang sudah di-sync (cleanup)
  Future<void> clearSyncedItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'sync_queue',
      where: 'synced_at IS NOT NULL',
    );
  }
}
```

---

## 5. Sync Service Implementation

### File: `lib/core/services/sync_service.dart`

```dart
import 'dart:async';
import 'dart:convert';

enum SyncStatus { idle, syncing, success, error }
enum SyncAction { insert, update, delete }

class SyncService {
  SyncService._();
  static final SyncService _instance = SyncService._();
  static SyncService get instance => _instance;

  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  final LocalDatasource _local = LocalDatasource();

  final _statusController = StreamController<SyncStatus>.broadcast();

  SyncStatus _status = SyncStatus.idle;
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncStatus get status => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;
  bool get isSyncing => _isSyncing;

  /// Initialize sync service
  Future<void> initialize() async {
    // Auto-sync saat koneksi kembali online
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncAll();
      }
    });

    // Periodic sync setiap 30 detik saat online
    _periodicSyncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_connectivity.isOnline && _supabase.isAuthenticated && !_isSyncing) {
        syncAll();
      }
    });

    // Initial sync jika online
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      syncAll();
    }
  }

  /// Queue local change untuk sync
  Future<void> queueForSync({
    required String table,
    required int localId,
    required SyncAction action,
    required Map<String, dynamic> data,
  }) async {
    await _local.addToSyncQueue(
      tableName: table,
      recordId: localId,
      action: action.name.toUpperCase(),
      data: data,
    );

    // Langsung sync jika online
    if (_connectivity.isOnline && !_isSyncing) {
      syncAll();
    }
  }

  /// Sync semua pending items
  Future<bool> syncAll() async {
    if (_isSyncing) return false;
    if (!_connectivity.isOnline) return false;
    if (!_supabase.isAuthenticated) return false;

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      await _pushLocalChanges();
      _updateStatus(SyncStatus.success);
      return true;
    } catch (e) {
      _updateStatus(SyncStatus.error);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes ke Supabase
  Future<void> _pushLocalChanges() async {
    final pendingItems = await _local.getPendingSyncItems();

    if (pendingItems.isEmpty) return;

    // Get outlet_id untuk user ini
    String? outletId = await _getOutletId();
    if (outletId == null) return;

    // Maps untuk track local_id -> remote_id
    final customerIdMap = <int, String>{};
    final orderIdMap = <int, String>{};

    for (final item in pendingItems) {
      try {
        final table = item['table_name'] as String;
        final action = item['operation'] as String;
        final data = json.decode(item['data'] as String);

        switch (action) {
          case 'INSERT':
            await _handleInsert(table, data, outletId, customerIdMap, orderIdMap);
            break;
          case 'UPDATE':
            await _handleUpdate(table, data);
            break;
          case 'DELETE':
            await _handleDelete(table, data);
            break;
        }

        // Tandai sudah sync
        await _local.markSynced(item['id'] as int);

      } catch (e) {
        debugPrint('Sync error: $e');
        // Lanjutkan ke item berikutnya
      }
    }

    // Cleanup items yang sudah sync
    await _local.clearSyncedItems();
  }

  Future<void> _handleInsert(
    String table,
    Map<String, dynamic> data,
    String outletId,
    Map<int, String> customerIdMap,
    Map<int, String> orderIdMap,
  ) async {
    switch (table) {
      case 'customers':
        final localId = data.remove('local_id') as int?;
        data['outlet_id'] = outletId;

        // Cek apakah sudah ada (by phone)
        final phone = data['phone'] as String?;
        if (phone != null) {
          final existing = await _supabase.client
              .from('customers')
              .select('id')
              .eq('outlet_id', outletId)
              .eq('phone', phone)
              .maybeSingle();

          if (existing != null) {
            if (localId != null) {
              customerIdMap[localId] = existing['id'];
            }
            return; // Skip, sudah ada
          }
        }

        final result = await _supabase.insert(table, data);
        if (localId != null) {
          customerIdMap[localId] = result['id'];
        }
        break;

      case 'orders':
        final localId = data.remove('local_id') as int?;
        final localCustomerId = data.remove('local_customer_id') as int?;
        data['outlet_id'] = outletId;

        // Map customer_id jika ada
        if (localCustomerId != null && customerIdMap.containsKey(localCustomerId)) {
          data['customer_id'] = customerIdMap[localCustomerId];
        }

        // Cek duplikat by invoice_no
        final invoiceNo = data['invoice_no'];
        final existing = await _supabase.client
            .from('orders')
            .select('id')
            .eq('outlet_id', outletId)
            .eq('invoice_no', invoiceNo)
            .maybeSingle();

        if (existing != null) {
          // Sudah ada, update local dengan remote_id
          if (localId != null) {
            orderIdMap[localId] = existing['id'];
            await _local.rawExecute(
              'UPDATE orders SET remote_id = ? WHERE id = ?',
              [existing['id'], localId],
            );
          }
          return;
        }

        final result = await _supabase.insert(table, data);
        if (localId != null) {
          orderIdMap[localId] = result['id'];
          // Update local dengan remote_id
          await _local.rawExecute(
            'UPDATE orders SET remote_id = ? WHERE id = ?',
            [result['id'], localId],
          );
        }
        break;

      case 'order_items':
        final localOrderId = data.remove('local_order_id') as int?;

        // Map order_id
        String? remoteOrderId;
        if (localOrderId != null) {
          remoteOrderId = orderIdMap[localOrderId] ??
              await _getRemoteOrderId(localOrderId);
        }

        if (remoteOrderId != null) {
          data['order_id'] = remoteOrderId;
          await _supabase.insert(table, data);
        }
        break;

      case 'payments':
        final localId = data.remove('local_id') as int?;
        final localOrderId = data.remove('local_order_id') as int?;

        // Map order_id
        String? remoteOrderId;
        if (localOrderId != null) {
          remoteOrderId = orderIdMap[localOrderId] ??
              await _getRemoteOrderId(localOrderId);
        }

        if (remoteOrderId != null) {
          data['order_id'] = remoteOrderId;
          final result = await _supabase.insert(table, data);

          // Update local dengan remote_id
          if (localId != null) {
            await _local.rawExecute(
              'UPDATE payments SET remote_id = ? WHERE id = ?',
              [result['id'], localId],
            );
          }

          // Update paid amount di order Supabase
          final paidAmount = await _getLocalOrderPaid(localOrderId!);
          await _supabase.update('orders', remoteOrderId, {'paid': paidAmount});
        }
        break;
    }
  }

  Future<void> _handleUpdate(String table, Map<String, dynamic> data) async {
    final remoteId = data.remove('remote_id') ?? data.remove('id');
    if (remoteId != null) {
      data.remove('local_id');
      await _supabase.update(table, remoteId.toString(), data);
    }
  }

  Future<void> _handleDelete(String table, Map<String, dynamic> data) async {
    final remoteId = data['remote_id'] ?? data['id'];
    if (remoteId != null) {
      await _supabase.delete(table, remoteId.toString());
    }
  }

  Future<String?> _getOutletId() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return null;

    final profile = await _supabase.client
        .from('profiles')
        .select('outlet_id')
        .eq('id', userId)
        .single();

    return profile['outlet_id'];
  }

  Future<String?> _getRemoteOrderId(int localId) async {
    final result = await _local.rawQuery(
      'SELECT remote_id FROM orders WHERE id = ?',
      [localId],
    );
    return result.isNotEmpty ? result.first['remote_id'] : null;
  }

  Future<int> _getLocalOrderPaid(int localId) async {
    final result = await _local.rawQuery(
      'SELECT paid FROM orders WHERE id = ?',
      [localId],
    );
    return result.isNotEmpty ? (result.first['paid'] as int? ?? 0) : 0;
  }

  void _updateStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
    _statusController.close();
  }
}
```

---

## 6. Repository Pattern untuk Offline-First

### Contoh: Order Repository

```dart
// lib/data/repositories/order_repository.dart

class OrderRepository {
  final DatabaseHelper _db;

  /// Create order - simpan lokal dulu, queue untuk sync
  Future<Order> createOrder({
    required Order order,
    required List<OrderItem> items,
    Payment? initialPayment,
  }) async {
    final db = await _db.database;

    // 1. Simpan ke SQLite dalam transaction
    final createdOrder = await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert('orders', {
        'invoice_no': order.invoiceNo,
        'customer_name': order.customerName,
        'total_price': order.totalPrice,
        'paid': initialPayment?.amount ?? 0,
        'status': 'pending',
        // ...
      });

      // Insert items
      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'service_name': item.serviceName,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        });
      }

      // Insert initial payment if any
      if (initialPayment != null && initialPayment.amount > 0) {
        await txn.insert('payments', {
          'order_id': orderId,
          'amount': initialPayment.amount,
          'change': initialPayment.change,
          'payment_date': initialPayment.paymentDate.toIso8601String(),
        });
      }

      return order.copyWith(id: orderId);
    });

    // 2. Queue untuk sync ke Supabase
    if (SupabaseService.instance.isAuthenticated) {
      await _queueOrderForSync(createdOrder, items);
    }

    return createdOrder;
  }

  Future<void> _queueOrderForSync(Order order, List<OrderItem> items) async {
    // Queue order
    await SyncService.instance.queueForSync(
      table: 'orders',
      localId: order.id!,
      action: SyncAction.insert,
      data: {
        'invoice_no': order.invoiceNo,
        'customer_name': order.customerName,
        'total_price': order.totalPrice,
        'paid': order.paid,
        'status': order.status.value,
        'local_id': order.id,
        // ...
      },
    );

    // Queue order items
    for (final item in items) {
      await SyncService.instance.queueForSync(
        table: 'order_items',
        localId: item.id ?? 0,
        action: SyncAction.insert,
        data: {
          'service_name': item.serviceName,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
          'local_order_id': order.id,
        },
      );
    }
  }

  /// Get orders - selalu dari local
  Future<List<Order>> getAllOrders() async {
    final db = await _db.database;
    final result = await db.query('orders', orderBy: 'created_at DESC');
    return result.map((e) => Order.fromMap(e)).toList();
  }

  /// Update order status
  Future<void> updateOrderStatus(int id, OrderStatus newStatus) async {
    final db = await _db.database;

    // 1. Update lokal
    await db.update(
      'orders',
      {'status': newStatus.value},
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2. Queue untuk sync jika ada remote_id
    final order = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    final remoteId = order.first['remote_id'];

    if (remoteId != null) {
      await SyncService.instance.queueForSync(
        table: 'orders',
        localId: id,
        action: SyncAction.update,
        data: {
          'remote_id': remoteId,
          'status': newStatus.value,
        },
      );
    }
  }
}
```

---

## 7. Handling Conflicts

### Strategi Conflict Resolution

```
┌────────────────────────────────────────────────────────────────────┐
│                    CONFLICT SCENARIOS                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. SAME RECORD MODIFIED OFFLINE & ONLINE                          │
│     ─────────────────────────────────────────                      │
│     Local: Order #42 status = 'done'                               │
│     Remote: Order #42 status = 'ready'                             │
│                                                                     │
│     SOLUTION: Last-Write-Wins (LWW) dengan timestamp               │
│               atau User-Decides (show conflict dialog)             │
│                                                                     │
│  2. RECORD DELETED REMOTELY BUT MODIFIED LOCALLY                   │
│     ─────────────────────────────────────────────────              │
│     Local: Update Order #42                                        │
│     Remote: Order #42 tidak ada (deleted)                          │
│                                                                     │
│     SOLUTION: Re-create record atau discard local changes          │
│                                                                     │
│  3. DUPLICATE RECORDS                                              │
│     ────────────────────                                           │
│     Dua device buat order dengan invoice yang sama                 │
│                                                                     │
│     SOLUTION: Gunakan UNIQUE constraint + upsert                   │
│               atau append device ID ke invoice                     │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### Implementasi di Project Ini

```dart
// Di sync_service.dart - saat sync orders

// Cek apakah order sudah ada di Supabase
final existing = await _supabase.client
    .from('orders')
    .select('id')
    .eq('outlet_id', outletId)
    .eq('invoice_no', invoiceNo)
    .maybeSingle();

if (existing != null) {
  // Order sudah ada - skip insert, update local dengan remote_id
  await _local.rawExecute(
    'UPDATE orders SET remote_id = ? WHERE id = ?',
    [existing['id'], localId],
  );
  return; // Don't insert duplicate
}

// Order belum ada - insert baru
final result = await _supabase.insert('orders', data);
```

---

## 8. UI Feedback

### Connectivity Status Widget

```dart
// lib/presentation/widgets/connectivity_status_widget.dart

class ConnectivityStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: isOnline ? 0 : 30,
          color: Colors.red,
          child: isOnline
              ? SizedBox.shrink()
              : Center(
                  child: Text(
                    'Offline Mode - Data akan sync saat online',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
        );
      },
    );
  }
}
```

### Sync Status Indicator

```dart
class SyncStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        if (state.status == SyncStatus.syncing) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Syncing...'),
            ],
          );
        }

        if (state.pendingCount > 0) {
          return Chip(
            label: Text('${state.pendingCount} pending'),
            backgroundColor: Colors.orange.shade100,
          );
        }

        return Icon(Icons.cloud_done, color: Colors.green);
      },
    );
  }
}
```

---

## 9. Best Practices

### DO's ✅

1. **Selalu simpan ke local dulu**
   ```dart
   // GOOD
   await saveToLocalDB(order);
   await queueForSync(order);

   // BAD
   await saveToSupabase(order);  // Bisa gagal jika offline
   ```

2. **Gunakan transaction untuk operasi terkait**
   ```dart
   await db.transaction((txn) async {
     final orderId = await txn.insert('orders', orderData);
     for (final item in items) {
       await txn.insert('order_items', {..., 'order_id': orderId});
     }
   });
   ```

3. **Handle sync errors gracefully**
   ```dart
   try {
     await _supabase.insert(table, data);
     await _local.markSynced(item['id']);
   } catch (e) {
     // Log error, lanjutkan ke item berikutnya
     // Item akan di-retry di sync berikutnya
   }
   ```

4. **Tambahkan timestamp untuk conflict resolution**
   ```dart
   await db.insert('orders', {
     ...orderData,
     'updated_at': DateTime.now().toIso8601String(),
   });
   ```

### DON'Ts ❌

1. **Jangan block UI saat sync**
   ```dart
   // BAD - UI freeze
   await syncAll();
   Navigator.pushNamed(context, '/home');

   // GOOD - sync di background
   unawaited(syncAll());  // Fire and forget
   Navigator.pushNamed(context, '/home');
   ```

2. **Jangan simpan data sensitif di sync queue**
   ```dart
   // BAD
   data: {'password': user.password}

   // GOOD - hash atau encrypt
   data: {'password_hash': hashPassword(user.password)}
   ```

3. **Jangan ignore errors**
   ```dart
   // BAD
   try { await sync(); } catch (_) {}

   // GOOD
   try {
     await sync();
   } catch (e) {
     logError(e);
     showErrorToUser(e);
   }
   ```

---

## Kesimpulan

Offline-First architecture dengan Sync Queue memungkinkan:

1. **Reliability** - App selalu bisa digunakan
2. **Speed** - Response instan dari local DB
3. **Data Safety** - Tidak ada data yang hilang
4. **Scalability** - Mudah menambah entitas baru untuk sync

### Checklist Implementation

- [ ] Setup ConnectivityService
- [ ] Setup SyncService
- [ ] Buat sync_queue table
- [ ] Implement queue di setiap repository
- [ ] Handle INSERT, UPDATE, DELETE
- [ ] Handle conflicts
- [ ] Add UI feedback
- [ ] Test offline scenarios
