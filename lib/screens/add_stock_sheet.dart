import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/flower_stock.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_popup.dart';

enum StockActionType { adjust, addNew }

class StockActionResult {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const StockActionResult({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class AddStockSheet extends StatefulWidget {
  final List<FlowerStock> existingStocks;

  const AddStockSheet({super.key, required this.existingStocks});

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  StockActionType _action = StockActionType.adjust;
  FlowerStock? _selectedFlower;
  List<FlowerStock> _searchResults = [];
  bool _showDropdown = false;
  String _adjustType = 'add';
  final String _selectedCategory = 'Bunga Potong';
  final String _unit = 'tangkai';
  bool _isLoading = false;
  int _rawPrice = 0;

  final _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool get _isAdjustMode => _action == StockActionType.adjust;

  IconData get _headerIcon =>
      _isAdjustMode ? Icons.add_box_rounded : Icons.local_florist_rounded;

  String get _sheetTitle =>
      _isAdjustMode ? 'Perbarui Stok Bunga' : 'Tambah Bunga Baru';

  String get _sheetSubtitle => _isAdjustMode
      ? 'Pilih bunga lalu tambah atau kurangi jumlah stok.'
      : 'Tambahkan bunga baru dengan satuan tangkai.';

  String get _submitLabel {
    if (!_isAdjustMode) return 'Tambah Bunga Baru';
    return _adjustType == 'add' ? 'Tambah Stok' : 'Kurangi Stok';
  }

  String? get _actionSummary {
    if (_isAdjustMode) {
      final flower = _selectedFlower;
      final quantity = int.tryParse(_quantityCtrl.text.trim());
      if (flower == null || quantity == null || quantity <= 0) return null;

      final sign = _adjustType == 'add' ? '+' : '-';
      return '${flower.name} $sign$quantity ${flower.unit}';
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _rawPrice <= 0) {
      return null;
    }

    return 'Bunga baru: $name, ${_rupiahFormatter.format(_rawPrice)} / $_unit';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _quantityCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _searchResults = [];
        _showDropdown = false;
        _selectedFlower = null;
        return;
      }

      _searchResults = widget.existingStocks
          .where((flower) => flower.name.toLowerCase().contains(q))
          .take(8)
          .toList();
      _showDropdown = true;
      _selectedFlower = null;
    });
  }

  void _selectFlower(FlowerStock flower) {
    setState(() {
      _selectedFlower = flower;
      _searchCtrl.text = flower.name;
      _showDropdown = false;
      _searchResults = [];
    });
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Tidak bisa terhubung')) return message;
    if (message.contains('Data tidak valid')) return message;
    if (message.contains('Akses ditolak')) return message;
    return 'Data stok belum bisa disimpan. Periksa isian atau coba lagi.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _confirmSubmit();
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    final notifProvider = context.read<NotificationProvider>();

    try {
      if (_action == StockActionType.adjust) {
        final flower = _selectedFlower!;
        final quantity = int.parse(_quantityCtrl.text.trim());
        await ApiService.updateStock(
          flower.id,
          quantity,
          _adjustType,
        );

        final title = _adjustType == 'add'
            ? 'Stok Bunga Ditambahkan'
            : 'Stok Bunga Dikurangi';
        final actionLabel = _adjustType == 'add' ? 'ditambahkan' : 'dikurangi';
        final message =
            'Stok bunga ${flower.name} berhasil $actionLabel sebanyak $quantity ${flower.unit}.';
        await notifProvider.addNotification(
          title: title,
          message: message,
          type: NotificationType.stockAdded,
        );

        if (!mounted) return;
        Navigator.pop(
          context,
          StockActionResult(
            title: title,
            message: message,
            icon: _adjustType == 'add'
                ? Icons.add_box_rounded
                : Icons.remove_circle_outline_rounded,
            color: _adjustType == 'add' ? AppTheme.success : AppTheme.error,
          ),
        );
      } else {
        final name = _nameCtrl.text.trim();
        await ApiService.addNewFlower({
          'name': name,
          'category': _selectedCategory,
          'price': _rawPrice,
          'unit': _unit,
        });

        final message =
            'Bunga baru Bunga Potong $name berhasil ditambahkan dengan harga ${_rupiahFormatter.format(_rawPrice)} per tangkai.';
        await notifProvider.addNotification(
          title: 'Bunga Ditambahkan',
          message: message,
          type: NotificationType.flowerAdded,
        );

        if (!mounted) return;
        Navigator.pop(
          context,
          StockActionResult(
            title: 'Bunga Ditambahkan',
            message: message,
            icon: Icons.local_florist_rounded,
            color: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      NotificationPopup.show(
        context,
        title: 'Gagal Menyimpan',
        message: _friendlyError(e),
        type: NotificationType.outOfStock,
      );
    }
  }

  Future<bool> _confirmSubmit() async {
    if (_isAdjustMode) {
      final flower = _selectedFlower!;
      final quantity = int.parse(_quantityCtrl.text.trim());
      final isAdd = _adjustType == 'add';
      final finalStock = isAdd
          ? flower.stock + quantity
          : (flower.stock - quantity).clamp(0, flower.stock);

      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _ConfirmStockDialog(
              icon: isAdd
                  ? Icons.add_box_rounded
                  : Icons.remove_circle_outline_rounded,
              color: isAdd ? AppTheme.success : AppTheme.error,
              title: isAdd ? 'Yakin tambah stok?' : 'Yakin kurangi stok?',
              message: isAdd
                  ? 'Stok ${flower.name} akan ditambah $quantity ${flower.unit}.'
                  : 'Stok ${flower.name} akan dikurangi $quantity ${flower.unit}.',
              detail: isAdd
                  ? 'Stok saat ini ${flower.stock} ${flower.unit}. Setelah ditambah: $finalStock ${flower.unit}.'
                  : 'Stok saat ini ${flower.stock} ${flower.unit}. Setelah dikurangi: $finalStock ${flower.unit}.',
              confirmLabel: isAdd ? 'Ya, Tambah' : 'Ya, Kurangi',
            ),
          ) ??
          false;
    }

    final name = _nameCtrl.text.trim();
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ConfirmStockDialog(
            icon: Icons.local_florist_rounded,
            color: AppTheme.primary,
            title: 'Yakin tambah bunga baru?',
            message:
                '$name akan ditambahkan sebagai bunga baru dengan harga jual ${_rupiahFormatter.format(_rawPrice)}.',
            detail: 'Kategori Bunga Potong, satuan tangkai.',
            confirmLabel: 'Ya, Tambah',
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0B5CC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryLight, AppTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _headerIcon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sheetTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              color: AppTheme.textPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _sheetSubtitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: AppTheme.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF5C6D8)),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: 'Tambah Jumlah',
                        icon: Icons.add_box_rounded,
                        isActive: _action == StockActionType.adjust,
                        onTap: () =>
                            setState(() => _action = StockActionType.adjust),
                      ),
                      _TabButton(
                        label: 'Bunga Baru',
                        icon: Icons.local_florist_rounded,
                        isActive: _action == StockActionType.addNew,
                        onTap: () =>
                            setState(() => _action = StockActionType.addNew),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _action == StockActionType.adjust
                      ? _buildAdjustForm()
                      : _buildAddNewForm(),
                ),
                const SizedBox(height: 16),
                _ActionSummaryCard(
                  summary: _actionSummary,
                  isAdjustMode: _isAdjustMode,
                  isSubtract: _adjustType == 'subtract',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primary.withValues(alpha: 0.48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _submitLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              letterSpacing: 0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustForm() {
    return Column(
      key: const ValueKey('adjust-stock-form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration:
              _inputDecoration('Cari bunga', Icons.search_rounded).copyWith(
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Bersihkan pilihan',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (_) => _selectedFlower == null ? 'Pilih bunga dulu' : null,
        ),
        if (_showDropdown) _buildSearchResults(),
        if (_selectedFlower != null)
          _SelectedStockInfo(flower: _selectedFlower!),
        const SizedBox(height: 14),
        Row(
          children: [
            _TypeButton(
              label: 'Tambah',
              icon: Icons.add_circle_outline_rounded,
              color: AppTheme.success,
              isActive: _adjustType == 'add',
              onTap: () => setState(() => _adjustType = 'add'),
            ),
            const SizedBox(width: 10),
            _TypeButton(
              label: 'Kurangi',
              icon: Icons.remove_circle_outline_rounded,
              color: AppTheme.error,
              isActive: _adjustType == 'subtract',
              onTap: () => setState(() => _adjustType = 'subtract'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _quantityCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Jumlah', Icons.numbers_rounded),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Jumlah wajib diisi';
            final parsed = int.tryParse(value);
            if (parsed == null || parsed <= 0) {
              return 'Masukkan jumlah yang valid';
            }
            if (_adjustType == 'subtract' &&
                _selectedFlower != null &&
                parsed > _selectedFlower!.stock) {
              return 'Jumlah melebihi stok saat ini';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5C6D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB11E5C).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _searchResults.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Bunga tidak ditemukan.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFFF8D7E4),
              ),
              itemBuilder: (context, index) {
                final flower = _searchResults[index];
                return ListTile(
                  minLeadingWidth: 32,
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_florist_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    flower.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${flower.stock} ${flower.unit} tersedia',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () => _selectFlower(flower),
                );
              },
            ),
    );
  }

  Widget _buildAddNewForm() {
    return Column(
      key: const ValueKey('add-flower-form'),
      children: [
        TextFormField(
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration('Nama bunga', Icons.local_florist),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        const _LockedInfoField(
          label: 'Kategori',
          value: 'Bunga Potong',
          badge: 'Tetap',
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Harga jual', Icons.sell_outlined),
          style: const TextStyle(fontFamily: 'Poppins'),
          onChanged: (value) {
            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            _rawPrice = digits.isEmpty ? 0 : int.parse(digits);
            final formatted =
                digits.isEmpty ? '' : _rupiahFormatter.format(_rawPrice);
            _priceCtrl.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
            setState(() {});
          },
          validator: (_) => _rawPrice <= 0 ? 'Harga wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        const _LockedInfoField(
          label: 'Satuan',
          value: 'tangkai',
          badge: 'Tetap',
          icon: Icons.straighten_rounded,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: AppTheme.textSecondary,
      ),
      prefixIcon: Icon(icon, size: 19, color: AppTheme.textSecondary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF5C6D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _ConfirmStockDialog extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String detail;
  final String confirmLabel;

  const _ConfirmStockDialog({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.detail,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D1734).withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF5C6D8)),
              ),
              child: Text(
                detail,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: Color(0xFFF5C6D8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
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

class _ActionSummaryCard extends StatelessWidget {
  final String? summary;
  final bool isAdjustMode;
  final bool isSubtract;

  const _ActionSummaryCard({
    required this.summary,
    required this.isAdjustMode,
    required this.isSubtract,
  });

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary != null;
    final color = !hasSummary
        ? AppTheme.textSecondary
        : isAdjustMode
            ? isSubtract
                ? AppTheme.error
                : AppTheme.success
            : AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: hasSummary ? 0.22 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasSummary
                  ? Icons.fact_check_rounded
                  : Icons.info_outline_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Aksi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary ?? 'Lengkapi data agar ringkasan muncul.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color:
                        hasSummary ? AppTheme.textPrimary : AppTheme.textHint,
                    letterSpacing: 0,
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

class _LockedInfoField extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final IconData icon;

  const _LockedInfoField({
    required this.label,
    required this.value,
    required this.badge,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5C6D8)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.success,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedStockInfo extends StatelessWidget {
  final FlowerStock flower;

  const _SelectedStockInfo({required this.flower});

  @override
  Widget build(BuildContext context) {
    final isLow = flower.isLowStock;
    final color = isLow ? const Color(0xFFC68A14) : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Stok saat ini ${flower.stock} ${flower.unit}, minimal ${flower.minStock}.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: color,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? Colors.white : AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: isActive ? Colors.white : AppTheme.primary,
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
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? color : const Color(0xFFF5C6D8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isActive ? color : AppTheme.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      color: isActive ? color : AppTheme.textHint,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
