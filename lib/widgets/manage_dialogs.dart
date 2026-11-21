import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../providers/finance_provider.dart';
import '../utils/api_action.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

// =====================================================================
// Dialog pengelolaan data: ubah, koreksi, hapus, dan batalkan.
// Semua fungsi memakai runApi (spinner + pesan error) dan mengembalikan
// true jika perubahan berhasil, supaya pemanggil bisa menutup bottom sheet.
// =====================================================================

InputDecoration _fieldDecoration({String? hint, String? prefix}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefix,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

Widget _label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  );
}

void _info(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          style: danger ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

// ---------------------------------------------------------------------
// DOMPET
// ---------------------------------------------------------------------

/// Ubah nama, jenis, ikon, dan warna dompet. (Saldo diubah lewat "Koreksi Saldo".)
Future<void> showEditWalletDialog(BuildContext context, Wallet wallet) async {
  final provider = context.read<FinanceProvider>();
  final nameController = TextEditingController(text: wallet.name);
  var selectedType = wallet.type == WalletType.other ? WalletType.cash : wallet.type;
  var selectedIcon = wallet.icon;
  var selectedColor = wallet.color;

  const icons = <IconData>[
    Icons.account_balance,
    Icons.payments,
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.phone_android,
  ];
  const colors = <Color>[
    Colors.blue,
    Colors.green,
    Colors.teal,
    Colors.purple,
    Colors.orange,
    Colors.redAccent,
  ];

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ubah Dompet / Akun'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Nama Dompet / Rekening'),
                TextField(
                  controller: nameController,
                  decoration: _fieldDecoration(hint: 'Misal: Bank Mandiri, OVO'),
                ),
                const SizedBox(height: 14),
                _label('Tipe Akun'),
                SegmentedButton<WalletType>(
                  segments: const [
                    ButtonSegment(value: WalletType.cash, label: Text('Tunai')),
                    ButtonSegment(value: WalletType.bank, label: Text('Bank')),
                    ButtonSegment(value: WalletType.ewallet, label: Text('E-Wallet')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (set) => setDialogState(() => selectedType = set.first),
                ),
                const SizedBox(height: 16),
                _label('Pilih Ikon'),
                Wrap(
                  spacing: 8,
                  children: icons.map((icon) {
                    final isSelected = selectedIcon.codePoint == icon.codePoint;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor
                              : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : null, size: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _label('Pilih Warna'),
                Wrap(
                  spacing: 8,
                  children: colors.map((c) {
                    final isSelected = selectedColor.value == c.value;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = c),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final updated = Wallet(
                  id: wallet.id,
                  name: name,
                  type: selectedType,
                  balance: wallet.balance,
                  icon: selectedIcon,
                  color: selectedColor,
                );
                final ok = await runApi(context, () => provider.updateWallet(updated));
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}

/// Koreksi saldo: selisih dengan saldo sebenarnya dicatat sebagai transaksi "Koreksi Saldo".
Future<void> showAdjustBalanceDialog(BuildContext context, Wallet wallet) async {
  final provider = context.read<FinanceProvider>();
  final controller = TextEditingController(text: wallet.balance.round().toString());

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Koreksi Saldo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo tercatat: ${CurrencyFormatter.format(wallet.balance)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Masukkan saldo yang sebenarnya. Selisihnya dicatat sebagai transaksi "Koreksi Saldo" agar riwayat tetap rapi.',
              style: TextStyle(fontSize: 12, color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 14),
            _label('Saldo Sebenarnya (Rp)'),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration(prefix: 'Rp '),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          onPressed: () async {
            final target = int.tryParse(controller.text.trim());
            if (target == null) return;
            final diff = target - wallet.balance.round();
            if (diff == 0) {
              Navigator.pop(ctx);
              return;
            }
            final isIncome = diff > 0;
            final adjustment = TransactionModel(
              id: '',
              title: 'Koreksi Saldo: ${wallet.name}',
              amount: diff.abs().toDouble(),
              type: isIncome ? TransactionType.income : TransactionType.expense,
              categoryId: isIncome ? 'inc_other' : 'exp_other',
              walletId: wallet.id,
              date: DateTime.now(),
              note:
                  'Penyesuaian saldo dari ${CurrencyFormatter.format(wallet.balance)} menjadi ${CurrencyFormatter.format(target.toDouble())}',
            );
            final ok = await runApi(context, () => provider.addTransaction(adjustment));
            if (ok && ctx.mounted) Navigator.pop(ctx);
            if (ok && context.mounted) _info(context, 'Saldo "${wallet.name}" dikoreksi');
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

/// Hapus dompet. Jika punya riwayat, pengguna memilih dompet tujuan untuk memindahkan
/// seluruh riwayat dan saldonya.
Future<void> confirmDeleteWallet(BuildContext context, Wallet wallet) async {
  final provider = context.read<FinanceProvider>();

  if (provider.wallets.length <= 1) {
    _info(context, 'Minimal harus ada satu dompet. Buat dompet lain sebelum menghapus yang ini.');
    return;
  }

  final usage = provider.walletUsageCount(wallet.id);
  if (usage == 0) {
    final ok = await _confirm(
      context,
      title: 'Hapus "${wallet.name}"?',
      message: 'Dompet ini belum punya riwayat dan akan dihapus permanen.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    final done = await runApi(context, () => provider.deleteWallet(wallet.id));
    if (done && context.mounted) _info(context, 'Dompet "${wallet.name}" dihapus');
    return;
  }

  final targets = provider.wallets.where((w) => w.id != wallet.id).toList();
  String targetId = targets.first.id;

  final chosen = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Hapus "${wallet.name}"?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dompet ini punya $usage catatan riwayat. Semua riwayat dan saldonya '
                  '(${CurrencyFormatter.format(wallet.balance)}) akan dipindahkan ke dompet:',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: targetId,
                  decoration: _fieldDecoration(),
                  items: targets
                      .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => targetId = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, targetId),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Pindahkan & Hapus'),
            ),
          ],
        );
      },
    ),
  );
  if (chosen == null || !context.mounted) return;

  final done = await runApi(
    context,
    () => provider.deleteWallet(wallet.id, moveToWalletId: chosen),
  );
  if (done && context.mounted) {
    _info(context, 'Dompet "${wallet.name}" dihapus, riwayatnya dipindahkan');
  }
}

// ---------------------------------------------------------------------
// UTANG & PIUTANG
// ---------------------------------------------------------------------

/// Ubah nama, total, jatuh tempo, dan catatan. Jenis (utang/piutang) tidak bisa diubah.
Future<bool> showEditDebtDialog(BuildContext context, DebtItem debt) async {
  final provider = context.read<FinanceProvider>();
  final nameController = TextEditingController(text: debt.personName);
  final amountController = TextEditingController(text: debt.amount.round().toString());
  final notesController = TextEditingController(text: debt.notes ?? '');
  DateTime? dueDate = debt.dueDate;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(debt.type == DebtType.debt ? 'Ubah Catatan Utang' : 'Ubah Catatan Piutang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Nama Orang / Pihak'),
                TextField(controller: nameController, decoration: _fieldDecoration()),
                const SizedBox(height: 14),
                _label('Total (Rp)'),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration(prefix: 'Rp '),
                ),
                if (debt.paidAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sudah dibayar ${CurrencyFormatter.format(debt.paidAmount)} (total tidak boleh lebih kecil)',
                    style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor),
                  ),
                ],
                const SizedBox(height: 14),
                _label('Jatuh Tempo'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setDialogState(() => dueDate = picked);
                        },
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(
                          dueDate == null ? 'Tanpa jatuh tempo' : DateFormatter.formatFull(dueDate!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (dueDate != null)
                      IconButton(
                        tooltip: 'Hapus jatuh tempo',
                        icon: const Icon(Icons.close),
                        onPressed: () => setDialogState(() => dueDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Catatan'),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: _fieldDecoration(hint: 'Opsional'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = int.tryParse(amountController.text.trim());
                if (name.isEmpty || amount == null || amount <= 0) return;
                final notes = notesController.text.trim();
                final updated = DebtItem(
                  id: debt.id,
                  personName: name,
                  type: debt.type,
                  amount: amount.toDouble(),
                  paidAmount: debt.paidAmount,
                  dueDate: dueDate,
                  createdAt: debt.createdAt,
                  notes: notes.isEmpty ? null : notes,
                  payments: debt.payments,
                );
                final ok = await runApi(context, () => provider.updateDebt(updated));
                if (ok && ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
  return saved == true;
}

/// Hapus catatan utang/piutang. Jika sudah ada pembayaran, pengguna memilih:
/// membatalkan semua pembayaran (saldo dikembalikan) atau hanya menghapus catatan.
Future<bool> confirmDeleteDebt(BuildContext context, DebtItem debt) async {
  final provider = context.read<FinanceProvider>();
  final hasPayments = debt.payments.isNotEmpty;
  final label = debt.type == DebtType.debt ? 'utang' : 'piutang';

  if (!hasPayments) {
    final ok = await _confirm(
      context,
      title: 'Hapus catatan ini?',
      message: 'Catatan $label "${debt.personName}" akan dihapus permanen.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !context.mounted) return false;
    final done = await runApi(context, () => provider.deleteDebt(debt.id));
    if (done && context.mounted) _info(context, 'Catatan dihapus');
    return done;
  }

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(debt.isPaidOff ? 'Catatan sudah lunas' : 'Hapus catatan ini?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              debt.isPaidOff
                  ? 'Catatan $label "${debt.personName}" sudah lunas. Hapus agar daftar tetap rapi.'
                  : 'Catatan $label "${debt.personName}" sudah punya ${debt.payments.length} pembayaran. Pilih cara menghapusnya:',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'keep'),
              style: FilledButton.styleFrom(
                backgroundColor: debt.isPaidOff ? const Color(0xFF10B981) : Colors.red,
              ),
              child: const Text('Hapus catatan saja'),
            ),
            const SizedBox(height: 4),
            Text(
              'Uang yang sudah dibayar tetap tercatat di riwayat transaksi.',
              style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'revert'),
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Batalkan pembayaran & hapus'),
            ),
            const SizedBox(height: 4),
            Text(
              'Saldo dompet dikembalikan seperti sebelum ada pembayaran. Cocok jika catatan ini tidak jadi.',
              style: TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;

  final done = await runApi(
    context,
    () => provider.deleteDebt(debt.id, revertPayments: choice == 'revert'),
  );
  if (done && context.mounted) {
    _info(
      context,
      choice == 'revert'
          ? 'Catatan dihapus dan pembayaran dibatalkan'
          : 'Catatan dihapus',
    );
  }
  return done;
}

Future<bool> confirmCancelDebtPayment(
  BuildContext context,
  DebtItem debt,
  DebtPayment payment,
) async {
  final provider = context.read<FinanceProvider>();
  final wallet = provider.getWallet(payment.walletId);
  final isDebt = debt.type == DebtType.debt;

  final ok = await _confirm(
    context,
    title: 'Batalkan pembayaran ini?',
    message:
        'Pembayaran ${CurrencyFormatter.format(payment.amount)} akan dibatalkan. '
        'Saldo "${wallet?.name ?? 'dompet'}" dikembalikan dan transaksinya ikut dihapus. '
        'Sisa ${isDebt ? 'utang' : 'piutang'} bertambah lagi.',
    confirmLabel: 'Batalkan Pembayaran',
  );
  if (!ok || !context.mounted) return false;

  final done = await runApi(context, () => provider.cancelDebtPayment(debt.id, payment.id));
  if (done && context.mounted) _info(context, 'Pembayaran dibatalkan');
  return done;
}

// ---------------------------------------------------------------------
// TABUNGAN
// ---------------------------------------------------------------------

/// Hapus target tabungan. Jika masih berisi dana, pengguna memilih:
/// mengembalikan dana ke dompet (target batal) atau menghapus tanpa mengembalikan
/// (target tercapai & dana sudah terpakai).
Future<bool> confirmDeleteGoal(BuildContext context, SavingsGoal goal) async {
  final provider = context.read<FinanceProvider>();

  if (goal.currentAmount <= 0) {
    final ok = await _confirm(
      context,
      title: 'Hapus target ini?',
      message: '"${goal.title}" akan dihapus permanen beserta riwayatnya.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !context.mounted) return false;
    final done = await runApi(context, () => provider.deleteSavingsGoal(goal.id));
    if (done && context.mounted) _info(context, 'Target "${goal.title}" dihapus');
    return done;
  }

  final completed = goal.isCompleted;
  final wallets = provider.wallets;
  String? walletId = wallets.isNotEmpty ? wallets.first.id : null;

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final hint = TextStyle(fontSize: 11, color: Theme.of(ctx).hintColor);
        final keepButtonStyle = FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981));
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(completed ? 'Target tercapai 🎉' : 'Hapus target ini?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  completed
                      ? '"${goal.title}" sudah tercapai dengan dana ${CurrencyFormatter.format(goal.currentAmount)}. Pilih cara menyelesaikannya:'
                      : '"${goal.title}" masih berisi dana ${CurrencyFormatter.format(goal.currentAmount)}. Mau dikemanakan dananya?',
                ),
                const SizedBox(height: 16),
                if (completed) ...[
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'keep'),
                    style: keepButtonStyle,
                    child: const Text('Selesai & hapus target'),
                  ),
                  const SizedBox(height: 4),
                  Text('Dana dianggap sudah terpakai (mis. untuk membeli barang impian).', style: hint),
                  const SizedBox(height: 14),
                ],
                if (walletId != null) ...[
                  Text('Kembalikan dana ke dompet:', style: hint),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: walletId,
                    decoration: _fieldDecoration(),
                    items: wallets
                        .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => walletId = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  completed
                      ? OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx, 'refund'),
                          icon: const Icon(Icons.undo, size: 18),
                          label: Text('Kembalikan ${CurrencyFormatter.format(goal.currentAmount)} & hapus'),
                        )
                      : FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, 'refund'),
                          icon: const Icon(Icons.undo, size: 18),
                          label: Text('Kembalikan ${CurrencyFormatter.format(goal.currentAmount)} & hapus'),
                        ),
                  const SizedBox(height: 4),
                  Text('Dana masuk kembali ke dompet sebagai pemasukan.', style: hint),
                ],
                if (!completed) ...[
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'keep'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Hapus tanpa mengembalikan'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (choice == null || !context.mounted) return false;

  final refundTo = choice == 'refund' ? walletId : null;
  final done = await runApi(
    context,
    () => provider.deleteSavingsGoal(goal.id, refundWalletId: refundTo),
  );
  if (done && context.mounted) {
    _info(
      context,
      refundTo != null
          ? 'Target dihapus, ${CurrencyFormatter.format(goal.currentAmount)} dikembalikan ke dompet'
          : 'Target "${goal.title}" dihapus',
    );
  }
  return done;
}

Future<bool> confirmCancelSavingsLog(
  BuildContext context,
  SavingsGoal goal,
  SavingsLog log,
) async {
  final provider = context.read<FinanceProvider>();
  final wallet = provider.getWallet(log.walletId);
  final isDeposit = log.type == SavingsLogType.deposit;

  final ok = await _confirm(
    context,
    title: isDeposit ? 'Batalkan setoran ini?' : 'Batalkan penarikan ini?',
    message: isDeposit
        ? 'Setoran ${CurrencyFormatter.format(log.amount)} dibatalkan: uang dikembalikan ke "${wallet?.name ?? 'dompet'}" dan tabungan berkurang.'
        : 'Penarikan ${CurrencyFormatter.format(log.amount)} dibatalkan: uang diambil lagi dari "${wallet?.name ?? 'dompet'}" dan tabungan bertambah.',
    confirmLabel: 'Batalkan',
  );
  if (!ok || !context.mounted) return false;

  final done = await runApi(context, () => provider.cancelSavingsLog(goal.id, log.id));
  if (done && context.mounted) _info(context, 'Riwayat dibatalkan');
  return done;
}