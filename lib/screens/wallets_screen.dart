import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/wallet.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _showAddWalletDialog(BuildContext context, FinanceProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    WalletType selectedType = WalletType.bank;
    IconData selectedIcon = Icons.account_balance;
    Color selectedColor = Colors.blue;

    final icons = [
      Icons.account_balance,
      Icons.payments,
      Icons.account_balance_wallet,
      Icons.credit_card,
      Icons.savings,
      Icons.phone_android,
    ];

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.teal,
      Colors.purple,
      Colors.orange,
      Colors.redAccent,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Tambah Dompet / Akun'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Dompet / Rekening',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Bank Mandiri, Dompet Tunai, OVO',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Saldo Awal (Rp)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Tipe Akun',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<WalletType>(
                    segments: const [
                      ButtonSegment(value: WalletType.cash, label: Text('Tunai')),
                      ButtonSegment(value: WalletType.bank, label: Text('Bank')),
                      ButtonSegment(value: WalletType.ewallet, label: Text('E-Wallet')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() {
                        selectedType = set.first;
                        if (selectedType == WalletType.cash) {
                          selectedIcon = Icons.payments;
                          selectedColor = Colors.green;
                        } else if (selectedType == WalletType.bank) {
                          selectedIcon = Icons.account_balance;
                          selectedColor = Colors.blue;
                        } else {
                          selectedIcon = Icons.account_balance_wallet;
                          selectedColor = Colors.teal;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Ikon',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : null,
                            size: 20,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Pilih Warna',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colors.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
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
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final balance = double.tryParse(balanceController.text.trim()) ?? 0;

                  final wallet = Wallet(
                    id: const Uuid().v4(),
                    name: name,
                    type: selectedType,
                    balance: balance,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  provider.addWallet(wallet);
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransferDialog(BuildContext context, FinanceProvider provider,
      {String? initialFromId}) {
    if (provider.wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda membutuhkan minimal 2 dompet untuk transfer saldo'),
        ),
      );
      return;
    }

    String fromId = initialFromId ?? provider.wallets.first.id;
    String toId = provider.wallets.firstWhere((w) => w.id != fromId).id;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final fromWallet = provider.getWallet(fromId);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Transfer Antar Dompet'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dari Dompet:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: fromId,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: provider.wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${CurrencyFormatter.formatCompact(w.balance)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          fromId = val;
                          if (toId == fromId) {
                            toId = provider.wallets.firstWhere((w) => w.id != fromId).id;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Ke Dompet:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: toId,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: provider.wallets.where((w) => w.id != fromId).map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${CurrencyFormatter.formatCompact(w.balance)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => toId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Nominal Transfer (Rp)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Catatan (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Tarik tunai ATM, Top up e-wallet',
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
                  if (fromWallet != null && fromWallet.balance < amount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saldo dompet asal tidak mencukupi')),
                    );
                    return;
                  }

                  provider.transferWalletBalance(
                    fromWalletId: fromId,
                    toWalletId: toId,
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer saldo berhasil dilakukan!')),
                  );
                },
                child: const Text('Transfer Sekarang'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dompet & Akun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer Antar Dompet',
            onPressed: () => _showTransferDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Dompet Baru',
            onPressed: () => _showAddWalletDialog(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Balance Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Seluruh Dompet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(provider.totalWalletBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: () => _showTransferDialog(context, provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 18),
                      SizedBox(width: 4),
                      Text('Transfer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Daftar Dompet & Rekening (${provider.wallets.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...provider.wallets.map((wallet) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: wallet.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(wallet.icon, color: wallet.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            wallet.type.name.toUpperCase(),
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(wallet.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: wallet.balance < 0 ? Colors.red : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _showTransferDialog(
                                context,
                                provider,
                                initialFromId: wallet.id,
                              ),
                              child: Text(
                                'Transfer',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Dompet Baru'),
      ),
    );
  }
}
