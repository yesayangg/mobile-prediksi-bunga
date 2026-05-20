import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isOwner => _user?.isOwner ?? false;
  bool get isCashier => _user?.isCashier ?? false;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

      final success = response['success'] == true;
      final data = response['data'];

      if (!success || data == null || data is! Map<String, dynamic>) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = response['message']?.toString() ?? 'Login gagal';
        notifyListeners();
        return false;
      }

      final token = data['token'];
      final userData = data['user'];

      if (token == null || userData == null || userData is! Map<String, dynamic>) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Response login tidak valid';
        notifyListeners();
        return false;
      }

      final userJson = Map<String, dynamic>.from(userData);
      userJson['token'] = token;

      _user = User.fromJson(userJson);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _user = null;
      _status = AuthStatus.unauthenticated;

      final message = e.toString();

      if (message.contains('401')) {
        _errorMessage = 'Email atau password salah';
      } else if (message.contains('403')) {
        _errorMessage = 'Akun ini tidak diizinkan login di aplikasi mobile';
      } else {
        _errorMessage = message.replaceFirst('Exception: ', '');
      }

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

    notifyListeners();
  }
}