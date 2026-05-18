import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';

import 'home_screen.dart';
import 'stock_screen.dart';
import 'transaction_screen.dart';
import 'prediction_screen.dart';
import 'notification_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Menyimpan index menu yang sedang aktif.
  //
  // Urutan index menu:
  // 0 = Beranda
  // 1 = Stok
  // 2 = Kasir
  // 3 = Prediksi
  // 4 = Notifikasi
  int _currentIndex = 0;

  // Fungsi ini dipanggil dari halaman Beranda ketika user menekan
  // tombol/link "Lihat Semua" pada bagian prediksi singkat.
  //
  // Prediksi sekarang dibuat bisa diakses dari mobile,
  // jadi tidak dibatasi lagi hanya untuk owner/admin.
  void _goToPrediksi() {
    setState(() {
      _currentIndex = 3;
    });
  }

  @override
  void initState() {
    super.initState();

    // Memuat data awal setelah widget pertama kali selesai dirender.
    //
    // addPostFrameCallback dipakai agar context aman digunakan
    // untuk memanggil Provider setelah proses build awal selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadStocks();
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider tetap dibaca agar state login user tetap tersedia.
    // Saat ini tidak dipakai untuk menyembunyikan menu Prediksi,
    // karena menu Prediksi memang ingin ditampilkan di mobile.
    context.watch<AuthProvider>();

    // Provider notifikasi dipakai untuk menampilkan badge pada menu Stok
    // dan menu Notifikasi.
    final notifProvider = context.watch<NotificationProvider>();

    // Daftar halaman utama aplikasi.
    //
    // Jumlah screen harus sama dengan jumlah item BottomNavigationBar.
    // Kalau urutannya berubah, index di _currentIndex juga harus disesuaikan.
    final screens = [
      HomeScreen(onNavigateToPrediksi: _goToPrediksi),
      const StockScreen(),
      const TransactionScreen(),
      const PredictionScreen(),
      const NotificationScreen(),
    ];

    return Scaffold(
      // IndexedStack menjaga state tiap halaman tetap hidup.
      // Contoh: ketika pindah dari Stok ke Kasir lalu kembali ke Stok,
      // halaman Stok tidak dibuat ulang dari nol.
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // Bottom navigation utama aplikasi mobile.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,

          // Saat user menekan menu bawah, update index halaman aktif.
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          // Urutan menu:
          // Beranda | Stok | Kasir | Prediksi | Notifikasi
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),

            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.inventory_2_outlined),

                  // Tanda kecil pada menu Stok jika ada notifikasi stok rendah.
                  if (notifProvider.lowStockNotifications.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.inventory_2),
              label: 'Stok',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),

            // Menu Prediksi ditampilkan untuk mobile.
            // Posisi: setelah Kasir, sebelum Notifikasi.
            const BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Prediksi',
            ),

            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),

                  // Badge jumlah notifikasi belum dibaca.
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notifProvider.unreadCount > 9
                              ? '9+'
                              : notifProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Notifikasi',
            ),
          ],
        ),
      ),
    );
  }
}