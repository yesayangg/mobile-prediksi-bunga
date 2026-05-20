// lib/screens/add_stock_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/flower_stock.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_popup.dart';

enum StockActionType { adjust, addNew }

class AddStockSheet extends StatefulWidget {
  final List<FlowerStock> existingStocks;

  const AddStockSheet({super.key, required this.existingStocks});

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  StockActionType _action = StockActionType.adjust;

  // Untuk "Tambah Jumlah Stok" — search
  final _searchCtrl = TextEditingController();
  FlowerStock? _selectedFlower;
  List<FlowerStock> _searchResults = [];
  bool _showDropdown = false;

  final _quantityCtrl = TextEditingController();
  String _adjustType = 'add'; // 'add' atau 'subtract'

  // Untuk "Tambah Bunga Baru"
  final _nameCtrl = TextEditingController();
  String? _selectedCategory;
  final _priceCtrl = TextEditingController();
  String _unit = 'tangkai';

  bool _isLoading = false;

  final List<String> _units = ['tangkai', 'pot', 'lusin', 'ikat', 'buket'];

  final List<String> _categories = [
    'Bunga Potong',
    'Buket',
    'Rangkaian',
    'Bunga Papan',
    'Tanaman Pot',
    'Bunga Kering',
    'Bunga Artificial',
    'Karangan Bunga',
  ];

  final _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _rawPrice = 0;

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
      } else {
        _searchResults = widget.existingStocks
            .where((f) => f.name.toLowerCase().contains(q))
            .toList();
        _showDropdown = _searchResults.isNotEmpty;
      }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final notifProvider = context.read<NotificationProvider>();

    try {
      if (_action == StockActionType.adjust) {
        await ApiService.updateStock(
          _selectedFlower!.id,
          int.parse(_quantityCtrl.text.trim()),
          _adjustType,
        );

        await notifProvider.addNotification(
          title: 'Stok Diperbarui',
          message: 'Stok ${_selectedFlower!.name} berhasil diperbarui! 🌸',
          type: NotificationType.stockAdded,
        );

        NotificationPopup.show(
          context,
          title: 'Stok Diperbarui',
          message: 'Stok ${_selectedFlower!.name} berhasil diperbarui! 🌸',
          type: NotificationType.stockAdded,
        );
      } else {
        await ApiService.addNewFlower({
          'name': _nameCtrl.text.trim(),
          'category': _selectedCategory,
          'price': _rawPrice,
          'unit': _unit,
        });

        await notifProvider.addNotification(
          title: 'Bunga Ditambahkan',
          message: '${_nameCtrl.text.trim()} berhasil ditambahkan! 🌹',
          type: NotificationType.flowerAdded,
        );

        NotificationPopup.show(
          context,
          title: 'Bunga Ditambahkan',
          message: '${_nameCtrl.text.trim()} berhasil ditambahkan! 🌹',
          type: NotificationType.flowerAdded,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationPopup.show(
        context,
        title: 'Gagal',
        message: e.toString(),
        type: NotificationType.outOfStock,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Kelola Stok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Toggle action
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Tambah Jumlah',
                      icon: Icons.add_box_outlined,
                      isActive: _action == StockActionType.adjust,
                      onTap: () =>
                          setState(() => _action = StockActionType.adjust),
                    ),
                    _TabButton(
                      label: 'Bunga Baru',
                      icon: Icons.local_florist_outlined,
                      isActive: _action == StockActionType.addNew,
                      onTap: () =>
                          setState(() => _action = StockActionType.addNew),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form sesuai action
              if (_action == StockActionType.adjust)
                _buildAdjustForm()
              else
                _buildAddNewForm(),

              const SizedBox(height: 24),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _action == StockActionType.adjust
                              ? 'Perbarui Stok'
                              : 'Tambah Bunga',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bunga
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Cari Bunga',
                labelStyle:
                    const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
              validator: (_) =>
                  _selectedFlower == null ? 'Pilih bunga dulu' : null,
            ),

            // Dropdown hasil search
            if (_showDropdown)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final flower = _searchResults[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.local_florist,
                          size: 16, color: AppTheme.primary),
                      title: Text(
                        flower.name,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 13),
                      ),
                      subtitle: Text(
                        '${flower.stock} ${flower.unit}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppTheme.textHint),
                      ),
                      onTap: () => _selectFlower(flower),
                    );
                  },
                ),
              ),

            // Info stok bunga yang dipilih
            if (_selectedFlower != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Stok saat ini: ${_selectedFlower!.stock} ${_selectedFlower!.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Tipe: tambah / kurangi
        Row(
          children: [
            _TypeButton(
              label: 'Tambah',
              icon: Icons.add_circle_outline,
              color: AppTheme.success,
              isActive: _adjustType == 'add',
              onTap: () => setState(() => _adjustType = 'add'),
            ),
            const SizedBox(width: 10),
            _TypeButton(
              label: 'Kurangi',
              icon: Icons.remove_circle_outline,
              color: AppTheme.error,
              isActive: _adjustType == 'subtract',
              onTap: () => setState(() => _adjustType = 'subtract'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Jumlah
        TextFormField(
          controller: _quantityCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Jumlah', Icons.numbers),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Jumlah tidak boleh kosong';
            if (int.tryParse(v) == null || int.parse(v) <= 0) {
              return 'Masukkan angka yang valid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddNewForm() {
    return Column(
      children: [
        // Nama bunga
        TextFormField(
          controller: _nameCtrl,
          decoration: _inputDecoration('Nama Bunga', Icons.local_florist),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
        ),
        const SizedBox(height: 14),

        // Kategori dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: _inputDecoration('Kategori', Icons.category_outlined),
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
          validator: (v) => v == null ? 'Pilih kategori' : null,
        ),
        const SizedBox(height: 14),

        // Harga jual
        TextFormField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Harga Jual', Icons.sell_outlined),
          style: const TextStyle(fontFamily: 'Poppins'),
          onChanged: (v) {
            final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
            _rawPrice = digits.isEmpty ? 0 : int.parse(digits);
            final formatted = digits.isEmpty
                ? ''
                : _rupiahFormatter.format(_rawPrice);
            _priceCtrl.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
          validator: (v) =>
              _rawPrice <= 0 ? 'Harga tidak boleh kosong' : null,
        ),
        const SizedBox(height: 14),

        // Satuan
        DropdownButtonFormField<String>(
          initialValue: _unit,
          decoration: _inputDecoration('Satuan', Icons.straighten),
          items: _units
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u,
                        style: const TextStyle(fontFamily: 'Poppins')),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _unit = v!),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: isActive ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? color : AppTheme.textHint),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: isActive ? color : AppTheme.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}