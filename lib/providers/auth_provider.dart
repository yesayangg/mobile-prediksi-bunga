import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _serverStatusMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get serverStatusMessage => _serverStatusMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isCashier => _user?.isCashier ?? false;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _serverStatusMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

      final success = response['success'] == true;
      final data = response['data'];

      if (!success || data == null || data is! Map<String, dynamic>) {
        _status = AuthStatus.unauthenticated;
        _errorMessage =
            response['message']?.toString() ?? 'Masuk belum berhasil';
        notifyListeners();
        return false;
      }

      final token = data['token'];
      final userData = data['user'];

      if (token == null ||
          userData == null ||
          userData is! Map<String, dynamic>) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Respons masuk tidak valid';
        notifyListeners();
        return false;
      }

      final userJson = Map<String, dynamic>.from(userData);
      userJson['token'] = token;

      await ApiService.saveToken(token.toString());

      _user = User.fromJson(userJson);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _serverStatusMessage = null;
      notifyListeners();

      return true;
    } on UnauthorizedException {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Email atau kata sandi belum sesuai.';
      _serverStatusMessage = null;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _user = null;
      _status = AuthStatus.unauthenticated;

      if (e.statusCode == 0 || e.statusCode == 408 || e.statusCode >= 500) {
        _errorMessage =
            'Tidak bisa terhubung ke server. Pastikan internet aktif atau hubungi admin.';
        _serverStatusMessage = 'Server toko belum bisa dijangkau.';
      } else if (e.statusCode == 403) {
        _errorMessage =
            'Akun kasir ini belum bisa masuk. Silakan hubungi admin.';
        _serverStatusMessage = null;
      } else {
        _errorMessage = e.message;
        _serverStatusMessage = null;
      }

      notifyListeners();
      return false;
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage =
          'Tidak bisa terhubung ke server. Pastikan internet aktif atau hubungi admin.';
      _serverStatusMessage = 'Server toko belum bisa dijangkau.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      await ApiService.clearToken();
    }

    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _serverStatusMessage = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();

    if (token != null) {
      _status = AuthStatus.authenticated;
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    _errorMessage = null;
    _serverStatusMessage = null;

    notifyListeners();
  }
}
