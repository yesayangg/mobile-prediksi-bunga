import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum NotificationType {
  lowStock,
  outOfStock,
  transaction,
  stockAdded,
  flowerAdded,
  info,
  warning
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  static const _storage = FlutterSecureStorage();
  static const _prefKey = 'app_notifications';

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get lowStockNotifications => _notifications
      .where((n) =>
          n.type == NotificationType.lowStock ||
          n.type == NotificationType.outOfStock)
      .toList();

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storage.read(key: _prefKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _notifications =
            decoded.map((e) => AppNotification.fromJson(e)).toList();
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final encoded =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await _storage.write(key: _prefKey, value: encoded);
    } catch (_) {}
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final notif = AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    notifyListeners();
    await _save();
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _save();
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _save();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _save();
  }
}
