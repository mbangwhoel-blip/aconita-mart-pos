import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aconita_mart_pos/core/theme/app_theme.dart';
import 'package:aconita_mart_pos/core/services/sync_service.dart';
import 'package:aconita_mart_pos/data/database/database_helper.dart';
import 'package:aconita_mart_pos/presentation/screens/pos_screen.dart';

class MartDashboardScreen extends StatefulWidget {
  const MartDashboardScreen({super.key});

  @override
  State<MartDashboardScreen> createState() => _MartDashboardScreenState();
}

class _MartDashboardScreenState extends State<MartDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService _sync = SyncService.instance;
  final NumberFormat _curr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Map<String, dynamic> _stats = {
    'today_revenue': 0.0,
    'today_orders': 0,
    'today_profit': 0.0,
    'unsynced_count': 0,
    'product_count': 0,
  };
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _initSync();
  }

  Future<void> _initSync() async {
    await _sync.initialize();
    _sync.startPeriodicSync();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _db.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memulai sinkronisasi dengan Backend Laravel...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final res = await _sync.performFullSync();
      if (mounted) {
        final isSuccess = res['success'] == true;
        final msg = (res['message'] as String?) ?? 'Selesai sinkronisasi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            content: Text(msg),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Sync gagal: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsynced = _stats['unsynced_count'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACONITA MART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Koperasi Simpan Pinjam & Konsumen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Data',
            onPressed: _isSyncing ? null : _triggerSync,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Sync Status
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: unsynced > 0 ? Colors.amber.shade300 : Colors.green.shade200,
                        ),
                      ),
                      color: unsynced > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              unsynced > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                              color: unsynced > 0 ? Colors.amber.shade800 : Colors.green.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unsynced > 0
                                        ? '$unsynced transaksi belum tersinkron ke cloud'
                                        : 'Semua data tersinkron dengan Backend Laravel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: unsynced > 0 ? Colors.amber.shade900 : Colors.green.shade900,
                                    ),
                                  ),
                                  Text(
                                    _sync.lastSyncTime != null
                                        ? 'Sync terakhir: ${DateFormat('HH:mm, dd MMM').format(_sync.lastSyncTime!)}'
                                        : 'Tekan tombol sync untuk sinkronisasi pertama',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _isSyncing ? null : _triggerSync,
                              child: Text(_isSyncing ? 'Proses...' : 'Sync'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Omset Hari Ini',
                            _curr.format(_stats['today_revenue']),
                            Icons.payments_outlined,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Transaksi Hari Ini',
                            '${_stats['today_orders']} Struk',
                            Icons.receipt_long_outlined,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Laba Kotor (SHU)',
                            _curr.format(_stats['today_profit']),
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Katalog Produk',
                            '${_stats['product_count']} Barang',
                            Icons.inventory_2_outlined,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Action Button - Open POS
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.point_of_sale, size: 28),
                        label: const Text('BUKA KASIR POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PosScreen()),
                          ).then((_) => _loadStats());
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Menu Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Menu Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildMenuCard('Kasir POS', Icons.shopping_cart_checkout, Colors.blue, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())).then((_) => _loadStats());
                        }),
                        _buildMenuCard('Produk & Stok', Icons.inventory, Colors.orange, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelola produk juga dapat melalui Web Admin Filament')));
                        }),
                        _buildMenuCard('Anggota Koperasi', Icons.group, Colors.teal, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master Anggota dikelola via Web Admin Filament')));
                        }),
                        _buildMenuCard('Sinkronisasi Cloud', Icons.cloud_sync, Colors.indigo, _triggerSync),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, size: 16, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, size: 24, color: color)),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
