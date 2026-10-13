import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aconita_mart_pos/data/models/product.dart';
import 'package:aconita_mart_pos/data/models/member.dart';
import 'package:aconita_mart_pos/data/models/order.dart';
import 'package:aconita_mart_pos/data/models/order_item.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'aconita_mart_pos_v1.db';
  static const int _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE products ADD COLUMN image TEXT');
            await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        name TEXT NOT NULL,
        slug TEXT
      )
    ''');

    // 2. Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        category_id INTEGER,
        barcode TEXT,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image TEXT,
        image_url TEXT,
        unit TEXT DEFAULT 'pcs',
        cost_price REAL DEFAULT 0,
        selling_price REAL NOT NULL,
        member_price REAL,
        stock INTEGER DEFAULT 0,
        min_stock INTEGER DEFAULT 5,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');

    // 3. Members
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        member_no TEXT NOT NULL UNIQUE,
        nik TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        department TEXT,
        savings_balance REAL DEFAULT 0,
        credit_limit REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('CREATE INDEX idx_members_no ON members(member_no)');

    // 4. Orders
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL UNIQUE,
        member_id INTEGER,
        member_name TEXT,
        order_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        payment_status TEXT DEFAULT 'paid',
        total_profit REAL DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_orders_no ON orders(order_no)');
    await db.execute('CREATE INDEX idx_orders_synced ON orders(is_synced)');

    // 5. Order Items
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        cost_price REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        profit REAL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // 6. Settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Seed default offline data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    // Settings
    await db.insert('app_settings', {'key': 'store_name', 'value': 'Aconita Mart'});
    await db.insert('app_settings', {'key': 'store_address', 'value': 'Koperasi Aconita Mart'});
    await db.insert('app_settings', {'key': 'store_phone', 'value': '081234567890'});

    // Categories
    await db.insert('categories', {'remote_id': 1, 'name': 'Sembako & Beras', 'slug': 'sembako-beras'});
    await db.insert('categories', {'remote_id': 2, 'name': 'Minuman & Susu', 'slug': 'minuman-susu'});
    await db.insert('categories', {'remote_id': 3, 'name': 'Makanan Ringan', 'slug': 'makanan-ringan'});

    // Members
    await db.insert('members', {
      'remote_id': 1,
      'member_no': 'MBR-001',
      'name': 'Ahmad Fauzi',
      'department': 'Divisi Keuangan',
      'savings_balance': 750000.0,
      'credit_limit': 1000000.0,
    });
    await db.insert('members', {
      'remote_id': 2,
      'member_no': 'MBR-002',
      'name': 'Siti Rahmawati',
      'department': 'Divisi Operasional',
      'savings_balance': 1200000.0,
      'credit_limit': 1500000.0,
    });

    // Products
    final products = [
      {'barcode': '8991001100111', 'sku': 'SBK-BRS-05', 'name': 'Beras Rojolele 5kg', 'unit': 'sak', 'cost_price': 65000, 'selling_price': 74000, 'member_price': 71000, 'stock': 45},
      {'barcode': '8991001100112', 'sku': 'SBK-MNY-02', 'name': 'Minyak Goreng SunCo 2L', 'unit': 'pouch', 'cost_price': 32000, 'selling_price': 37000, 'member_price': 35500, 'stock': 60},
      {'barcode': '8991001100113', 'sku': 'SBK-GLA-01', 'name': 'Gulaku Tebu 1kg', 'unit': 'kg', 'cost_price': 16000, 'selling_price': 18500, 'member_price': 17500, 'stock': 50},
      {'barcode': '8991002200221', 'sku': 'MNM-AQR-60', 'name': 'Aqua Botol 600ml', 'unit': 'botol', 'cost_price': 2800, 'selling_price': 4000, 'member_price': 3500, 'stock': 120},
      {'barcode': '8991003300331', 'sku': 'MKN-MIE-01', 'name': 'Indomie Goreng 85g', 'unit': 'pcs', 'cost_price': 2800, 'selling_price': 3500, 'member_price': 3200, 'stock': 200},
      {'barcode': '8991003300332', 'sku': 'MKN-BSK-01', 'name': 'Roma Kelapa 300g', 'unit': 'pack', 'cost_price': 10000, 'selling_price': 12500, 'member_price': 11500, 'stock': 35},
    ];

    for (final p in products) {
      await db.insert('products', {
        ...p,
        'category_id': 1,
        'min_stock': 5,
        'is_active': 1,
      });
    }
  }

  // --- CRUD Products ---
  Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    final db = await database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (categoryId != null && categoryId > 0) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final maps = await db.query('products', where: whereClause, whereArgs: whereArgs, orderBy: 'name ASC');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query('products', where: 'barcode = ? AND is_active = 1', whereArgs: [barcode]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  // --- CRUD Members ---
  Future<List<Member>> getMembers({String? search}) async {
    final db = await database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR member_no LIKE ? OR phone LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    final maps = await db.query('members', where: whereClause, whereArgs: whereArgs, orderBy: 'name ASC');
    return maps.map((e) => Member.fromMap(e)).toList();
  }

  // --- Orders & Checkout ---
  Future<Order> createOrder(Order order, List<OrderItem> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Insert order
      final orderId = await txn.insert('orders', order.toMap());

      // 2. Insert items & deduct stock
      for (final item in items) {
        await txn.insert('order_items', item.toMap(orderId));
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      // 3. Deduct member savings if payment is potong_simpanan
      if (order.paymentMethod == 'potong_simpanan' && order.memberId != null) {
        await txn.rawUpdate(
          'UPDATE members SET savings_balance = MAX(0, savings_balance - ?) WHERE id = ?',
          [order.finalAmount, order.memberId],
        );
      }

      return Order.fromMap(
        {...order.toMap(), 'id': orderId},
        items: items,
      );
    });
  }

  Future<List<Order>> getRecentOrders({int limit = 20}) async {
    final db = await database;
    final orderMaps = await db.query('orders', orderBy: 'order_date DESC', limit: limit);
    List<Order> orders = [];
    for (final oMap in orderMaps) {
      final itemMaps = await db.query('order_items', where: 'order_id = ?', whereArgs: [oMap['id']]);
      final items = itemMaps.map((e) => OrderItem.fromMap(e)).toList();
      orders.add(Order.fromMap(oMap, items: items));
    }
    return orders;
  }

  // --- Sync Engine Handlers ---
  Future<List<Map<String, dynamic>>> getUnsyncedOrdersForUpload() async {
    final db = await database;
    final orderMaps = await db.query('orders', where: 'is_synced = 0');
    List<Map<String, dynamic>> result = [];

    for (final oMap in orderMaps) {
      final itemMaps = await db.query('order_items', where: 'order_id = ?', whereArgs: [oMap['id']]);
      final items = itemMaps.map((e) => OrderItem.fromMap(e)).toList();
      final order = Order.fromMap(oMap, items: items);
      result.add(order.toSyncJson());
    }
    return result;
  }

  Future<void> markOrdersAsSynced(List<String> orderNos) async {
    if (orderNos.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final no in orderNos) {
      batch.update('orders', {'is_synced': 1}, where: 'order_no = ?', whereArgs: [no]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertDownloadedCatalog(Map<String, dynamic> data) async {
    final db = await database;
    final batch = db.batch();

    // Upsert Categories
    if (data['categories'] is List) {
      for (final cat in data['categories']) {
        batch.rawInsert('''
          INSERT OR REPLACE INTO categories (remote_id, name, slug)
          VALUES (?, ?, ?)
        ''', [cat['id'], cat['name'], cat['slug']]);
      }
    }

    // Upsert Products
    if (data['products'] is List) {
      for (final p in data['products']) {
        batch.rawInsert('''
          INSERT OR REPLACE INTO products (remote_id, category_id, barcode, sku, name, description, image, image_url, unit, cost_price, selling_price, member_price, stock, min_stock, is_active)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          p['id'],
          p['category_id'],
          p['barcode'],
          p['sku'],
          p['name'],
          p['description'],
          p['image'],
          p['image_url'],
          p['unit'] ?? 'pcs',
          p['cost_price'] ?? 0,
          p['selling_price'] ?? 0,
          p['member_price'],
          p['stock'] ?? 0,
          p['min_stock'] ?? 5,
          (p['is_active'] == true || p['is_active'] == 1) ? 1 : 0,
        ]);
      }
    }

    // Upsert Members
    if (data['members'] is List) {
      for (final m in data['members']) {
        batch.rawInsert('''
          INSERT OR REPLACE INTO members (remote_id, member_no, nik, name, phone, email, department, savings_balance, credit_limit, is_active)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          m['id'],
          m['member_no'],
          m['nik'],
          m['name'],
          m['phone'],
          m['email'],
          m['department'],
          m['savings_balance'] ?? 0,
          m['credit_limit'] ?? 0,
          (m['is_active'] == true || m['is_active'] == 1) ? 1 : 0,
        ]);
      }
    }

    await batch.commit(noResult: true);
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final revenueResult = await db.rawQuery('''
      SELECT SUM(final_amount) as total_revenue, COUNT(*) as total_orders, SUM(total_profit) as total_profit
      FROM orders
      WHERE order_date LIKE ?
    ''', ['$today%']);

    final unsyncedCountResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM orders WHERE is_synced = 0');
    final productCountResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM products WHERE is_active = 1');
    final memberCountResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM members WHERE is_active = 1');

    return {
      'today_revenue': ((revenueResult.first['total_revenue'] ?? 0) as num).toDouble(),
      'today_orders': (revenueResult.first['total_orders'] ?? 0) as int,
      'today_profit': ((revenueResult.first['total_profit'] ?? 0) as num).toDouble(),
      'unsynced_count': (unsyncedCountResult.first['cnt'] ?? 0) as int,
      'product_count': (productCountResult.first['cnt'] ?? 0) as int,
      'member_count': (memberCountResult.first['cnt'] ?? 0) as int,
    };
  }
}
