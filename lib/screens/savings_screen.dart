import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/savings_item_card.dart';
import 'add_savings_screen.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showDepositDialog(BuildContext context, SavingsGoal goal, FinanceProvider provider) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedWalletId = provider.wallets.isNotEmpty
        ? provider.wallets.first.id
        : 'w_cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Setor Tabungan: ${goal.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa target: ${CurrencyFormatter.format(goal.remainingAmount)}',
                    style: TextStyle(
                      color: goal.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nominal Setoran (Rp)',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
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
                  const Text('Ambil Dari Dompet:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                            const SizedBox(width: 6),
                            Text(
                              '(${CurrencyFormatter.formatCompact(w.balance)})',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor, fontSize: 11),
                            ),
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
                      hintText: 'Misal: Sisa uang jajan, bonus mingguan',
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

                  final wallet = provider.getWallet(selectedWalletId);
                  if (wallet != null && wallet.balance < amount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saldo dompet tidak mencukupi untuk setoran'),
                      ),
                    );
                    return;
                  }

                  provider.depositToSavings(
                    goalId: goal.id,
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
                        'Berhasil menyetor ${CurrencyFormatter.format(amount)} ke "${goal.title}"',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: goal.color),
                child: const Text('Setor Sekarang'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, SavingsGoal goal, FinanceProvider provider) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedWalletId = provider.wallets.isNotEmpty
        ? provider.wallets.first.id
        : 'w_cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Tarik Tabungan: ${goal.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo tabungan saat ini: ${CurrencyFormatter.format(goal.currentAmount)}',
                    style: TextStyle(
                      color: goal.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nominal Penarikan (Rp)',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
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
                  const Text('Kirim ke Dompet:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                  const Text('Alasan Penarikan (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Kebutuhan mendesak / target dibeli',
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

                  if (amount > goal.currentAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nominal melebihi saldo tabungan saat ini'),
                      ),
                    );
                    return;
                  }

                  provider.withdrawFromSavings(
                    goalId: goal.id,
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
                        'Berhasil menarik ${CurrencyFormatter.format(amount)} dari "${goal.title}"',
                      ),
                    ),
                  );
                },
                child: const Text('Tarik Dana'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGoalDetails(BuildContext context, SavingsGoal goal, FinanceProvider provider) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(goal.icon, color: goal.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal.isCompleted ? 'Target Tercapai 🎉' : 'Dalam Proses Menabung',
                        style: TextStyle(
                          color: goal.isCompleted ? const Color(0xFF10B981) : goal.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSavingsScreen(goalToEdit: goal),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Hapus Target Tabungan?'),
                        content: Text('Yakin ingin menghapus "${goal.title}"?'),
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
                      provider.deleteSavingsGoal(goal.id);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statBox('Terkumpul', CurrencyFormatter.format(goal.currentAmount),
                    valueColor: goal.color),
                _statBox('Target', CurrencyFormatter.format(goal.targetAmount)),
                _statBox('Sisa', CurrencyFormatter.format(goal.remainingAmount)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kemajuan: ${(goal.progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: theme.hintColor, fontSize: 12)),
                if (goal.targetDate != null)
                  Text('Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                      style: TextStyle(color: theme.hintColor, fontSize: 12)),
              ],
            ),
            if (goal.notes != null && goal.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Catatan: ${goal.notes!}', style: TextStyle(color: theme.hintColor)),
            ],
            const Divider(height: 28),
            const Text('Riwayat Setoran & Penarikan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (goal.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Belum ada riwayat transaksi tabungan',
                      style: TextStyle(color: theme.hintColor)),
                ),
              )
            else
              ...goal.logs.map((log) {
                final isDeposit = log.type == SavingsLogType.deposit;
                final wallet = provider.getWallet(log.walletId);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDeposit
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    child: Icon(
                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDeposit ? const Color(0xFF10B981) : Colors.orange,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(log.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDeposit ? const Color(0xFF10B981) : Colors.orange,
                    ),
                  ),
                  subtitle: Text(
                    '${isDeposit ? 'Setor' : 'Tarik'} • ${DateFormatter.formatDate(log.date)} via ${wallet?.name ?? 'Dompet'}${log.notes != null ? ' (${log.notes})' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Row(
              children: [
                if (goal.currentAmount > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showWithdrawDialog(context, goal, provider);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.remove),
                      label: const Text('Tarik'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDepositDialog(context, goal, provider);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: goal.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Setor Tabungan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

    final totalSaved = provider.totalSavedInGoals;
    final totalTarget = provider.totalTargetInGoals;
    final overallProgress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan & Impian'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Buat Target Baru',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSavingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Overall Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F766E),
                  const Color(0xFF14B8A6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Akumulasi Tabungan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}% Tercapai',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(totalSaved),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dari target total ${CurrencyFormatter.format(totalTarget)} (${provider.savings.length} Impian)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // List of Savings Goals
          Expanded(
            child: provider.savings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 64,
                          color: theme.hintColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada target tabungan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rencanakan impian Anda dan mulai menabung sekarang',
                          style: TextStyle(color: theme.hintColor, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddSavingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Target Tabungan'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.savings.length,
                    itemBuilder: (context, index) {
                      final goal = provider.savings[index];
                      return SavingsItemCard(
                        goal: goal,
                        onTap: () => _showGoalDetails(context, goal, provider),
                        onDeposit: () => _showDepositDialog(context, goal, provider),
                        onWithdraw: () => _showWithdrawDialog(context, goal, provider),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSavingsScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Target Baru'),
      ),
    );
  }
}
