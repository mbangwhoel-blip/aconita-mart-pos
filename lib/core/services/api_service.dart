import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _defaultUrl = 'http://10.0.2.2:8000/api';
  static const String _fallbackUrl = 'http://127.0.0.1:8000/api';
  static const String _laragonUrl = 'http://aconita-mart.test/api';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyToken = 'api_token';

  String _baseUrl = _laragonUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? _laragonUrl;
    _token = prefs.getString(_keyToken);
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_keyToken, token);
    } else {
      await prefs.remove(_keyToken);
    }
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Test server connectivity
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (_) {
      // Try fallback URL if on desktop
      if (_baseUrl != _fallbackUrl) {
        try {
          final resFallback = await http
              .get(Uri.parse('$_fallbackUrl/products'), headers: _headers)
              .timeout(const Duration(seconds: 2));
          if (resFallback.statusCode == 200 || resFallback.statusCode == 401) {
            _baseUrl = _fallbackUrl;
            return true;
          }
        } catch (_) {}
      }
      return false;
    }
  }

  /// Login cashier / admin
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        await setToken(token);
        return {'success': true, 'user': data['data']['user'], 'token': token};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghubungi server: $e'};
    }
  }

  /// Sync Down: Fetch all products, categories, members from Laravel MySQL
  Future<Map<String, dynamic>> syncDown() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sync/down'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  /// Sync Up: Upload offline orders queue to Laravel MySQL
  Future<Map<String, dynamic>> syncUp(List<Map<String, dynamic>> orders) async {
    if (orders.isEmpty) return {'success': true, 'synced_count': 0};

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/sync/up'),
            headers: _headers,
            body: jsonEncode({'orders': orders}),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'synced_count': body['synced_count'],
          'synced_orders': body['synced_orders'] ?? [],
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Gagal upload transaksi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error saat upload: $e'};
    }
  }
}
