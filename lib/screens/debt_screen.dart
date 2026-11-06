import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/debt_item_card.dart';
import 'add_debt_screen.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnlyUnpaid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPaymentDialog(BuildContext context, DebtItem debt, FinanceProvider provider) {
    final amountController = TextEditingController(
      text: debt.remainingAmount.toInt().toString(),
    );
    final noteController = TextEditingController();
    String selectedWalletId = provider.wallets.isNotEmpty
        ? provider.wallets.first.id
        : 'w_cash';

    final isDebt = debt.type == DebtType.debt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isDebt ? 'Bayar Cicilan Utang' : 'Catat Pelunasan Piutang'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pihak: ${debt.personName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sisa tagihan: ${CurrencyFormatter.format(debt.remainingAmount)}',
                    style: TextStyle(
                      color: isDebt ? Colors.red.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nominal Pembayaran (Rp)',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isDebt ? 'Bayar Menggunakan Dompet:' : 'Terima ke Dompet:',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedWalletId,
                    decoration: InputDecoration(
                      filled: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: provider.wallets.map((w) {
                      return DropdownMenuItem<String>(
                        value: w.id,
                        child: Row(
                          children: [
                            Icon(w.icon, color: w.color, size: 18),
                            const SizedBox(width: 8),
                            Text(w.name, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedWalletId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Catatan (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Cicilan ke-1 via transfer',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0) return;

                  provider.payDebt(
                    debtId: debt.id,
                    amount: amount,
                    walletId: selectedWalletId,
                    notes: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isDebt
                            ? 'Berhasil mencatat pembayaran utang Rp ${CurrencyFormatter.formatWithoutSymbol(amount)}'
                            : 'Berhasil mencatat pelunasan piutang Rp ${CurrencyFormatter.formatWithoutSymbol(amount)}',
                      ),
                    ),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDebtDetails(BuildContext context, DebtItem debt, FinanceProvider provider) {
    final theme = Theme.of(context);
    final isDebt = debt.type == DebtType.debt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  debt.personName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Hapus Catatan Ini?'),
                        content: const Text('Catatan utang/piutang ini akan dihapus permanen.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      provider.deleteDebt(debt.id);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isDebt
                  ? 'Utang Saya (Uang dipinjam dari ${debt.personName})'
                  : 'Piutang (Dipinjam oleh ${debt.personName})',
              style: TextStyle(
                color: isDebt ? Colors.red.shade600 : Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statBox('Total Pinjaman', CurrencyFormatter.format(debt.amount), theme),
                _statBox('Sudah Dibayar', CurrencyFormatter.format(debt.paidAmount), theme),
                _statBox(
                  'Sisa Tagihan',
                  CurrencyFormatter.format(debt.remainingAmount),
                  theme,
                  valueColor: isDebt ? Colors.red.shade700 : Colors.blue.shade700,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (debt.dueDate != null) ...[
              Text(
                'Jatuh Tempo: ${DateFormatter.formatFull(debt.dueDate!)}',
                style: TextStyle(
                  color: debt.isOverdue ? Colors.red : theme.hintColor,
                  fontWeight: debt.isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (debt.notes != null && debt.notes!.isNotEmpty) ...[
              Text('Catatan: ${debt.notes!}', style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 16),
            ],
            const Divider(height: 28),
            const Text(
              'Riwayat Pembayaran / Cicilan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (debt.payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Belum ada riwayat pembayaran',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              )
            else
              ...debt.payments.map((p) {
                final wallet = provider.getWallet(p.walletId);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    CurrencyFormatter.format(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${DateFormatter.formatDate(p.date)} via ${wallet?.name ?? 'Dompet'}${p.notes != null ? ' • ${p.notes}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
            const SizedBox(height: 20),
            if (!debt.isPaidOff)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPaymentDialog(context, debt, provider);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isDebt ? Colors.red.shade700 : const Color(0xFF2563EB),
                ),
                icon: const Icon(Icons.payment),
                label: Text(isDebt ? 'Bayar Cicilan Utang' : 'Catat Pelunasan Piutang'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.hintColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);

    final myDebts = provider.debts
        .where((d) => d.type == DebtType.debt)
        .where((d) => !_showOnlyUnpaid || !d.isPaidOff)
        .toList();

    final myReceivables = provider.debts
        .where((d) => d.type == DebtType.receivable)
        .where((d) => !_showOnlyUnpaid || !d.isPaidOff)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utang & Piutang'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyUnpaid ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            tooltip: _showOnlyUnpaid ? 'Tampilkan Semua' : 'Hanya Belum Lunas',
            onPressed: () {
              setState(() => _showOnlyUnpaid = !_showOnlyUnpaid);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Catatan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDebtScreen(
                    initialType: _tabController.index == 0
                        ? DebtType.debt
                        : DebtType.receivable,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Utang Saya (${myDebts.length})'),
            Tab(text: 'Piutang (${myReceivables.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary cards at the top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Utang Saya',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(provider.totalDebt),
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Piutang Saya',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(provider.totalReceivable),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Utang List
                _buildDebtList(myDebts, provider, isDebtTab: true),
                // Piutang List
                _buildDebtList(myReceivables, provider, isDebtTab: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDebtScreen(
                initialType: _tabController.index == 0
                    ? DebtType.debt
                    : DebtType.receivable,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Catat Utang' : 'Catat Piutang'),
      ),
    );
  }

  Widget _buildDebtList(
    List<DebtItem> list,
    FinanceProvider provider, {
    required bool isDebtTab,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDebtTab ? Icons.check_circle_outline : Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isDebtTab
                  ? 'Bagus! Tidak ada catatan utang'
                  : 'Tidak ada piutang tercatat',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isDebtTab
                  ? 'Keuangan Anda aman dan bebas tanggungan'
                  : 'Catat uang yang dipinjam oleh teman atau keluarga',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final debt = list[index];
        return DebtItemCard(
          debt: debt,
          onTap: () => _showDebtDetails(context, debt, provider),
          onPayTap: () => _showPaymentDialog(context, debt, provider),
        );
      },
    );
  }
}
