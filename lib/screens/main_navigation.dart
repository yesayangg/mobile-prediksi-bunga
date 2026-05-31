import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';

import 'home_screen.dart';
import 'stock_screen.dart';
import 'transaction_screen.dart';
import 'prediction_screen.dart';

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
  int _currentIndex = 0;
  int _transactionInitialTab = 0;

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

  void _goToStock() {
    final stock = context.read<StockProvider>();
    stock.search('');
    stock.toggleLowStockFilter(false);
    stock.filterByCategory(null);

    setState(() {
      _currentIndex = 1;
    });

    unawaited(stock.loadStocks(refresh: true));
  }

  void _goToLowStock() {
    final stock = context.read<StockProvider>();
    stock.search('');
    stock.toggleLowStockFilter(true);

    setState(() {
      _currentIndex = 1;
    });

    unawaited(stock.loadStocks(refresh: true));
  }

  void _goToTransactionHistory() {
    setState(() {
      _transactionInitialTab = 1;
      _currentIndex = 2;
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
      context.read<PredictionProvider>().loadPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider tetap dibaca agar state login user tetap tersedia.
    // Saat ini tidak dipakai untuk menyembunyikan menu Prediksi,
    // karena menu Prediksi memang ingin ditampilkan di mobile.
    context.watch<AuthProvider>();

    // Provider notifikasi dipakai untuk menampilkan badge pada menu Stok.
    final notifProvider = context.watch<NotificationProvider>();

    // Daftar halaman utama aplikasi.
    //
    // Jumlah screen harus sama dengan jumlah item BottomNavigationBar.
    // Kalau urutannya berubah, index di _currentIndex juga harus disesuaikan.
    final screens = [
      HomeScreen(
        onNavigateToPrediksi: _goToPrediksi,
        onNavigateToStock: _goToStock,
        onNavigateToLowStock: _goToLowStock,
        onNavigateToTransactions: _goToTransactionHistory,
      ),
      const StockScreen(),
      TransactionScreen(
        initialTab: _transactionInitialTab,
        onOpenStock: _goToLowStock,
      ),
      const PredictionScreen(),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F9D174D),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: const Color(0xFFC793AA),
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            elevation: 0,

            // Saat user menekan menu bawah, update index halaman aktif.
            onTap: (index) {
              if (index == 2) {
                final stock = context.read<StockProvider>();
                stock.search('');
                stock.toggleLowStockFilter(false);
                stock.filterByCategory(null);
              }

              setState(() {
                if (index == 2) _transactionInitialTab = 0;
                _currentIndex = index;
              });
            },

            // Urutan menu:
            // Beranda | Stok | Kasir | Prediksi
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
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
                activeIcon: const Icon(Icons.inventory_2_rounded),
                label: 'Stok',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale_outlined),
                activeIcon: Icon(Icons.point_of_sale_rounded),
                label: 'Kasir',
              ),

              // Menu Prediksi ditampilkan untuk mobile.
              // Posisi: setelah Kasir.
              const BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights_rounded),
                label: 'Prediksi',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
