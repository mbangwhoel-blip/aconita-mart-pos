# Multi-Outlet: Backup, Restore & Sync

## Daftar Isi
1. [Overview Multi-Outlet](#1-overview-multi-outlet)
2. [Database Schema](#2-database-schema)
3. [Row Level Security (RLS)](#3-row-level-security-rls)
4. [Backup ke Cloud](#4-backup-ke-cloud)
5. [Restore dari Cloud](#5-restore-dari-cloud)
6. [Auto-Sync Order Baru](#6-auto-sync-order-baru)
7. [ID Mapping Strategy](#7-id-mapping-strategy)
8. [Debug Tools](#8-debug-tools)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Overview Multi-Outlet

### Apa itu Multi-Outlet?

Multi-Outlet memungkinkan satu owner memiliki beberapa cabang laundry dalam satu aplikasi. Setiap outlet memiliki:
- Data terpisah (customers, services, orders)
- Settings sendiri (nama, alamat, invoice prefix)
- Akses terisolasi (kasir hanya lihat outlet mereka)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         OWNER ACCOUNT                                │
│                    (email: owner@laundry.com)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────┐         ┌─────────────────────┐           │
│  │   OUTLET 1          │         │   OUTLET 2          │           │
│  │   "Laundry Pusat"   │         │   "Laundry Cabang"  │           │
│  │   Prefix: LNDR      │         │   Prefix: PLG       │           │
│  ├─────────────────────┤         ├─────────────────────┤           │
│  │ - 3 Customers       │         │ - 2 Customers       │           │
│  │ - 7 Services        │         │ - 2 Services        │           │
│  │ - 10 Orders         │         │ - 5 Orders          │           │
│  │ - Kasir: Ani, Budi  │         │ - Kasir: Citra      │           │
│  └─────────────────────┘         └─────────────────────┘           │
│                                                                      │
│  Owner bisa akses SEMUA outlet                                      │
│  Kasir hanya akses outlet yang ditugaskan                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Fitur Multi-Outlet

| Fitur | Deskripsi |
|-------|-----------|
| Switch Outlet | Owner bisa pindah antar outlet dari menu settings |
| Per-Outlet Settings | Setiap outlet punya nama, alamat, telepon, prefix invoice sendiri |
| Data Isolation | Data customers, services, orders terpisah per outlet |
| Backup per Outlet | Upload data dari SEMUA outlet sekaligus |
| Restore per Outlet | Download data ke outlet yang sesuai |
| RLS Multi-Outlet | Owner akses semua outlet, kasir hanya outlet mereka |

---

## 2. Database Schema

### Local SQLite Schema

```sql
-- Outlets table
CREATE TABLE outlets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id TEXT,                    -- Supabase UUID
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  invoice_prefix TEXT DEFAULT 'INV',
  owner_id TEXT,                     -- Supabase auth user UUID
  created_at TEXT,
  updated_at TEXT
);

-- Semua tabel lain memiliki outlet_id
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id TEXT,
  outlet_id TEXT NOT NULL,           -- Referensi ke outlets.id (local)
  name TEXT NOT NULL,
  phone TEXT,
  -- ...
);

CREATE TABLE services (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id TEXT,
  outlet_id TEXT NOT NULL,
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  -- ...
);

CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id TEXT,
  outlet_id TEXT NOT NULL,
  invoice_no TEXT NOT NULL,
  -- ...
);
```

### Supabase Cloud Schema

```sql
-- Outlets (UUID-based)
CREATE TABLE outlets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  invoice_prefix TEXT DEFAULT 'INV',
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Semua tabel lain referensi outlet_id (UUID)
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  -- ...
);
```

### Perbedaan Local vs Cloud ID

| Aspek | Local (SQLite) | Cloud (Supabase) |
|-------|----------------|------------------|
| Primary Key | INTEGER AUTOINCREMENT | UUID |
| outlet_id | String (local int) | UUID |
| Relasi | Manual mapping | Foreign key |

---

## 3. Row Level Security (RLS)

### Konsep RLS Multi-Outlet

RLS memastikan:
1. **Owner** bisa akses **SEMUA outlet** yang mereka miliki
2. **Kasir** hanya bisa akses **satu outlet** yang ditugaskan

```sql
-- SEBELUM: Hanya satu outlet
CREATE POLICY "Users can manage customers" ON customers
  FOR ALL USING (
    outlet_id IN (SELECT outlet_id FROM profiles WHERE id = auth.uid())
  );

-- SESUDAH: Multi-outlet support
CREATE POLICY "Users can manage customers" ON customers
  FOR ALL USING (
    -- Owner: akses semua outlet yang dimiliki
    outlet_id IN (SELECT id FROM outlets WHERE owner_id = auth.uid())
    OR
    -- Kasir: akses outlet yang ditugaskan
    outlet_id IN (SELECT outlet_id FROM profiles WHERE id = auth.uid())
  );
```

### Full RLS Policies (Multi-Outlet)

```sql
-- =====================================================
-- OUTLETS POLICIES
-- =====================================================
CREATE POLICY "Users can view own outlet" ON outlets
  FOR SELECT USING (
    owner_id = auth.uid()
    OR id IN (SELECT outlet_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can update own outlet" ON outlets
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Users can delete own outlet" ON outlets
  FOR DELETE USING (owner_id = auth.uid());

CREATE POLICY "Anyone can create outlet" ON outlets
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- CUSTOMERS POLICIES
-- =====================================================
CREATE POLICY "Users can view outlet customers" ON customers
  FOR SELECT USING (
    outlet_id IN (SELECT id FROM outlets WHERE owner_id = auth.uid())
    OR outlet_id IN (SELECT outlet_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can manage outlet customers" ON customers
  FOR ALL USING (
    outlet_id IN (SELECT id FROM outlets WHERE owner_id = auth.uid())
    OR outlet_id IN (SELECT outlet_id FROM profiles WHERE id = auth.uid())
  );

-- =====================================================
-- SERVICES, ORDERS, PAYMENTS - sama pattern-nya
-- =====================================================
```

### Migration untuk Existing Database

Jalankan file `supabase/migrations/002_multi_outlet_rls.sql` untuk update RLS policies.

---

## 4. Backup ke Cloud

### Alur Backup Multi-Outlet

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKUP PROCESS                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. OUTLETS                                                         │
│     ┌─────────────┐                    ┌─────────────┐              │
│     │ Local       │  ───── upsert ───▶ │ Supabase    │              │
│     │ outlets     │                    │ outlets     │              │
│     └─────────────┘                    └─────────────┘              │
│           │                                  │                       │
│           ▼ Build outletIdMap               ▼                       │
│     {1: "uuid-1", 2: "uuid-2"}                                      │
│                                                                      │
│  2. APP_SETTINGS (per outlet)                                       │
│     ┌─────────────┐                    ┌─────────────┐              │
│     │ outlets     │  ── upsert ──────▶ │ app_settings│              │
│     │ (name,addr) │    per outlet      │ (key-value) │              │
│     └─────────────┘                    └─────────────┘              │
│                                                                      │
│  3. CUSTOMERS (check by phone first)                                │
│     ┌─────────────┐  ── check cloud ─▶ exists? skip                 │
│     │ Local       │                    not exists? insert           │
│     │ customers   │  ───── map outlet_id to UUID ─────▶ Supabase   │
│     └─────────────┘                                                  │
│                                                                      │
│  4. SERVICES (check by name first)                                  │
│     ┌─────────────┐  ── check cloud ─▶ exists? skip                 │
│     │ Local       │                    not exists? insert           │
│     │ services    │  ───── map outlet_id to UUID ─────▶ Supabase   │
│     └─────────────┘                                                  │
│                                                                      │
│  5. ORDERS (check by invoice_no)                                    │
│     ┌─────────────┐  ── check cloud ─▶ exists? skip                 │
│     │ Local       │                    not exists? insert           │
│     │ orders      │  ───── map outlet_id & customer_id ──▶ Supabase│
│     └─────────────┘                                                  │
│                                                                      │
│  6. ORDER_ITEMS (with service_id lookup)                            │
│     ┌─────────────┐                                                  │
│     │ Local       │  ── lookup service remote_id ──▶ Supabase      │
│     │ order_items │  ── fallback: find by name ────▶               │
│     └─────────────┘                                                  │
│                                                                      │
│  7. PAYMENTS                                                         │
│     ┌─────────────┐                    ┌─────────────┐              │
│     │ Local       │  ── map order_id ─▶│ Supabase    │              │
│     │ payments    │                    │ payments    │              │
│     └─────────────┘                    └─────────────┘              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Kode Backup Service

```dart
// lib/core/services/restore_service.dart

Future<BackupResult> backupToCloud() async {
  final logBuffer = StringBuffer();
  void log(String message) {
    debugPrint(message);
    logBuffer.writeln(message);
  }

  log('=== STARTING BACKUP ===');

  // 1. Sync outlets - build outletIdMap
  final outletIdMap = <String, String>{}; // local_id -> remote_id

  for (final localOutlet in localOutlets) {
    final localId = localOutlet['id'].toString();

    // Check if outlet exists in cloud
    final existing = await _supabase.client
        .from('outlets')
        .select('id')
        .eq('owner_id', userId)
        .eq('name', localOutlet['name'])
        .maybeSingle();

    String cloudId;
    if (existing != null) {
      cloudId = existing['id'];
      log('Outlet "${localOutlet['name']}" already exists: $cloudId');
    } else {
      final result = await _supabase.client
          .from('outlets')
          .insert({
            'name': localOutlet['name'],
            'address': localOutlet['address'],
            'phone': localOutlet['phone'],
            'invoice_prefix': localOutlet['invoice_prefix'],
            'owner_id': userId,
          })
          .select('id')
          .single();
      cloudId = result['id'];
      log('Created outlet "${localOutlet['name']}": $cloudId');
    }

    outletIdMap[localId] = cloudId;

    // Update local outlet with remote_id
    await db.update('outlets',
      {'remote_id': cloudId},
      where: 'id = ?',
      whereArgs: [int.parse(localId)],
    );
  }

  // 2. Upload app_settings per outlet (from outlets table data)
  for (final localOutlet in localOutlets) {
    final localOutletId = localOutlet['id'].toString();
    final cloudOutletId = outletIdMap[localOutletId];

    final settings = {
      'laundry_name': localOutlet['name'],
      'laundry_address': localOutlet['address'] ?? '',
      'laundry_phone': localOutlet['phone'] ?? '',
      'invoice_prefix': localOutlet['invoice_prefix'] ?? 'INV',
    };

    for (final entry in settings.entries) {
      await _supabase.client.from('app_settings').upsert({
        'outlet_id': cloudOutletId,
        'key': entry.key,
        'value': entry.value,
      }, onConflict: 'outlet_id,key');
    }
    log('Uploaded settings for outlet $cloudOutletId');
  }

  // 3. Upload customers (check by phone first)
  for (final customer in localCustomers) {
    final localOutletId = customer['outlet_id']?.toString();
    final cloudOutletId = outletIdMap[localOutletId] ?? defaultOutletId;

    // Check if customer exists by phone
    final phone = customer['phone'] as String?;
    if (phone != null && phone.isNotEmpty) {
      final existing = await _supabase.client
          .from('customers')
          .select('id')
          .eq('outlet_id', cloudOutletId)
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        log('Customer "${customer['name']}" already exists, skipping');
        continue;
      }
    }

    await _supabase.client.from('customers').insert({
      'outlet_id': cloudOutletId,
      'name': customer['name'],
      'phone': customer['phone'],
      'address': customer['address'],
    });
    log('Uploaded customer: ${customer['name']}');
  }

  // 4-7. Similar pattern for services, orders, order_items, payments...

  log('=== BACKUP COMPLETED ===');

  return BackupResult(
    success: true,
    message: 'Backup berhasil',
    logs: logBuffer.toString(),
  );
}
```

### Order Items dengan Service ID Lookup

```dart
// Upload order_items with service_id mapping
for (final item in localOrderItems) {
  final localOrderId = item['order_id'] as int;
  final remoteOrderId = orderIdMap[localOrderId];

  if (remoteOrderId == null) continue;

  // Get service_id
  String? remoteServiceId;
  final localServiceId = item['service_id'] as int?;

  if (localServiceId != null) {
    // Try to get from local DB
    final serviceResult = await db.query('services',
      columns: ['remote_id'],
      where: 'id = ?',
      whereArgs: [localServiceId],
    );

    if (serviceResult.isNotEmpty) {
      remoteServiceId = serviceResult.first['remote_id'] as String?;
    }
  }

  // Fallback: find service by name in cloud
  if (remoteServiceId == null) {
    final serviceName = item['service_name'] as String;
    final orderOutletId = /* get from order */;

    final existing = await _supabase.client
        .from('services')
        .select('id')
        .eq('outlet_id', orderOutletId)
        .eq('name', serviceName)
        .maybeSingle();

    if (existing != null) {
      remoteServiceId = existing['id'] as String;
    }
  }

  await _supabase.client.from('order_items').insert({
    'order_id': remoteOrderId,
    'service_id': remoteServiceId,  // Can be null if not found
    'service_name': item['service_name'],
    'quantity': item['quantity'],
    'unit': item['unit'],
    'price_per_unit': item['price_per_unit'],
    'subtotal': item['subtotal'],
  });
}
```

---

## 5. Restore dari Cloud

### Alur Restore Multi-Outlet

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RESTORE PROCESS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. FETCH ALL DATA FROM SUPABASE                                    │
│     - outlets (where owner_id = current_user)                       │
│     - customers, services, orders, etc. (via RLS)                   │
│                                                                      │
│  2. CLEAR LOCAL DATA (optional - based on user choice)              │
│                                                                      │
│  3. INSERT OUTLETS                                                   │
│     ┌─────────────┐                    ┌─────────────┐              │
│     │ Supabase    │  ─── insert ────▶  │ Local       │              │
│     │ outlets     │                    │ outlets     │              │
│     └─────────────┘                    └─────────────┘              │
│           │                                  │                       │
│           ▼ Build remoteToLocalMap          ▼                       │
│     {"uuid-1": 1, "uuid-2": 2}                                      │
│                                                                      │
│  4. INSERT CUSTOMERS (map outlet_id)                                │
│     cloud.outlet_id (UUID) ──▶ local outlet.id (INT)                │
│                                                                      │
│  5. INSERT SERVICES (map outlet_id)                                 │
│                                                                      │
│  6. INSERT ORDERS (map outlet_id & customer_id)                     │
│                                                                      │
│  7. INSERT ORDER_ITEMS (map order_id & service_id)                  │
│                                                                      │
│  8. INSERT PAYMENTS (map order_id)                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Kode Restore Service

```dart
Future<void> restoreFromCloud() async {
  final userId = _supabase.currentUser!.id;
  final db = await _dbHelper.database;

  // 1. Fetch all outlets owned by user
  final cloudOutlets = await _supabase.client
      .from('outlets')
      .select()
      .eq('owner_id', userId);

  // 2. Clear local data (optional)
  await db.delete('payments');
  await db.delete('order_items');
  await db.delete('orders');
  await db.delete('services');
  await db.delete('customers');
  await db.delete('outlets');

  // 3. Insert outlets & build mapping
  final remoteToLocalOutletMap = <String, int>{};

  for (final outlet in cloudOutlets) {
    final localId = await db.insert('outlets', {
      'remote_id': outlet['id'],
      'name': outlet['name'],
      'address': outlet['address'],
      'phone': outlet['phone'],
      'invoice_prefix': outlet['invoice_prefix'],
      'owner_id': outlet['owner_id'],
    });
    remoteToLocalOutletMap[outlet['id']] = localId;
  }

  // 4. Fetch & insert customers
  final cloudCustomers = await _supabase.client
      .from('customers')
      .select();

  final remoteToLocalCustomerMap = <String, int>{};

  for (final customer in cloudCustomers) {
    final remoteOutletId = customer['outlet_id'] as String;
    final localOutletId = remoteToLocalOutletMap[remoteOutletId];

    if (localOutletId == null) continue;

    final localId = await db.insert('customers', {
      'remote_id': customer['id'],
      'outlet_id': localOutletId.toString(),
      'name': customer['name'],
      'phone': customer['phone'],
      'address': customer['address'],
    });
    remoteToLocalCustomerMap[customer['id']] = localId;
  }

  // 5-8. Similar pattern for services, orders, order_items, payments...
}
```

---

## 6. Auto-Sync Order Baru

### Alur Auto-Sync saat Order Dibuat

```
┌─────────────────────────────────────────────────────────────────────┐
│                     AUTO-SYNC NEW ORDER                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  User creates order                                                  │
│        │                                                             │
│        ▼                                                             │
│  ┌─────────────┐                                                    │
│  │ Save to     │  ◀── Transaction                                   │
│  │ SQLite      │      - Insert order                                │
│  │             │      - Insert order_items                          │
│  │             │      - Insert payment (if any)                     │
│  └──────┬──────┘                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────────────────────────────────┐                        │
│  │ Queue for Sync                           │                        │
│  │ ─────────────────────────────────────── │                        │
│  │ 1. Queue customer (with local_outlet_id) │                        │
│  │ 2. Queue order (with local_outlet_id,    │                        │
│  │    local_customer_id)                    │                        │
│  │ 3. Queue order_items (with local_order_id│                        │
│  │    local_service_id)                     │                        │
│  └──────┬──────────────────────────────────┘                        │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────┐                                                    │
│  │ SyncService │  ◀── Triggered if online                           │
│  │ .syncAll()  │                                                    │
│  └──────┬──────┘                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────────────────────────────────┐                        │
│  │ Process Sync Queue                       │                        │
│  │ ─────────────────────────────────────── │                        │
│  │ For each item:                           │                        │
│  │ 1. Map local_outlet_id → cloud outlet_id │                        │
│  │ 2. Map local_customer_id → cloud cust_id │                        │
│  │ 3. Map local_service_id → cloud serv_id  │                        │
│  │ 4. Insert to Supabase                    │                        │
│  │ 5. Update local record with remote_id    │                        │
│  └─────────────────────────────────────────┘                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Kode Queue Order untuk Sync

```dart
// lib/data/repositories/order_repository.dart

Future<void> _queueOrderForSync(
  Order order,
  List<OrderItem> items,
  int? customerId,
) async {
  // Get outlet_id from local order
  final db = await _databaseHelper.database;
  final localOrder = await db.query('orders',
    columns: ['outlet_id'],
    where: 'id = ?',
    whereArgs: [order.id],
  );
  final localOutletId = localOrder.first['outlet_id'] as String?;

  // Queue customer first (with outlet_id)
  if (customerId != null) {
    final customer = await _customerRepository.getCustomerById(customerId);
    if (customer != null) {
      await SyncService.instance.queueForSync(
        table: 'customers',
        localId: customerId,
        action: SyncAction.insert,
        data: {
          'name': customer.name,
          'phone': customer.phone,
          'local_id': customerId,
          'local_outlet_id': localOutletId,  // IMPORTANT!
        },
      );
    }
  }

  // Queue order
  await SyncService.instance.queueForSync(
    table: 'orders',
    localId: order.id!,
    action: SyncAction.insert,
    data: {
      'invoice_no': order.invoiceNo,
      'customer_name': order.customerName,
      'total_price': order.totalPrice,
      'local_id': order.id,
      'local_customer_id': customerId,
      'local_outlet_id': localOutletId,  // IMPORTANT!
    },
  );

  // Queue order items (with service_id)
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
        'local_service_id': item.serviceId,  // IMPORTANT!
      },
    );
  }
}
```

### Kode Sync Service untuk Order Items

```dart
// lib/core/services/sync_service.dart

case 'order_items':
  final localOrderId = data['local_order_id'] as int?;
  final localServiceId = data['local_service_id'] as int?;
  data.remove('local_order_id');
  data.remove('local_service_id');

  // Get remote order_id
  String? remoteOrderId;
  if (localOrderId != null) {
    remoteOrderId = orderIdMap[localOrderId] ??
        await _getRemoteOrderId(localOrderId);
  }

  // Get remote service_id
  String? remoteServiceId;

  // First, get order's outlet_id for correct service lookup
  String? orderOutletId = outletId;
  if (localOrderId != null) {
    final orderData = await _local.rawQuery(
      'SELECT outlet_id FROM orders WHERE id = ?',
      [localOrderId],
    );
    if (orderData.isNotEmpty) {
      final localOutletIdStr = orderData.first['outlet_id'] as String?;
      if (localOutletIdStr != null) {
        final outletData = await _local.rawQuery(
          'SELECT remote_id FROM outlets WHERE id = ?',
          [int.tryParse(localOutletIdStr) ?? 0],
        );
        if (outletData.isNotEmpty) {
          orderOutletId = outletData.first['remote_id'] as String?;
        }
      }
    }
  }

  // Try to get service remote_id from local DB
  if (localServiceId != null) {
    final serviceData = await _local.rawQuery(
      'SELECT remote_id FROM services WHERE id = ?',
      [localServiceId],
    );
    if (serviceData.isNotEmpty) {
      remoteServiceId = serviceData.first['remote_id'] as String?;
    }
  }

  // Fallback: find service by name in Supabase
  if (remoteServiceId == null) {
    final serviceName = data['service_name'] as String?;
    if (serviceName != null && orderOutletId != null) {
      final existing = await _supabase.client
          .from('services')
          .select('id')
          .eq('outlet_id', orderOutletId)
          .eq('name', serviceName)
          .maybeSingle();

      if (existing != null) {
        remoteServiceId = existing['id'] as String;

        // Update local service for future syncs
        if (localServiceId != null) {
          await _local.rawExecute(
            'UPDATE services SET remote_id = ? WHERE id = ?',
            [remoteServiceId, localServiceId],
          );
        }
      }
    }
  }

  // Insert to Supabase
  if (remoteOrderId != null) {
    data['order_id'] = remoteOrderId;
    data['service_id'] = remoteServiceId;
    await _supabase.insert(table, data);
  }
  break;
```

---

## 7. ID Mapping Strategy

### Local ID vs Remote ID

```
┌─────────────────────────────────────────────────────────────────────┐
│                      ID MAPPING STRATEGY                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  LOCAL (SQLite)                     REMOTE (Supabase)               │
│  ═════════════                     ══════════════════               │
│                                                                      │
│  outlets                                                             │
│  ┌────┬───────────────────────────────┬───────────────────────┐    │
│  │ id │ remote_id                     │ name                  │    │
│  ├────┼───────────────────────────────┼───────────────────────┤    │
│  │ 1  │ 550e8400-e29b-41d4-a716-...   │ Laundry Pusat        │    │
│  │ 2  │ 6fa459ea-ee8a-3ca4-894e-...   │ Laundry Cabang       │    │
│  └────┴───────────────────────────────┴───────────────────────┘    │
│                                                                      │
│  customers                                                           │
│  ┌────┬───────────────────────────────┬───────────┬──────────┐     │
│  │ id │ remote_id                     │ outlet_id │ name     │     │
│  ├────┼───────────────────────────────┼───────────┼──────────┤     │
│  │ 1  │ a1b2c3d4-...                  │ 1         │ Rina     │     │
│  │ 2  │ e5f6g7h8-...                  │ 2         │ Sari     │     │
│  └────┴───────────────────────────────┴───────────┴──────────┘     │
│         ▲                                   ▲                       │
│         │                                   │                       │
│         │ remote_id diisi setelah sync     │ outlet_id = local int │
│         │                                   │                       │
│                                                                      │
│  MAPPING SAAT SYNC:                                                 │
│  ──────────────────                                                 │
│  local outlet_id (1) ──▶ lookup outlets.remote_id ──▶ UUID         │
│  local customer_id (1) ──▶ lookup customers.remote_id ──▶ UUID     │
│  local service_id (5) ──▶ lookup services.remote_id ──▶ UUID       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Maps yang Digunakan saat Sync

```dart
// Di SyncService._pushLocalChanges()

// Map local outlet_id → remote outlet_id
final outletIdMap = <String, String>{};
for (final outlet in localOutlets) {
  outletIdMap[outlet['id'].toString()] = outlet['remote_id'];
}

// Map local customer_id → remote customer_id (built during sync)
final customerIdMap = <int, String>{};

// Map local order_id → remote order_id (built during sync)
final orderIdMap = <int, String>{};
```

---

## 8. Debug Tools

### Cek Data Lokal

Fitur untuk melihat semua data di local database:

```dart
// lib/core/services/restore_service.dart

Future<String> getDebugLocalData() async {
  final db = await _dbHelper.database;
  final buffer = StringBuffer();

  // Outlets
  buffer.writeln('=== OUTLETS ===');
  final outlets = await db.query('outlets');
  for (final o in outlets) {
    buffer.writeln('id: ${o['id']}, remote_id: ${o['remote_id']}, '
        'name: ${o['name']}, prefix: ${o['invoice_prefix']}');
  }

  // Customers
  buffer.writeln('\n=== CUSTOMERS ===');
  final customers = await db.query('customers');
  for (final c in customers) {
    buffer.writeln('id: ${c['id']}, outlet_id: ${c['outlet_id']}, '
        'remote_id: ${c['remote_id']}, name: ${c['name']}');
  }

  // Services
  buffer.writeln('\n=== SERVICES ===');
  final services = await db.query('services');
  for (final s in services) {
    buffer.writeln('id: ${s['id']}, outlet_id: ${s['outlet_id']}, '
        'remote_id: ${s['remote_id']}, name: ${s['name']}');
  }

  // Orders
  buffer.writeln('\n=== ORDERS ===');
  final orders = await db.query('orders');
  for (final o in orders) {
    buffer.writeln('id: ${o['id']}, outlet_id: ${o['outlet_id']}, '
        'remote_id: ${o['remote_id']}, invoice: ${o['invoice_no']}');
  }

  return buffer.toString();
}
```

### Fix Outlet ID Lokal

Fungsi untuk memperbaiki outlet_id yang tersimpan sebagai UUID alih-alih local int:

```dart
Future<String> fixLocalOutletIds() async {
  final db = await _dbHelper.database;
  final buffer = StringBuffer();

  // Build mapping remote_id → local_id
  final outlets = await db.query('outlets');
  final remoteToLocalMap = <String, int>{};
  for (final outlet in outlets) {
    final localId = outlet['id'] as int;
    final remoteId = outlet['remote_id'] as String?;
    if (remoteId != null) {
      remoteToLocalMap[remoteId] = localId;
    }
  }

  // Fix customers
  final customers = await db.query('customers');
  for (final c in customers) {
    final outletId = c['outlet_id']?.toString();
    if (outletId != null && outletId.contains('-')) {
      // It's a UUID, need to convert
      final localOutletId = remoteToLocalMap[outletId];
      if (localOutletId != null) {
        await db.update('customers',
          {'outlet_id': localOutletId.toString()},
          where: 'id = ?',
          whereArgs: [c['id']],
        );
        buffer.writeln('Fixed customer ${c['id']}: $outletId → $localOutletId');
      }
    }
  }

  // Similar for services, orders...

  return buffer.toString();
}
```

### UI Debug Buttons

```dart
// Di online_settings_screen.dart

// Debug: Cek Data Lokal
OutlinedButton.icon(
  onPressed: () async {
    final data = await BackupRestoreService.instance.getDebugLocalData();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Data Lokal'),
        content: SingleChildScrollView(
          child: SelectableText(data, style: TextStyle(fontSize: 10)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data disalin ke clipboard')),
              );
            },
            child: Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  },
  icon: Icon(Icons.bug_report),
  label: Text('Debug: Cek Data Lokal'),
),

// Fix: Perbaiki Outlet ID
OutlinedButton.icon(
  onPressed: () async {
    final result = await BackupRestoreService.instance.fixLocalOutletIds();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Fix Result'),
        content: SingleChildScrollView(
          child: SelectableText(result),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  },
  icon: Icon(Icons.build),
  label: Text('Fix: Perbaiki Outlet ID Lokal'),
),
```

---

## 9. Troubleshooting

### Error: RLS Policy Violation

```
PostgrestException: new row violates row-level security policy
```

**Penyebab:** RLS policy belum diupdate untuk multi-outlet.

**Solusi:** Jalankan migration `002_multi_outlet_rls.sql`

### Error: service_id NULL di order_items

**Penyebab:**
1. `local_service_id` tidak di-queue saat order dibuat
2. Service tidak punya `remote_id` di local DB
3. Service tidak ditemukan di Supabase by name

**Solusi:**
1. Pastikan queue order_items menyertakan `local_service_id`
2. Backup services dulu sebelum backup orders
3. Cek nama service sama persis (case-sensitive)

### Error: outlet_id tidak konsisten (UUID vs INT)

**Penyebab:** Data lama tersimpan dengan UUID outlet_id dari cloud.

**Solusi:** Jalankan fungsi `fixLocalOutletIds()` dari debug menu.

### Data tidak muncul setelah restore

**Penyebab:**
1. Outlet tidak ter-restore dengan benar
2. outlet_id mapping gagal

**Solusi:**
1. Cek debug data lokal
2. Pastikan outlets ter-restore terlebih dahulu
3. Cek mapping remoteToLocalOutletMap

### Backup log menunjukkan "skipped"

**Penyebab:** Data sudah ada di cloud (deduplicated by phone/invoice_no).

**Ini normal** - backup service mengecek duplikat untuk mencegah data ganda.

---

## Kesimpulan

Multi-outlet backup & restore memerlukan:

1. **ID Mapping** - Local INT ↔ Remote UUID
2. **Outlet-aware RLS** - Owner akses semua, kasir satu outlet
3. **Per-outlet data** - Setiap tabel filter by outlet_id
4. **Debug tools** - Untuk troubleshooting ID inconsistencies
5. **Logging** - Backup log untuk tracking proses

### Checklist Implementation

- [x] Update RLS policies untuk multi-outlet
- [x] Backup outlets dengan outletIdMap
- [x] Backup data per outlet
- [x] service_id lookup untuk order_items
- [x] Restore dengan ID mapping
- [x] Auto-sync dengan local_outlet_id
- [x] Debug tools (cek data, fix outlet ID)
- [x] Backup logging dengan copy button
