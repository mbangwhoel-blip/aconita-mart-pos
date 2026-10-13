# Step-by-Step Integrasi Flutter dengan Supabase

## Daftar Isi
1. [Persiapan Supabase](#1-persiapan-supabase)
2. [Setup Project Flutter](#2-setup-project-flutter)
3. [Konfigurasi Environment](#3-konfigurasi-environment)
4. [Initialize Supabase di Flutter](#4-initialize-supabase-di-flutter)
5. [Authentication](#5-authentication)
6. [Database Operations (CRUD)](#6-database-operations-crud)
7. [Row Level Security (RLS)](#7-row-level-security-rls)
8. [Realtime Subscriptions](#8-realtime-subscriptions)

---

## 1. Persiapan Supabase

### Step 1.1: Buat Akun Supabase

1. Buka [https://supabase.com](https://supabase.com)
2. Klik **"Start your project"**
3. Sign up dengan GitHub atau email

### Step 1.2: Buat Project Baru

1. Klik **"New Project"**
2. Isi form:
   - **Name**: `laundry-jagoflutter`
   - **Database Password**: (buat password kuat, simpan!)
   - **Region**: Pilih terdekat (Singapore)
3. Klik **"Create new project"**
4. Tunggu ~2 menit sampai project ready

### Step 1.3: Dapatkan API Keys

1. Setelah project ready, buka **Settings** > **API**
2. Catat 2 nilai ini:
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGciOiJI...
   ```

### Step 1.4: Setup Database Schema

1. Buka **SQL Editor** di sidebar
2. Copy-paste schema SQL dari file `supabase/schema.sql`
3. Klik **Run** untuk execute

```sql
-- Contoh: Membuat tabel customers
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contoh: Membuat tabel orders
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE NOT NULL,
  invoice_no TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  total_price BIGINT NOT NULL,
  paid BIGINT DEFAULT 0,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(outlet_id, invoice_no)
);
```

### Step 1.5: Enable Authentication

1. Buka **Authentication** > **Providers**
2. Pastikan **Email** provider sudah enabled
3. (Opsional) Disable **"Confirm email"** untuk testing:
   - **Authentication** > **Settings** > **Email Auth**
   - Matikan "Enable email confirmations"

---

## 2. Setup Project Flutter

### Step 2.1: Tambah Dependencies

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase SDK
  supabase_flutter: ^2.8.4

  # Environment variables
  flutter_dotenv: ^5.2.1

  # Connectivity monitoring
  connectivity_plus: ^6.1.4
```

Jalankan:
```bash
flutter pub get
```

### Step 2.2: Setup Assets untuk .env

Edit `pubspec.yaml`, tambahkan di bagian `flutter:`:

```yaml
flutter:
  uses-material-design: true

  assets:
    - .env  # Tambahkan ini
```

---

## 3. Konfigurasi Environment

### Step 3.1: Buat File .env

Buat file `.env` di root project:

```env
# Supabase Configuration
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 3.2: Tambahkan .env ke .gitignore

Edit `.gitignore`:

```gitignore
# Environment variables
.env
.env.local
.env.*.local
```

### Step 3.3: Buat .env.example

Untuk dokumentasi, buat `.env.example`:

```env
# Copy this file to .env and fill in your values
SUPABASE_URL=your-supabase-project-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

---

## 4. Initialize Supabase di Flutter

### Step 4.1: Buat Supabase Service

Buat file `lib/core/services/supabase_service.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service untuk Supabase client
class SupabaseService {
  // Private constructor untuk singleton
  SupabaseService._();

  // Instance singleton
  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;

  bool _initialized = false;

  /// Initialize Supabase - panggil di main.dart sebelum runApp()
  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _initialized = true;
  }

  /// Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Check if authenticated
  bool get isAuthenticated => currentUser != null;
}
```

### Step 4.2: Initialize di main.dart

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:your_app/core/services/supabase_service.dart';

void main() async {
  // Wajib untuk async operations sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry App',
      home: const HomeScreen(),
    );
  }
}
```

---

## 5. Authentication

### Step 5.1: Sign Up (Register)

```dart
// Di SupabaseService atau AuthRepository

Future<AuthResponse> signUp({
  required String email,
  required String password,
  String? name,
}) async {
  final response = await client.auth.signUp(
    email: email,
    password: password,
    data: {
      'name': name,  // Metadata yang akan disimpan
    },
  );
  return response;
}
```

### Step 5.2: Sign In (Login)

```dart
Future<AuthResponse> signIn({
  required String email,
  required String password,
}) async {
  final response = await client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  return response;
}
```

### Step 5.3: Sign Out (Logout)

```dart
Future<void> signOut() async {
  await client.auth.signOut();
}
```

### Step 5.4: Listen Auth State Changes

```dart
// Di main.dart atau AuthCubit

void listenAuthChanges() {
  SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    switch (event) {
      case AuthChangeEvent.signedIn:
        print('User signed in: ${session?.user.email}');
        // Navigate to home
        break;
      case AuthChangeEvent.signedOut:
        print('User signed out');
        // Navigate to login
        break;
      case AuthChangeEvent.tokenRefreshed:
        print('Token refreshed');
        break;
      default:
        break;
    }
  });
}
```

### Step 5.5: Contoh Login Screen

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Login sukses
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Database Operations (CRUD)

### Step 6.1: Helper Methods di SupabaseService

Tambahkan di `supabase_service.dart`:

```dart
/// GET ALL - Ambil semua data dari tabel
Future<List<Map<String, dynamic>>> getAll(String table) async {
  final response = await client.from(table).select();
  return List<Map<String, dynamic>>.from(response);
}

/// GET BY ID - Ambil satu record
Future<Map<String, dynamic>?> getById(String table, String id) async {
  final response = await client
      .from(table)
      .select()
      .eq('id', id)
      .maybeSingle();
  return response;
}

/// INSERT - Tambah data baru
Future<Map<String, dynamic>> insert(
  String table,
  Map<String, dynamic> data,
) async {
  final response = await client
      .from(table)
      .insert(data)
      .select()
      .single();
  return response;
}

/// UPDATE - Update data
Future<Map<String, dynamic>> update(
  String table,
  String id,
  Map<String, dynamic> data,
) async {
  final response = await client
      .from(table)
      .update(data)
      .eq('id', id)
      .select()
      .single();
  return response;
}

/// DELETE - Hapus data
Future<void> delete(String table, String id) async {
  await client.from(table).delete().eq('id', id);
}

/// UPSERT - Insert atau Update
Future<Map<String, dynamic>> upsert(
  String table,
  Map<String, dynamic> data,
) async {
  final response = await client
      .from(table)
      .upsert(data)
      .select()
      .single();
  return response;
}
```

### Step 6.2: Contoh Repository

Buat `lib/data/repositories/customer_repository.dart`:

```dart
import 'package:your_app/core/services/supabase_service.dart';
import 'package:your_app/data/models/customer.dart';

class CustomerRepository {
  final _supabase = SupabaseService.instance;

  /// Get all customers for current outlet
  Future<List<Customer>> getAllCustomers() async {
    final response = await _supabase.client
        .from('customers')
        .select()
        .order('name');

    return response.map((json) => Customer.fromJson(json)).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final response = await _supabase.client
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Customer.fromJson(response);
  }

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query) async {
    final response = await _supabase.client
        .from('customers')
        .select()
        .or('name.ilike.%$query%,phone.ilike.%$query%')
        .order('name');

    return response.map((json) => Customer.fromJson(json)).toList();
  }

  /// Create new customer
  Future<Customer> createCustomer(Customer customer) async {
    final response = await _supabase.client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();

    return Customer.fromJson(response);
  }

  /// Update customer
  Future<Customer> updateCustomer(Customer customer) async {
    final response = await _supabase.client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id)
        .select()
        .single();

    return Customer.fromJson(response);
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    await _supabase.client
        .from('customers')
        .delete()
        .eq('id', id);
  }
}
```

### Step 6.3: Query dengan Filter

```dart
// Filter dengan berbagai kondisi
final response = await client
    .from('orders')
    .select()
    .eq('status', 'pending')                    // WHERE status = 'pending'
    .gte('total_price', 100000)                 // AND total_price >= 100000
    .lte('created_at', DateTime.now())          // AND created_at <= now
    .order('created_at', ascending: false)      // ORDER BY created_at DESC
    .limit(10);                                 // LIMIT 10

// Filter dengan IN
final response = await client
    .from('orders')
    .select()
    .in_('status', ['pending', 'process']);     // WHERE status IN (...)

// Filter dengan LIKE
final response = await client
    .from('customers')
    .select()
    .ilike('name', '%john%');                   // WHERE name ILIKE '%john%'

// Filter dengan OR
final response = await client
    .from('customers')
    .select()
    .or('name.ilike.%$query%,phone.ilike.%$query%');

// Join tables (select with relations)
final response = await client
    .from('orders')
    .select('''
      *,
      customer:customers(name, phone),
      items:order_items(*)
    ''');
```

---

## 7. Row Level Security (RLS)

### Apa itu RLS?

Row Level Security adalah fitur PostgreSQL yang membatasi akses data di level baris berdasarkan policy yang ditentukan.

### Step 7.1: Enable RLS

```sql
-- Enable RLS pada tabel
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
```

### Step 7.2: Buat Policy

```sql
-- Policy: User hanya bisa lihat data outlet sendiri
CREATE POLICY "Users can view own outlet customers"
ON customers
FOR SELECT
USING (
  outlet_id IN (
    SELECT outlet_id FROM profiles WHERE id = auth.uid()
  )
);

-- Policy: User bisa manage data outlet sendiri
CREATE POLICY "Users can manage own outlet customers"
ON customers
FOR ALL
USING (
  outlet_id IN (
    SELECT outlet_id FROM profiles WHERE id = auth.uid()
  )
);
```

### Step 7.3: Policy untuk Orders

```sql
-- User hanya bisa akses orders dari outlet mereka
CREATE POLICY "Users can view outlet orders"
ON orders
FOR SELECT
USING (
  outlet_id IN (
    SELECT outlet_id FROM profiles WHERE id = auth.uid()
  )
);

CREATE POLICY "Users can manage outlet orders"
ON orders
FOR ALL
USING (
  outlet_id IN (
    SELECT outlet_id FROM profiles WHERE id = auth.uid()
  )
);
```

### Keuntungan RLS

1. **Security di Database Level** - Tidak bisa di-bypass dari client
2. **Otomatis Applied** - Setiap query otomatis difilter
3. **Centralized** - Satu tempat untuk semua security rules
4. **Audit Trail** - Mudah di-audit

---

## 8. Realtime Subscriptions

### Step 8.1: Subscribe ke Perubahan Tabel

```dart
// Di SupabaseService
RealtimeChannel subscribeToTable(
  String table, {
  required void Function(PostgresChangePayload payload) onInsert,
  required void Function(PostgresChangePayload payload) onUpdate,
  required void Function(PostgresChangePayload payload) onDelete,
}) {
  return client
      .channel('public:$table')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        callback: onInsert,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      )
      .subscribe();
}

// Unsubscribe
Future<void> unsubscribe(RealtimeChannel channel) async {
  await client.removeChannel(channel);
}
```

### Step 8.2: Contoh Penggunaan di Cubit

```dart
class OrderCubit extends Cubit<OrderState> {
  RealtimeChannel? _subscription;

  void subscribeToOrders() {
    _subscription = SupabaseService.instance.subscribeToTable(
      'orders',
      onInsert: (payload) {
        // Order baru ditambahkan
        final newOrder = Order.fromJson(payload.newRecord);
        final currentOrders = (state as OrderLoaded).orders;
        emit(OrderLoaded(orders: [newOrder, ...currentOrders]));
      },
      onUpdate: (payload) {
        // Order diupdate
        final updatedOrder = Order.fromJson(payload.newRecord);
        final currentOrders = (state as OrderLoaded).orders;
        final index = currentOrders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) {
          currentOrders[index] = updatedOrder;
          emit(OrderLoaded(orders: List.from(currentOrders)));
        }
      },
      onDelete: (payload) {
        // Order dihapus
        final deletedId = payload.oldRecord['id'];
        final currentOrders = (state as OrderLoaded).orders;
        currentOrders.removeWhere((o) => o.id == deletedId);
        emit(OrderLoaded(orders: List.from(currentOrders)));
      },
    );
  }

  @override
  Future<void> close() async {
    if (_subscription != null) {
      await SupabaseService.instance.unsubscribe(_subscription!);
    }
    return super.close();
  }
}
```

### Step 8.3: Enable Realtime di Supabase Dashboard

1. Buka **Database** > **Replication**
2. Untuk setiap tabel yang ingin realtime:
   - Klik toggle untuk enable
   - Atau jalankan SQL:
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE orders;
   ALTER PUBLICATION supabase_realtime ADD TABLE customers;
   ```

---

## Checklist Integrasi

- [ ] Buat akun Supabase
- [ ] Buat project baru
- [ ] Catat URL dan anon key
- [ ] Setup database schema
- [ ] Enable Email auth
- [ ] Tambahkan dependencies di Flutter
- [ ] Buat file .env
- [ ] Buat SupabaseService
- [ ] Initialize di main.dart
- [ ] Test authentication
- [ ] Test CRUD operations
- [ ] Setup RLS policies
- [ ] (Opsional) Setup realtime

---

## Troubleshooting

### Error: "Invalid API key"
- Pastikan SUPABASE_ANON_KEY di .env benar
- Pastikan tidak ada spasi atau newline

### Error: "No rows returned"
- Cek RLS policies
- Pastikan user sudah authenticated

### Error: "Permission denied"
- RLS policy belum benar
- User tidak punya akses ke data tersebut

### Realtime tidak berfungsi
- Pastikan tabel sudah di-enable di Replication
- Cek apakah ada error di console

---

## Referensi
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime](https://supabase.com/docs/guides/realtime)
