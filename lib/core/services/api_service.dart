import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

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
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
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

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get(uri, headers: _headers()).timeout(
      const Duration(seconds: 15),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(data),
    ).timeout(
      const Duration(seconds: 25),
    );
    return _handleResponse(response);
  }

  Future<dynamic> syncDown() async {
    return get('/sync/down');
  }

  Future<dynamic> syncUp(dynamic payload) async {
    if (payload is List) {
      return post('/sync/up', {'orders': payload});
    } else if (payload is Map<String, dynamic>) {
      return post('/sync/up', payload);
    }
    return post('/sync/up', {'orders': []});
  }

  dynamic _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final msg = body is Map && body['message'] != null
          ? body['message']
          : 'Server Error (${res.statusCode})';
      throw Exception(msg);
    }
  }
}
