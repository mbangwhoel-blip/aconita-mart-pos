import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aconita_mart_pos/core/theme/app_theme.dart';
import 'package:aconita_mart_pos/core/services/sync_service.dart';
import 'package:aconita_mart_pos/data/database/database_helper.dart';
import 'package:aconita_mart_pos/presentation/screens/pos/pos_screen.dart';

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
    'member_count': 0,
  };
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _sync.statusStream.listen((status) {
      if (mounted) {
        setState(() => _isSyncing = (status == SyncStatus.syncing));
        if (status == SyncStatus.success) {
          _loadStats();
        }
      }
    });
  }

  Future<void> _loadStats() async {
    final stats = await _db.getDashboardStats();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  Future<void> _triggerSync() async {
    final res = await _sync.performFullSync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? ''),
        backgroundColor: res['success'] == true ? Colors.green : Colors.orange,
      ),
    );
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final unsynced = _stats['unsynced_count'] as int;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Aconita Mart POS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync),
            tooltip: 'Sinkronisasi dengan Backend Laravel',
            onPressed: _isSyncing ? null : _triggerSync,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sync status banner
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.12), child: Icon(icon, size: 16, color: color)),
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
              CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.12), child: Icon(icon, size: 24, color: color)),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}


