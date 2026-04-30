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
  bool get isCashier => _user?.isCashier ?? true;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // =============================================
    // BYPASS LOGIN - hapus bagian ini kalau backend
    // sudah siap
    await Future.delayed(const Duration(milliseconds: 500));
    _user = User.fromJson({
      'id': 1,
      'name': 'yesa',
      'email': email,
      'role': 'owner',
      'token': 'dummy_token',
      'avatar_url': null,
    });
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
    // =============================================

    // try {
    //   final response = await ApiService.login(email, password);
    //   _user = User.fromJson(response['data']['user']);
    //   await ApiService.saveToken(response['data']['token']);
    //   _status = AuthStatus.authenticated;
    //   notifyListeners();
    //   return true;
    // } catch (e) {
    //   _status = AuthStatus.error;
    //   _errorMessage = e.toString();
    //   notifyListeners();
    //   return false;
    // }
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
