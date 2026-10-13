import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aconita_mart_pos/core/services/api_service.dart';
import 'package:aconita_mart_pos/data/database/database_helper.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ApiService _api = ApiService.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _isOnline = !connectivity.contains(ConnectivityResult.none);

    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      if (!wasOnline && _isOnline) {
        // Auto-sync when coming back online
        performFullSync();
      }
    });
  }

  /// Perform bidirectional synchronization:
  /// 1. Upload offline orders to Laravel MySQL (Sync Up)
  /// 2. Download latest products & members from Laravel MySQL to SQLite (Sync Down)
  Future<Map<String, dynamic>> performFullSync() async {
    if (_status == SyncStatus.syncing) {
      return {'success': false, 'message': 'Sinkronisasi sedang berjalan'};
    }

    _status = SyncStatus.syncing;
    _statusController.add(_status);
    _lastError = null;

    try {
      // Step 1: Sync Up (Upload offline orders)
      final unsyncedOrders = await _db.getUnsyncedOrdersForUpload();
      int uploadedCount = 0;

      if (unsyncedOrders.isNotEmpty) {
        final upResult = await _api.syncUp(unsyncedOrders);
        if (upResult['success'] == true) {
          uploadedCount = upResult['synced_count'] ?? 0;
          final syncedNos = List<String>.from(upResult['synced_orders'] ?? []);
          await _db.markOrdersAsSynced(syncedNos);
        } else {
          debugPrint('Sync Up Warning: ${upResult['message']}');
        }
      }

      // Step 2: Sync Down (Fetch catalog from Laravel)
      final downResult = await _api.syncDown();
      if (downResult['success'] == true && downResult['data'] != null) {
        await _db.upsertDownloadedCatalog(downResult['data']);
      } else {
        throw Exception(downResult['message'] ?? 'Gagal mengunduh data dari server');
      }

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.success;
      _statusController.add(_status);

      return {
        'success': true,
        'message': 'Sinkronisasi berhasil! $uploadedCount transaksi terkirim, katalog diperbarui.',
        'uploaded_count': uploadedCount,
      };
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      _statusController.add(_status);
      return {'success': false, 'message': 'Gagal sinkronisasi: $e'};
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        if (_status == SyncStatus.success || _status == SyncStatus.error) {
          _status = SyncStatus.idle;
          _statusController.add(_status);
        }
      });
    }
  }
}
