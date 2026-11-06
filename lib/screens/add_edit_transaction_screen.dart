import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  final TransactionType? initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.initialType,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  late String _selectedCategoryId;
  late String _selectedWalletId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final editTx = widget.transactionToEdit;
    if (editTx != null) {
      _selectedType = editTx.type;
      _titleController.text = editTx.title;
      _amountController.text = editTx.amount.toInt().toString();
      _selectedCategoryId = editTx.categoryId;
      _selectedWalletId = editTx.walletId;
      _selectedDate = editTx.date;
      _noteController.text = editTx.note ?? '';
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
      _selectedCategoryId = _selectedType == TransactionType.expense
          ? CategoryItem.defaultExpenseCategories.first.id
          : CategoryItem.defaultIncomeCategories.first.id;
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      _selectedWalletId = provider.wallets.isNotEmpty
          ? provider.wallets.first.id
          : 'w_cash';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
        _selectedCategoryId = type == TransactionType.expense
            ? CategoryItem.defaultExpenseCategories.first.id
            : CategoryItem.defaultIncomeCategories.first.id;
      });
    }
  }

  void _addQuickAmount(int delta) {
    final current = int.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + delta).toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      if (!mounted) return;
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (!mounted) return;
      setState(() {
        if (timePicked != null) {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.transactionToEdit != null) {
      final updated = widget.transactionToEdit!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      provider.updateTransaction(widget.transactionToEdit!, updated);
    } else {
      final newTx = TransactionModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      provider.addTransaction(newTx);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);
    final isEditing = widget.transactionToEdit != null;

    final categories = _selectedType == TransactionType.expense
        ? CategoryItem.defaultExpenseCategories
        : CategoryItem.defaultIncomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Transaksi' : 'Catat Transaksi'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Segmented switch (Pengeluaran vs Pemasukan)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.expense
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == TransactionType.expense
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                              color: _selectedType == TransactionType.expense
                                  ? Colors.white
                                  : theme.hintColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TransactionType.expense
                                    ? Colors.white
                                    : theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.income
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == TransactionType.income
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                              color: _selectedType == TransactionType.income
                                  ? Colors.white
                                  : theme.hintColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == TransactionType.income
                                    ? Colors.white
                                    : theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            Text(
              'Nominal (Rp)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _selectedType == TransactionType.expense
                      ? Colors.red.shade700
                      : const Color(0xFF10B981),
                ),
                hintText: '0',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan nominal transaksi';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Quick Amount Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickAmountChip('+10.000', 10000),
                  _quickAmountChip('+20.000', 20000),
                  _quickAmountChip('+50.000', 50000),
                  _quickAmountChip('+100.000', 100000),
                  _quickAmountChip('+500.000', 50000),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title / Description Input
            Text(
              'Judul / Keperluan Transaksi',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _selectedType == TransactionType.expense
                    ? 'Misal: Makan Siang, Beli Kopi, Bensin'
                    : 'Misal: Gaji Pokok, Bonus, Hadiah',
                filled: true,
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan judul transaksi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Kategori',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  avatar: Icon(
                    cat.icon,
                    size: 18,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : theme.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategoryId = cat.id;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Wallet Selection
            Text(
              'Sumber Dompet / Akun',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: provider.wallets.any((w) => w.id == _selectedWalletId)
                  ? _selectedWalletId
                  : (provider.wallets.isNotEmpty ? provider.wallets.first.id : null),
              decoration: InputDecoration(
                filled: true,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: provider.wallets.map((w) {
                return DropdownMenuItem<String>(
                  value: w.id,
                  child: Row(
                    children: [
                      Icon(w.icon, color: w.color, size: 20),
                      const SizedBox(width: 10),
                      Text(w.name),
                      const SizedBox(width: 8),
                      Text(
                        '(${CurrencyFormatter.formatCompact(w.balance)})',
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedWalletId = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Date & Time Picker
            Text(
              'Tanggal & Waktu',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
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
                    const Icon(Icons.calendar_month, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${DateFormatter.formatFull(_selectedDate)} • ${DateFormatter.formatTime(_selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes / Catatan
            Text(
              'Catatan Tambahan (Opsional)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Keterangan tambahan...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _saveTransaction,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _selectedType == TransactionType.expense
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isEditing ? 'Simpan Perubahan' : 'Catat Transaksi Sekarang',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountChip(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        onPressed: () => _addQuickAmount(amount),
      ),
    );
  }
}
