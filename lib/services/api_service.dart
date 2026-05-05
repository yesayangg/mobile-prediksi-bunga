import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ApiException(
        'Koneksi ke server terlalu lama. Pastikan backend aktif dan jaringan stabil.',
        408,
      );
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan HP dan laptop berada di jaringan yang sama.',
        0,
      );
    } on http.ClientException {
      throw ApiException(
        'Koneksi ke server gagal. Periksa alamat API dan koneksi jaringan.',
        0,
      );
    } catch (_) {
      throw ApiException(
        'Terjadi gangguan koneksi ke server.',
        0,
      );
    }
  }

  // AUTH
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<void> logout() async {
    try {
      await _sendRequest(
        () async => http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: await _headers(),
        ),
      );
    } finally {
      await clearToken();
    }
  }

  // STOCK
  static Future<Map<String, dynamic>> getStocks({
    String? category,
    String? search,
    bool? lowStockOnly,
  }) async {
    final params = <String, String>{};

    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    if (lowStockOnly == true) params['low_stock'] = '1';

    final uri = Uri.parse('$baseUrl/stocks').replace(queryParameters: params);

    final response = await _sendRequest(
      () async => http.get(uri, headers: await _headers()),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateStock(
    int id,
    int quantity,
    String type,
  ) async {
    final response = await _sendRequest(
      () async => http.patch(
        Uri.parse('$baseUrl/stocks/$id/adjust'),
        headers: await _headers(),
        body: jsonEncode({
          'quantity': quantity,
          'type': type,
        }),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addNewFlower(
    Map<String, dynamic> data,
  ) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/stocks'),
        headers: await _headers(),
        body: jsonEncode(data),
      ),
    );

    return _handleResponse(response);
  }

  // TRANSACTIONS
  static Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: await _headers(),
        body: jsonEncode(data),
      ),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (startDate != null) {
      params['start_date'] = startDate.toIso8601String().split('T')[0];
    }

    if (endDate != null) {
      params['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('$baseUrl/transactions').replace(
      queryParameters: params,
    );

    final response = await _sendRequest(
      () async => http.get(uri, headers: await _headers()),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _sendRequest(
      () async => http.get(
        Uri.parse('$baseUrl/dashboard/summary'),
        headers: await _headers(),
      ),
    );

    return _handleResponse(response);
  }

  // PREDICTIONS
  static Future<dynamic> getPredictions({
    int? flowerId,
    String period = '7days',
  }) async {
    final params = <String, String>{'period': period};

    if (flowerId != null) {
      params['flower_id'] = flowerId.toString();
    }

    final uri = Uri.parse('$baseUrl/predictions').replace(
      queryParameters: params,
    );

    final response = await _sendRequest(
      () async => http.get(uri, headers: await _headers()),
    );

    return _handleResponse(response);
  }

  // FORGOT PASSWORD
  static Future<void> forgotPassword(String email) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: await _headers(),
        body: jsonEncode({'email': email}),
      ),
    );

    _handleResponse(response);
  }

  static Future<void> verifyOtp(String email, String otp) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: await _headers(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ),
    );

    _handleResponse(response);
  }

  static Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final response = await _sendRequest(
      () async => http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: await _headers(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      ),
    );

    _handleResponse(response);
  }

  // NOTIFICATIONS
  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await _sendRequest(
      () async => http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: await _headers(),
      ),
    );

    return _handleResponse(response);
  }

  static Future<void> markNotificationRead(int id) async {
    final response = await _sendRequest(
      () async => http.patch(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: await _headers(),
      ),
    );

    _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};

    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      throw ApiException(
        'Response server tidak valid.',
        response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException(
        body['message']?.toString() ?? 'Email atau password salah.',
      );
    }

    if (response.statusCode == 403) {
      throw ApiException(
        body['message']?.toString() ?? 'Akses ditolak.',
        response.statusCode,
      );
    }

    if (response.statusCode == 422) {
      throw ValidationException(
        body['message']?.toString() ?? 'Data tidak valid.',
        errors: body['errors'] is Map<String, dynamic>
            ? body['errors'] as Map<String, dynamic>
            : null,
      );
    }

    throw ApiException(
      body['message']?.toString() ?? 'Terjadi kesalahan pada server.',
      response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException(
    String message, {
    this.errors,
  }) : super(message, 422);
}