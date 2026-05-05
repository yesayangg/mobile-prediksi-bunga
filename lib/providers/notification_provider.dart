import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

enum NotificationType { lowStock, outOfStock, transaction, info, warning }

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
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

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
      final response = await ApiService.getNotifications();
      _notifications = (response['data'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
    } catch (e) {
      // Silently fail
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await ApiService.markNotificationRead(id);
    }
  }

  void addLocalNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
