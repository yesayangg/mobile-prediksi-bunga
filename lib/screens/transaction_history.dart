import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

enum _HistoryFilter { all, today, mine }

enum _ReceiptNoticeKind { info, success, error }

class _ReceiptPlatformActions {
  static const _channel = MethodChannel('florashop/file_actions');

  static Future<String> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String collection,
  }) async {
    final path = await _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
      'collection': collection,
    });

    return path ?? fileName;
  }

  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String collection,
    required String text,
    required String subject,
  }) {
    return _channel.invokeMethod<void>('shareFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
      'collection': collection,
      'text': text,
      'subject': subject,
    });
  }

  static Future<void> printBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return _channel.invokeMethod<void>('printFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
      'collection': 'downloads',
    });
  }
}

class TransactionHistoryTab extends StatefulWidget {
  final NumberFormat currencyFmt;
  const TransactionHistoryTab({super.key, required this.currencyFmt});

  @override
  State<TransactionHistoryTab> createState() => _TransactionHistoryTabState();
}

class _TransactionHistoryTabState extends State<TransactionHistoryTab> {
  final _dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  _HistoryFilter _activeFilter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  void _showDetail(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        tx: tx,
        currencyFmt: widget.currencyFmt,
        dateFmt: _dateFmt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final currentUser = context.watch<AuthProvider>().user;

    if (txProvider.isLoading) {
      return const _HistorySkeletonList();
    }

    if (txProvider.errorMessage != null && txProvider.transactions.isEmpty) {
      return _HistoryStatePanel(
        icon: Icons.cloud_off_rounded,
        color: AppTheme.error,
        title: 'Riwayat belum bisa dimuat',
        subtitle: 'Pastikan internet aktif atau minta admin mengecek server.',
        actionLabel: 'Coba lagi',
        onAction: () => context.read<TransactionProvider>().loadTransactions(),
      );
    }

    if (txProvider.transactions.isEmpty) {
      return const _HistoryStatePanel(
        icon: Icons.receipt_long_outlined,
        color: AppTheme.primary,
        title: 'Belum ada transaksi',
        subtitle: 'Transaksi yang berhasil disimpan akan muncul di sini.',
      );
    }

    final filtered =
        _filteredTransactions(txProvider.transactions, currentUser);

    return Column(
      children: [
        _HistoryFilterBar(
          activeFilter: _activeFilter,
          allCount: txProvider.transactions.length,
          todayCount: _todayTransactions(txProvider.transactions).length,
          mineCount: _mineTransactions(
            txProvider.transactions,
            currentUser,
          ).length,
          onRefresh: () =>
              context.read<TransactionProvider>().loadTransactions(),
          onChanged: (filter) => setState(() => _activeFilter = filter),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _HistoryStatePanel(
                  icon: Icons.receipt_long_outlined,
                  color: AppTheme.primary,
                  title: _activeFilter == _HistoryFilter.mine
                      ? 'Belum ada transaksi dari akun ini'
                      : 'Belum ada transaksi hari ini',
                  subtitle: _activeFilter == _HistoryFilter.mine
                      ? 'Transaksi yang cocok dengan akun kasir ini akan muncul di sini.'
                      : 'Transaksi semua kasir yang bertanggal hari ini akan muncul di sini.',
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final tx = filtered[i];
                    return _HistoryCard(
                      tx: tx,
                      currencyFmt: widget.currencyFmt,
                      dateFmt: _dateFmt,
                      onTap: () => _showDetail(context, tx),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Transaction> _filteredTransactions(
    List<Transaction> transactions,
    currentUser,
  ) {
    switch (_activeFilter) {
      case _HistoryFilter.today:
        return _todayTransactions(transactions);
      case _HistoryFilter.mine:
        return _mineTransactions(transactions, currentUser);
      case _HistoryFilter.all:
        return transactions;
    }
  }

  List<Transaction> _todayTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    return transactions.where((tx) {
      final local = tx.createdAt.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList();
  }

  List<Transaction> _mineTransactions(
    List<Transaction> transactions,
    currentUser,
  ) {
    if (currentUser == null) return [];

    final currentId = currentUser.id.toString();
    final currentName = currentUser.name.toString().trim().toLowerCase();

    return transactions.where((tx) {
      final txId = tx.cashierId.trim();
      final txName = tx.cashierName.trim().toLowerCase();
      return txId == currentId ||
          (currentName.isNotEmpty && txName == currentName);
    }).toList();
  }
}

class _HistoryFilterBar extends StatelessWidget {
  final _HistoryFilter activeFilter;
  final int allCount;
  final int todayCount;
  final int mineCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<_HistoryFilter> onChanged;

  const _HistoryFilterBar({
    required this.activeFilter,
    required this.allCount,
    required this.todayCount,
    required this.mineCount,
    required this.onRefresh,
    required this.onChanged,
  });

  String get _helperText {
    switch (activeFilter) {
      case _HistoryFilter.all:
        return 'Menampilkan semua riwayat transaksi dari backend.';
      case _HistoryFilter.today:
        return 'Menampilkan transaksi semua kasir yang bertanggal hari ini.';
      case _HistoryFilter.mine:
        return 'Menampilkan transaksi yang cocok dengan akun kasir yang sedang masuk.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter Riwayat',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Perbarui riwayat transaksi',
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF5C6D8)),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF5C6D8)),
            ),
            child: Row(
              children: [
                _HistoryFilterChip(
                  label: 'Semua',
                  count: allCount,
                  selected: activeFilter == _HistoryFilter.all,
                  onTap: () => onChanged(_HistoryFilter.all),
                ),
                const SizedBox(width: 5),
                _HistoryFilterChip(
                  label: 'Hari Ini',
                  count: todayCount,
                  selected: activeFilter == _HistoryFilter.today,
                  onTap: () => onChanged(_HistoryFilter.today),
                ),
                const SizedBox(width: 5),
                _HistoryFilterChip(
                  label: 'Transaksi Saya',
                  count: mineCount,
                  selected: activeFilter == _HistoryFilter.mine,
                  onTap: () => onChanged(_HistoryFilter.mine),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _helperText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.6,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppTheme.primary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Transaction tx;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.tx,
    required this.currencyFmt,
    required this.dateFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5C6D8)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateFmt.format(tx.createdAt.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFmt.format(tx.grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontFamily: 'Poppins',
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.paymentMethod.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _HistoryStatePanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB11E5C).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 44),
                    elevation: 0,
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySkeletonList extends StatelessWidget {
  const _HistorySkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 76,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD9E8).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD9E8).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 86,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD9E8).withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  static OverlayEntry? _activeActionNotice;

  final Transaction tx;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _TransactionDetailSheet({
    required this.tx,
    required this.currencyFmt,
    required this.dateFmt,
  });

  String get _fileBaseName {
    final cleaned = tx.invoiceNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return 'florashop_$cleaned';
  }

  String get _cashierName =>
      tx.cashierName.trim().isEmpty || tx.cashierName == '-'
          ? 'Kasir'
          : tx.cashierName;

  PdfPageFormat get _receiptPageFormat {
    final itemHeightMm = tx.items.fold<double>(0, (sum, item) {
      final nameRows = (item.flowerName.length / 24).ceil().clamp(1, 3);
      return sum + 8 + ((nameRows - 1) * 4);
    });
    final noteHeightMm = tx.note == null || tx.note!.trim().isEmpty ? 0 : 10;
    final heightMm = (78 + itemHeightMm + noteHeightMm).clamp(92.0, 2000.0);

    return PdfPageFormat(
      80 * PdfPageFormat.mm,
      heightMm * PdfPageFormat.mm,
    );
  }

  Future<pw.Font> _loadPdfFont(String assetPath) async {
    return pw.Font.ttf(await rootBundle.load(assetPath));
  }

  Future<Uint8List> _buildPdfBytes() async {
    final regularFont = await _loadPdfFont('assets/fonts/Roboto-Regular.ttf');
    final mediumFont = await _loadPdfFont('assets/fonts/Roboto-Medium.ttf');
    final boldFont = await _loadPdfFont('assets/fonts/Roboto-Bold.ttf');
    final blackFont = await _loadPdfFont('assets/fonts/Roboto-Black.ttf');
    final doc = pw.Document();
    final pink = PdfColor.fromHex('#E21666');
    final dark = PdfColor.fromHex('#4B1528');
    final muted = PdfColor.fromHex('#9F6079');
    final softPink = PdfColor.fromHex('#FFF7FB');
    final borderPink = PdfColor.fromHex('#F5B4CE');
    final logoData = await rootBundle.load('assets/icons/app_icon.png');
    final logo = pw.MemoryImage(
      logoData.buffer.asUint8List(
        logoData.offsetInBytes,
        logoData.lengthInBytes,
      ),
    );
    final createdAt = dateFmt.format(tx.createdAt.toLocal());

    pw.TextStyle style(
      double fontSize,
      PdfColor color, {
      pw.Font? font,
    }) {
      return pw.TextStyle(
        font: font ?? regularFont,
        fontSize: fontSize,
        color: color,
      );
    }

    pw.Widget infoRow(
      String label,
      String value, {
      PdfColor? valueColor,
      bool total = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3.3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                label,
                style: style(
                  total ? 9.5 : 7.3,
                  total ? dark : muted,
                  font: total ? blackFont : mediumFont,
                ),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              flex: 9,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: style(
                  total ? 10 : 7.4,
                  valueColor ?? dark,
                  font: total ? blackFont : boldFont,
                ),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: _receiptPageFormat,
          margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 18,
                  height: 18,
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(
                    color: softPink,
                    borderRadius: pw.BorderRadius.circular(5),
                    border: pw.Border.all(color: borderPink, width: 0.45),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 6),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FLORAPREDICT',
                      style: style(12, pink, font: blackFont),
                    ),
                    pw.Text(
                      'Struk transaksi FLORASHOP',
                      style: style(7, muted, font: mediumFont),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          infoRow('Invoice', tx.invoiceNumber),
          infoRow('Tanggal', createdAt),
          infoRow('Kasir', _cashierName),
          infoRow('Bayar', tx.paymentMethod.label),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.55, color: borderPink),
          pw.SizedBox(height: 6),
          pw.Text(
            'Item Dibeli',
            style: style(8.7, dark, font: blackFont),
          ),
          pw.SizedBox(height: 5),
          ...tx.items.map((item) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.flowerName,
                          style: style(8.4, dark, font: blackFont),
                        ),
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          '${item.quantity} x ${currencyFmt.format(item.unitPrice)}',
                          style: style(7.2, muted, font: mediumFont),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    currencyFmt.format(item.subtotal),
                    style: style(8.1, dark, font: blackFont),
                  ),
                ],
              ),
            );
          }),
          pw.Container(height: 0.55, color: borderPink),
          pw.SizedBox(height: 6),
          infoRow('Subtotal', currencyFmt.format(tx.totalAmount)),
          if (tx.discount > 0)
            infoRow(
              'Diskon',
              '- ${currencyFmt.format(tx.discount)}',
              valueColor: pink,
            ),
          if (tx.tax > 0) infoRow('Pajak', currencyFmt.format(tx.tax)),
          if (tx.paymentMethod == PaymentMethod.cash) ...[
            infoRow('Dibayar', currencyFmt.format(tx.amountPaid)),
            infoRow('Kembalian', currencyFmt.format(tx.change)),
          ],
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderPink, width: 0.65),
                bottom: pw.BorderSide(color: borderPink, width: 0.65),
              ),
            ),
            child: infoRow(
              'TOTAL',
              currencyFmt.format(tx.grandTotal),
              valueColor: pink,
              total: true,
            ),
          ),
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Catatan: ${tx.note}',
              style: style(7.1, muted),
            ),
          ],
          pw.SizedBox(height: 9),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Terima kasih',
                  style: style(8.3, dark, font: blackFont),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Sampai jumpa lagi.',
                  style: style(6.8, muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<File> _writePdfFile([Uint8List? bytes]) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileBaseName.pdf');
    await file.writeAsBytes(bytes ?? await _buildPdfBytes(), flush: true);
    return file;
  }

  Future<Uint8List> _buildPngBytes() async {
    final bytes = await _buildPdfBytes();

    await for (final page in Printing.raster(bytes, pages: [0], dpi: 180)) {
      return page.toPng();
    }

    throw StateError('Struk belum bisa dirender menjadi gambar.');
  }

  Future<File> _writePngFile([Uint8List? bytes]) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileBaseName.png');
    await file.writeAsBytes(bytes ?? await _buildPngBytes(), flush: true);
    return file;
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      _showActionMessage(
        context,
        'Membuka pilihan printer...',
        kind: _ReceiptNoticeKind.info,
      );
      final bytes = await _buildPdfBytes();
      final fileName = '$_fileBaseName.pdf';

      if (Platform.isAndroid) {
        await _ReceiptPlatformActions.printBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
        if (!context.mounted) return;
        _showActionMessage(
          context,
          'Pilihan printer struk dibuka.',
        );
        return;
      }

      final printed = await Printing.layoutPdf(
        name: tx.invoiceNumber,
        onLayout: (_) async => bytes,
      );

      if (!context.mounted) return;
      _showActionMessage(
        context,
        printed ? 'Struk dikirim ke layanan cetak.' : 'Cetak struk dibatalkan.',
        kind: printed ? _ReceiptNoticeKind.success : _ReceiptNoticeKind.info,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Struk belum bisa dicetak. ${_receiptActionError(e)}',
        kind: _ReceiptNoticeKind.error,
      );
    }
  }

  Future<void> _savePdf(BuildContext context) async {
    try {
      _showActionMessage(
        context,
        'Menyiapkan PDF struk...',
        kind: _ReceiptNoticeKind.info,
      );
      final bytes = await _buildPdfBytes();
      final fileName = '$_fileBaseName.pdf';
      if (!context.mounted) return;

      if (Platform.isAndroid) {
        final location = await _ReceiptPlatformActions.saveBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
          collection: 'downloads',
        );
        if (!context.mounted) return;
        _showActionMessage(
          context,
          'PDF struk tersimpan di $location',
        );
        return;
      }

      final file = await _writePdfFile(bytes);
      if (!context.mounted) return;
      _showActionMessage(context, 'PDF struk tersimpan: ${file.path}');
    } catch (e) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'PDF struk belum bisa disimpan. ${_receiptActionError(e)}',
        kind: _ReceiptNoticeKind.error,
      );
    }
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      _showActionMessage(
        context,
        'Menyiapkan gambar struk...',
        kind: _ReceiptNoticeKind.info,
      );
      final bytes = await _buildPngBytes();
      final fileName = '$_fileBaseName.png';
      if (!context.mounted) return;

      if (Platform.isAndroid) {
        final location = await _ReceiptPlatformActions.saveBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'image/png',
          collection: 'pictures',
        );
        if (!context.mounted) return;
        _showActionMessage(
          context,
          'Gambar struk tersimpan di $location',
        );
        return;
      }

      final file = await _writePngFile(bytes);
      if (!context.mounted) return;
      _showActionMessage(context, 'Gambar struk tersimpan: ${file.path}');
    } catch (e) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Gambar struk belum bisa disimpan. ${_receiptActionError(e)}',
        kind: _ReceiptNoticeKind.error,
      );
    }
  }

  Future<void> _shareReceipt(BuildContext context,
      {required bool image}) async {
    try {
      final formatLabel = image ? 'gambar' : 'PDF';
      _showActionMessage(
        context,
        'Menyiapkan bagikan $formatLabel struk...',
        kind: _ReceiptNoticeKind.info,
      );
      final fileName = image ? '$_fileBaseName.png' : '$_fileBaseName.pdf';
      final mimeType = image ? 'image/png' : 'application/pdf';
      final text = 'Struk transaksi FLORASHOP ${tx.invoiceNumber}';
      final subject = 'Struk FLORASHOP ${tx.invoiceNumber}';

      if (Platform.isAndroid) {
        final bytes = image ? await _buildPngBytes() : await _buildPdfBytes();
        await _ReceiptPlatformActions.shareBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
          collection: image ? 'pictures' : 'downloads',
          text: text,
          subject: subject,
        );
        if (!context.mounted) return;
        _showActionMessage(
          context,
          'Menu bagikan $formatLabel struk dibuka.',
        );
        return;
      }

      final file = image ? await _writePngFile() : await _writePdfFile();
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path)],
          subject: subject,
        ),
      );
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Menu bagikan $formatLabel struk dibuka.',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showActionMessage(
        context,
        'Struk belum bisa dibagikan. ${_receiptActionError(e)}',
        kind: _ReceiptNoticeKind.error,
      );
    }
  }

  String _receiptActionError(Object error) {
    if (error is PlatformException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final message = error.toString().trim();
    if (message.isEmpty) return 'Coba lagi atau hubungi admin.';
    if (message.length > 96) return '${message.substring(0, 96)}...';
    return message;
  }

  void _showActionMessage(
    BuildContext context,
    String message, {
    _ReceiptNoticeKind kind = _ReceiptNoticeKind.success,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final color = switch (kind) {
      _ReceiptNoticeKind.info => AppTheme.info,
      _ReceiptNoticeKind.success => AppTheme.success,
      _ReceiptNoticeKind.error => AppTheme.error,
    };
    final icon = switch (kind) {
      _ReceiptNoticeKind.info => Icons.info_rounded,
      _ReceiptNoticeKind.success => Icons.check_circle_rounded,
      _ReceiptNoticeKind.error => Icons.error_rounded,
    };

    if (overlay != null) {
      _activeActionNotice?.remove();
      _activeActionNotice = null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      _activeActionNotice = entry;
      Future.delayed(const Duration(seconds: 3), () {
        if (_activeActionNotice == entry) {
          entry.remove();
          _activeActionNotice = null;
        }
      });
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReceiptActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptActionSheet(
        onPrint: () => _printReceipt(context),
        onSavePdf: () => _savePdf(context),
        onSaveImage: () => _saveImage(context),
        onSharePdf: () => _shareReceipt(context, image: false),
        onShareImage: () => _shareReceipt(context, image: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ScrollConfiguration(
        behavior: const _NoStretchScrollBehavior(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0B5CC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detail Struk',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showReceiptActions(context),
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Bagikan/Simpan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(44, 40),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ReceiptCard(tx: tx, currencyFmt: currencyFmt, dateFmt: dateFmt),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptActionSheet extends StatelessWidget {
  final Future<void> Function() onPrint;
  final Future<void> Function() onSavePdf;
  final Future<void> Function() onSaveImage;
  final Future<void> Function() onSharePdf;
  final Future<void> Function() onShareImage;

  const _ReceiptActionSheet({
    required this.onPrint,
    required this.onSavePdf,
    required this.onSaveImage,
    required this.onSharePdf,
    required this.onShareImage,
  });

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ScrollConfiguration(
          behavior: const _NoStretchScrollBehavior(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0B5CC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bagikan atau Simpan Struk',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih format struk sesuai kebutuhan kasir.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                _ReceiptActionTile(
                  icon: Icons.print_rounded,
                  title: 'Cetak Struk',
                  subtitle: 'Kirim ke printer yang tersedia di perangkat.',
                  onTap: () => _run(context, onPrint),
                ),
                _ReceiptActionTile(
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Simpan PDF',
                  subtitle: 'Simpan struk sebagai file PDF.',
                  onTap: () => _run(context, onSavePdf),
                ),
                _ReceiptActionTile(
                  icon: Icons.image_rounded,
                  title: 'Simpan Gambar',
                  subtitle: 'Simpan struk sebagai gambar siap dikirim.',
                  onTap: () => _run(context, onSaveImage),
                ),
                _ReceiptActionTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Bagikan PDF',
                  subtitle:
                      'Buka pilihan berbagi, termasuk WhatsApp jika tersedia.',
                  onTap: () => _run(context, onSharePdf),
                ),
                _ReceiptActionTile(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Bagikan Gambar',
                  subtitle: 'Cocok untuk dikirim sebagai foto struk.',
                  onTap: () => _run(context, onShareImage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReceiptActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF5C6D8)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Transaction tx;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _ReceiptCard({
    required this.tx,
    required this.currencyFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final cashierName = tx.cashierName.trim().isEmpty || tx.cashierName == '-'
        ? 'Kasir'
        : tx.cashierName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF5C6D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB11E5C).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF5C6D8)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFF5C6D8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLORAPREDICT',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Struk transaksi FLORASHOP',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        tx.paymentMethod.label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReceiptMetaRow(label: 'Invoice', value: tx.invoiceNumber),
                const SizedBox(height: 6),
                _ReceiptMetaRow(
                  label: 'Tanggal',
                  value: dateFmt.format(tx.createdAt.toLocal()),
                ),
                const SizedBox(height: 6),
                _ReceiptMetaRow(label: 'Kasir', value: cashierName),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item Dibeli',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                ...tx.items.map(
                  (item) => _ReceiptItemRow(
                    item: item,
                    currencyFmt: currencyFmt,
                  ),
                ),
                const SizedBox(height: 10),
                const _ReceiptDivider(),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Subtotal',
                  value: currencyFmt.format(tx.totalAmount),
                ),
                const SizedBox(height: 6),
                _DetailRow(
                  label: 'Metode bayar',
                  value: tx.paymentMethod.label,
                ),
                if (tx.paymentMethod == PaymentMethod.cash) ...[
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Dibayar',
                    value: currencyFmt.format(tx.amountPaid),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Kembalian',
                    value: currencyFmt.format(tx.change),
                    valueColor: AppTheme.success,
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currencyFmt.format(tx.grandTotal),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan: ${tx.note}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Terima kasih',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sampai jumpa lagi.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final TransactionItem item;
  final NumberFormat currencyFmt;

  const _ReceiptItemRow({required this.item, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C6D8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: AppTheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.flowerName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x ${currencyFmt.format(item.unitPrice)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFmt.format(item.subtotal),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(),
      child: const SizedBox(width: double.infinity, height: 1),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0B5CC)
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + 6, 0), paint);
      startX += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
