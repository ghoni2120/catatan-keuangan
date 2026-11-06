import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/debt.dart';
import '../providers/finance_provider.dart';
import '../utils/date_formatter.dart';

class AddDebtScreen extends StatefulWidget {
  final DebtType? initialType;

  const AddDebtScreen({super.key, this.initialType});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidController = TextEditingController();
  final _noteController = TextEditingController();

  late DebtType _selectedType;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? DebtType.debt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _saveDebt() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final initialPaid = double.tryParse(_paidController.text.trim()) ?? 0;
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    final newDebt = DebtItem(
      id: const Uuid().v4(),
      personName: _nameController.text.trim(),
      type: _selectedType,
      amount: amount,
      paidAmount: initialPaid > amount ? amount : initialPaid,
      dueDate: _selectedDueDate,
      createdAt: DateTime.now(),
      notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    provider.addDebt(newDebt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebt = _selectedType == DebtType.debt;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDebt ? 'Catat Utang Baru' : 'Catat Piutang Baru'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
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
                      onTap: () => setState(() => _selectedType = DebtType.debt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == DebtType.debt
                              ? Colors.red.shade700
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == DebtType.debt
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
                        child: Text(
                          'Utang (Saya Berutang)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == DebtType.debt
                                ? Colors.white
                                : theme.hintColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = DebtType.receivable),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == DebtType.receivable
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == DebtType.receivable
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Piutang (Dia Berutang)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == DebtType.receivable
                                ? Colors.white
                                : theme.hintColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Person name
            Text(
              isDebt ? 'Nama Pemberi Pinjaman' : 'Nama Peminjam (Yang Berutang)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: isDebt ? 'Misal: Budi, Bank Mandiri, Teman Kantor' : 'Misal: Rian, Adik, Teman Kampus',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Masukkan nama pihak';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Total Amount
            Text(
              'Total Nominal Pinjaman (Rp)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
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
                  return 'Masukkan total pinjaman';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Initial Paid Amount (optional)
            Text(
              'Sudah Dibayar Sebelumnya (Opsional)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0 (jika belum ada pembayaran)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Due Date
            Text(
              'Jatuh Tempo / Tenggat Pembayaran',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormatter.formatFull(_selectedDueDate!)
                            : 'Pilih Tanggal Jatuh Tempo (Opsional)',
                        style: TextStyle(
                          color: _selectedDueDate != null ? null : theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _selectedDueDate = null),
                      )
                    else
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            Text(
              'Catatan / Keperluan (Opsional)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Alasan pinjam, kesepakatan cicilan, dll...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _saveDebt,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDebt ? Colors.red.shade700 : const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isDebt ? 'Simpan Data Utang' : 'Simpan Data Piutang',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
