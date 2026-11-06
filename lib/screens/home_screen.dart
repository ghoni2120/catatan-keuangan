import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/savings_item_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/wallet_card.dart';
import 'add_debt_screen.dart';
import 'add_edit_transaction_screen.dart';
import 'add_savings_screen.dart';
import 'wallets_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Yang Ingin Dicatat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _actionTile(
              context: context,
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFEF4444),
              title: 'Catat Pengeluaran',
              subtitle: 'Uang keluar belanja, makanan, tagihan, dll.',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditTransactionScreen(
                      initialType: TransactionType.expense,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context: context,
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF10B981),
              title: 'Catat Pemasukan',
              subtitle: 'Uang masuk gaji, bonus, freelance, dll.',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditTransactionScreen(
                      initialType: TransactionType.income,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context: context,
              icon: Icons.handshake_outlined,
              color: const Color(0xFF2563EB),
              title: 'Catat Utang / Piutang',
              subtitle: 'Pinjaman ke orang lain atau pinjaman diterima',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context: context,
              icon: Icons.savings_outlined,
              color: const Color(0xFF0D9488),
              title: 'Buat Target Tabungan',
              subtitle: 'Target dana impian, laptop, liburan, darurat',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSavingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final recentTransactions = provider.transactions.take(5).toList();
    final topSavings = provider.savings.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wallet, color: Color(0xFF0D9488), size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Keuangan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Halo, Selamat Datang! 👋',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Ganti Tema',
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'reset') {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Reset Data Sample?'),
                    content: const Text(
                        'Semua data akan dikembalikan ke data awal contoh. Cocok untuk demo aplikasi.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        onPressed: () {
                          provider.resetAllData();
                          Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data berhasil di-reset')),
                          );
                        },
                        child: const Text('Reset Data'),
                      ),
                    ],
                  ),
                );
              } else if (val == 'wallets') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletsScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'wallets',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Kelola Dompet'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 20, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Muat Ulang Data Contoh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadData();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Total Balance Summary Card
            SummaryCard(
              totalBalance: provider.totalWalletBalance,
              incomeMonth: provider.totalIncomeThisMonth,
              expenseMonth: provider.totalExpenseThisMonth,
              totalDebt: provider.totalDebt,
              totalReceivable: provider.totalReceivable,
              onAddTap: () => _showQuickAddSheet(context),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons Grid
            Row(
              children: [
                _quickActionButton(
                  context: context,
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFF10B981),
                  label: 'Pemasukan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditTransactionScreen(
                          initialType: TransactionType.income,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _quickActionButton(
                  context: context,
                  icon: Icons.remove_circle_outline,
                  color: const Color(0xFFEF4444),
                  label: 'Pengeluaran',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditTransactionScreen(
                          initialType: TransactionType.expense,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _quickActionButton(
                  context: context,
                  icon: Icons.handshake_outlined,
                  color: const Color(0xFF2563EB),
                  label: 'Utang Piutang',
                  onTap: () => onNavigateTab(2), // Tab Utang
                ),
                const SizedBox(width: 10),
                _quickActionButton(
                  context: context,
                  icon: Icons.savings_outlined,
                  color: const Color(0xFF0D9488),
                  label: 'Tabungan',
                  onTap: () => onNavigateTab(3), // Tab Tabungan
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Wallets Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dompet & Rekening',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletsScreen()),
                    );
                  },
                  child: const Text('Kelola Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 115,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.wallets.length + 1,
                itemBuilder: (context, index) {
                  if (index < provider.wallets.length) {
                    final wallet = provider.wallets[index];
                    return WalletCard(
                      wallet: wallet,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletsScreen()),
                        );
                      },
                    );
                  }
                  // Add new wallet card
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: theme.colorScheme.primary, size: 28),
                          const SizedBox(height: 6),
                          const Text(
                            'Tambah\nDompet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Savings Goals Section
            if (topSavings.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target Tabungan Aktif',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(3),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...topSavings.map(
                (goal) => SavingsItemCard(
                  goal: goal,
                  onTap: () => onNavigateTab(3),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(1),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (recentTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    'Belum ada transaksi dicatat',
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
              )
            else
              ...recentTransactions.map((tx) {
                final wallet = provider.getWallet(tx.walletId);
                return TransactionItem(
                  transaction: tx,
                  wallet: wallet,
                  onTap: () => onNavigateTab(1),
                  onDelete: () => provider.deleteTransaction(tx.id),
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _quickActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
