// lib/screens/add_stock_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/flower_stock.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  // Untuk "Tambah Jumlah Stok"
  FlowerStock? _selectedFlower;
  final _quantityCtrl = TextEditingController();
  String _adjustType = 'add'; // 'add' atau 'subtract'

  // Untuk "Tambah Bunga Baru"
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  String _unit = 'tangkai';

  bool _isLoading = false;

  final List<String> _units = ['tangkai', 'pot', 'lusin', 'ikat', 'buket'];

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _priceCtrl.dispose();
    _costPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_action == StockActionType.adjust) {
        await ApiService.updateStock(
          _selectedFlower!.id,
          int.parse(_quantityCtrl.text.trim()),
          _adjustType,
        );
        _showSuccess('Stok berhasil diperbarui! 🌸');
      } else {
        // POST /stocks — tambah bunga baru
        // Sesuaikan endpoint ini dengan backend kamu
        await ApiService.addNewFlower({
          'name': _nameCtrl.text.trim(),
          'category': _categoryCtrl.text.trim(),
          'stock': int.parse(_stockCtrl.text.trim()),
          'min_stock': int.parse(_minStockCtrl.text.trim()),
          'price': double.parse(_priceCtrl.text.trim()),
          'cost_price': double.parse(_costPriceCtrl.text.trim()),
          'unit': _unit,
        });
        _showSuccess('Bunga baru berhasil ditambahkan! 🌹');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        // Pilih bunga
        DropdownButtonFormField<FlowerStock>(
          initialValue: _selectedFlower,
          decoration: _inputDecoration('Pilih Bunga', Icons.local_florist),
          items: widget.existingStocks
              .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(
                      '${f.name} (${f.stock} ${f.unit})',
                      style:
                          const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedFlower = v),
          validator: (v) => v == null ? 'Pilih bunga dulu' : null,
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

        // Info stok saat ini
        if (_selectedFlower != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildAddNewForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: _inputDecoration('Nama Bunga', Icons.local_florist),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _categoryCtrl,
          decoration: _inputDecoration('Kategori', Icons.category_outlined),
          style: const TextStyle(fontFamily: 'Poppins'),
          validator: (v) =>
              v == null || v.isEmpty ? 'Kategori tidak boleh kosong' : null,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    _inputDecoration('Stok Awal', Icons.inventory_2_outlined),
                style: const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _minStockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    _inputDecoration('Min. Stok', Icons.warning_amber_outlined),
                style: const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Harga Jual', Icons.sell_outlined),
                style: const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _costPriceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    _inputDecoration('Harga Modal', Icons.receipt_outlined),
                style: const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _unit,
          decoration: _inputDecoration('Satuan', Icons.straighten),
          items: _units
              .map((u) => DropdownMenuItem(
                    value: u,
                    child:
                        Text(u, style: const TextStyle(fontFamily: 'Poppins')),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  size: 16, color: isActive ? Colors.white : AppTheme.primary),
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
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? color : AppTheme.textHint),
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
