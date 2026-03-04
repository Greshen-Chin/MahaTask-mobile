import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3001';
      default:
        return 'http://localhost:3001';
    }
  }

  String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultBaseUrl;
  }

  Future<dynamic> get(String endpoint, {bool authenticated = true}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authenticated: authenticated),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authenticated: authenticated),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    bool authenticated = true,
  }) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authenticated: authenticated),
    );
    return _decode(response);
  }

  Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (!authenticated) return headers;

    final token = SessionStore.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Session login tidak ditemukan. Silakan login ulang.');
    }
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception(_message(response.body));
  }

  String _message(String body) {
    if (body.isEmpty) return 'Request gagal. Coba lagi.';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
        if (message is List && message.isNotEmpty) return message.first.toString();
      }
    } catch (_) {}
    return 'Request gagal. Coba lagi.';
  }
}
