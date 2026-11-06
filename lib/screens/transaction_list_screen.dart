import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_item.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _searchQuery = '';
  TransactionType? _filterType; // null = all
  String? _filterWalletId; // null = all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);

    // Apply filtering
    final filtered = provider.transactions.where((tx) {
      if (_filterType != null && tx.type != _filterType) return false;
      if (_filterWalletId != null && tx.walletId != _filterWalletId) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(q);
        final matchNote = tx.note?.toLowerCase().contains(q) ?? false;
        final category = CategoryItem.findCategory(tx.categoryId);
        final matchCat = category.name.toLowerCase().contains(q);
        if (!matchTitle && !matchNote && !matchCat) return false;
      }
      return true;
    }).toList();

    // Calculate totals for filtered
    double totalFilteredIncome = 0;
    double totalFilteredExpense = 0;
    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        totalFilteredIncome += tx.amount;
      } else {
        totalFilteredExpense += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Transaksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditTransactionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Type Chips (Semua, Pengeluaran, Pemasukan)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _filterType == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterType = null);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pengeluaran'),
                        selected: _filterType == TransactionType.expense,
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red.shade800,
                        labelStyle: TextStyle(
                          color: _filterType == TransactionType.expense
                              ? Colors.red.shade800
                              : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? TransactionType.expense : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pemasukan'),
                        selected: _filterType == TransactionType.income,
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green.shade800,
                        labelStyle: TextStyle(
                          color: _filterType == TransactionType.income
                              ? Colors.green.shade800
                              : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? TransactionType.income : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Wallet filter dropdown chip
                      PopupMenuButton<String?>(
                        initialValue: _filterWalletId,
                        onSelected: (val) {
                          setState(() => _filterWalletId = val);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('Semua Dompet'),
                          ),
                          ...provider.wallets.map((w) => PopupMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              )),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                          label: Text(
                            _filterWalletId == null
                                ? 'Dompet: Semua'
                                : (provider.getWallet(_filterWalletId!)?.name ?? 'Dompet'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Transaksi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '+${CurrencyFormatter.formatCompact(totalFilteredIncome)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '-${CurrencyFormatter.formatCompact(totalFilteredExpense)}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.hintColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada transaksi yang cocok',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditTransactionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Catat Transaksi Baru'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final wallet = provider.getWallet(tx.walletId);
                      return TransactionItem(
                        transaction: tx,
                        wallet: wallet,
                        onTap: () {
                          _showTransactionDetails(context, tx, wallet, provider);
                        },
                        onDelete: () {
                          provider.deleteTransaction(tx.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionModel tx,
    wallet,
    FinanceProvider provider,
  ) {
    final theme = Theme.of(context);
    final category = CategoryItem.findCategory(tx.categoryId);
    final isIncome = tx.type == TransactionType.income;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(category.icon, color: category.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _detailRow('Tipe', isIncome ? 'Pemasukan' : 'Pengeluaran', theme),
            const SizedBox(height: 8),
            _detailRow('Dompet / Sumber', wallet?.name ?? '-', theme),
            const SizedBox(height: 8),
            _detailRow('Waktu', tx.date.toString().substring(0, 16), theme),
            if (tx.note != null && tx.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow('Catatan', tx.note!, theme),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      provider.deleteTransaction(tx.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditTransactionScreen(
                            transactionToEdit: tx,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Ubah'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.hintColor, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
