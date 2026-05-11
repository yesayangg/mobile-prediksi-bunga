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
      final data = response['data'] as Map<String, dynamic>?;

      if (data == null || data['user'] == null) {
        throw ApiException('Response login tidak valid', 500);
      }

      final token = data['token']?.toString() ?? '';
      final userJson = Map<String, dynamic>.from(data['user']);

      userJson['token'] = token;

      final loggedInUser = User.fromJson(userJson);

      if (!loggedInUser.isCashier) {
        await ApiService.clearToken();

        _user = null;
        _status = AuthStatus.error;
        _errorMessage =
            'Akun admin hanya dapat digunakan melalui website. Silakan login sebagai kasir untuk menggunakan aplikasi mobile.';
        notifyListeners();

        return false;
      }

      await ApiService.saveToken(token);

      _user = loggedInUser;
      _status = AuthStatus.authenticated;
      notifyListeners();

      return true;
    } catch (e) {
      await ApiService.clearToken();

      _user = null;
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();

    if (token != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }
}
