import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  Color _color(NotificationType t) {
    switch (t) {
      case NotificationType.lowStock:
        return AppTheme.warning;
      case NotificationType.outOfStock:
        return AppTheme.error;
      case NotificationType.transaction:
        return AppTheme.success;
      default:
        return AppTheme.info;
    }
  }

  IconData _icon(NotificationType t) {
    switch (t) {
      case NotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case NotificationType.outOfStock:
        return Icons.warning_amber;
      case NotificationType.transaction:
        return Icons.receipt_long;
      default:
        return Icons.info_outline;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔔 Notifikasi 🌸'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) async {
              if (v == 'logout') {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: AppTheme.error),
                  SizedBox(width: 8),
                  Text('Keluar', style: TextStyle(color: AppTheme.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => np.loadNotifications(),
        child: np.isLoading
            ? const Center(child: CircularProgressIndicator())
            : np.notifications.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_none,
                        size: 48, color: AppTheme.textHint),
                    SizedBox(height: 12),
                    Text('Tidak ada notifikasi',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins')),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: np.notifications.length,
                    itemBuilder: (_, i) {
                      final n = np.notifications[i];
                      final c = _color(n.type);
                      return GestureDetector(
                        onTap: () => np.markAsRead(n.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppTheme.bgCard
                                : c.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: n.isRead
                                    ? AppTheme.border
                                    : c.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_icon(n.type), color: c, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(n.title,
                                              style: TextStyle(
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                  fontFamily: 'Poppins')),
                                        ),
                                        if (!n.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                                color: c,
                                                shape: BoxShape.circle),
                                          ),
                                      ]),
                                      const SizedBox(height: 3),
                                      Text(n.message,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              fontFamily: 'Poppins')),
                                      const SizedBox(height: 4),
                                      Text(_timeAgo(n.createdAt),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textHint,
                                              fontFamily: 'Poppins')),
                                    ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
