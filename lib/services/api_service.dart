import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // TODO: Ganti dengan base URL backend kamu
  static const String baseUrl = 'http://10.0.2.2:8000/api';
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

  // AUTH
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _headers(),
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
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateStock(
      int id, int quantity, String type) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/stocks/$id/adjust'),
      headers: await _headers(),
      body: jsonEncode({'quantity': quantity, 'type': type}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addNewFlower(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stocks'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // TRANSACTIONS
  static Future<Map<String, dynamic>> createTransaction(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _headers(),
      body: jsonEncode(data),
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

    final uri =
        Uri.parse('$baseUrl/transactions').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // PREDICTIONS
  static Future<dynamic> getPredictions({
    int? flowerId,
    String period = '7days',
  }) async {
    final params = <String, String>{'period': period};
    if (flowerId != null) params['flower_id'] = flowerId.toString();

    final uri =
        Uri.parse('$baseUrl/predictions').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    return _handleResponse(response);
  }

  // NOTIFICATIONS
  // FORGOT PASSWORD
static Future<void> forgotPassword(String email) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/forgot-password'),
    headers: await _headers(),
    body: jsonEncode({'email': email}),
  );
  _handleResponse(response);
}

static Future<void> verifyOtp(String email, String otp) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/verify-otp'),
    headers: await _headers(),
    body: jsonEncode({'email': email, 'otp': otp}),
  );
  _handleResponse(response);
}

static Future<void> resetPassword(
    String email, String otp, String newPassword) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/reset-password'),
    headers: await _headers(),
    body: jsonEncode({
      'email': email,
      'otp': otp,
      'password': newPassword,
      'password_confirmation': newPassword,
    }),
  );
  _handleResponse(response);
}
  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<void> markNotificationRead(int id) async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(body['message'] ?? 'Sesi habis, login ulang');
    } else if (response.statusCode == 422) {
      throw ValidationException(body['message'] ?? 'Data tidak valid',
          errors: body['errors'] as Map<String, dynamic>?);
    } else {
      throw ApiException(
          body['message'] ?? 'Terjadi kesalahan', response.statusCode);
    }
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
  ValidationException(String message, {this.errors}) : super(message, 422);
}