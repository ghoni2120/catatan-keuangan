import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/savings_goal.dart';
import '../providers/finance_provider.dart';
import '../utils/date_formatter.dart';

class AddSavingsScreen extends StatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddSavingsScreen({super.key, this.goalToEdit});

  @override
  State<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialDepositController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedTargetDate;
  IconData _selectedIcon = Icons.savings;
  Color _selectedColor = const Color(0xFF0D9488);
  String? _selectedWalletId;

  final List<IconData> _availableIcons = [
    Icons.savings,
    Icons.shield,
    Icons.laptop_mac,
    Icons.beach_access,
    Icons.directions_car,
    Icons.home,
    Icons.phone_iphone,
    Icons.school,
    Icons.flight,
    Icons.favorite,
    Icons.shopping_bag,
    Icons.diamond,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF0D9488), // Teal
    const Color(0xFF2563EB), // Blue
    const Color(0xFF7C3AED), // Purple
    const Color(0xFFDB2777), // Pink
    const Color(0xFFEA580C), // Orange
    const Color(0xFF16A34A), // Green
    const Color(0xFF475569), // Slate
    const Color(0xFFCA8A04), // Amber
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.goalToEdit;
    if (edit != null) {
      _titleController.text = edit.title;
      _targetAmountController.text = edit.targetAmount.toInt().toString();
      _selectedTargetDate = edit.targetDate;
      _selectedIcon = edit.icon;
      _selectedColor = edit.color;
      _noteController.text = edit.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialDepositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedTargetDate = picked);
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final targetAmount = double.tryParse(_targetAmountController.text.trim()) ?? 0;
    if (targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target nominal harus lebih dari 0')),
      );
      return;
    }

    final initialDeposit = double.tryParse(_initialDepositController.text.trim()) ?? 0;
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.goalToEdit != null) {
      final updated = widget.goalToEdit!.copyWith(
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _selectedTargetDate,
        icon: _selectedIcon,
        color: _selectedColor,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      provider.updateSavingsGoal(updated);
    } else {
      final goalId = const Uuid().v4();
      final newGoal = SavingsGoal(
        id: goalId,
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: _selectedTargetDate,
        createdAt: DateTime.now(),
        icon: _selectedIcon,
        color: _selectedColor,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      provider.addSavingsGoal(newGoal);

      // If initial deposit specified
      if (initialDeposit > 0 && _selectedWalletId != null) {
        provider.depositToSavings(
          goalId: goalId,
          amount: initialDeposit,
          walletId: _selectedWalletId!,
          notes: 'Setoran awal tabungan',
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);
    final isEditing = widget.goalToEdit != null;

    if (_selectedWalletId == null && provider.wallets.isNotEmpty) {
      _selectedWalletId = provider.wallets.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Target Tabungan' : 'Buat Target Tabungan Baru'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview Card Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_selectedIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty
                              ? 'Nama Impian Keuangan'
                              : _titleController.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wujudkan impian finansial Anda selangkah demi selangkah',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Goal Title
            Text('Nama Target / Impian',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Misal: Beli Laptop Baru, Liburan ke Bali, Dana Darurat',
                prefixIcon: const Icon(Icons.star_outline),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan nama target tabungan';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Target Amount
            Text('Target Nominal Dana (Rp)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan nominal target';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Initial deposit (only when creating new)
            if (!isEditing) ...[
              Text('Setoran Awal (Opsional)',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _initialDepositController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0 (jika ingin langsung setor)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.wallets.isNotEmpty) ...[
                Text('Sumber Dompet untuk Setoran Awal',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedWalletId,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: provider.wallets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (${w.balance.toInt()})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWalletId = val),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Target Date
            Text('Target Tanggal Selesai (Opsional)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTargetDate != null
                            ? DateFormatter.formatFull(_selectedTargetDate!)
                            : 'Pilih Target Tanggal Tercapai',
                        style: TextStyle(
                          color: _selectedTargetDate != null ? null : theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedTargetDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _selectedTargetDate = null),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon Picker
            Text('Pilih Ikon Impian',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor
                          : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : theme.iconTheme.color,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color Picker
            Text('Pilih Warna Tema',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            Text('Catatan / Alasan Menabung (Opsional)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Motivasi atau catatan khusus...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton(
              onPressed: _saveGoal,
              style: FilledButton.styleFrom(
                backgroundColor: _selectedColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isEditing ? 'Simpan Perubahan' : 'Buat Target Tabungan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
