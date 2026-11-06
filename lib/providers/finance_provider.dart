import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/dummy_data.dart';

class FinanceProvider extends ChangeNotifier {
  static const String _keyWallets = 'finance_wallets_v1';
  static const String _keyTransactions = 'finance_transactions_v1';
  static const String _keyDebts = 'finance_debts_v1';
  static const String _keySavings = 'finance_savings_v1';
  static const String _keyInitialized = 'finance_has_initialized_v1';

  final Uuid _uuid = const Uuid();

  List<Wallet> _wallets = [];
  List<TransactionModel> _transactions = [];
  List<DebtItem> _debts = [];
  List<SavingsGoal> _savings = [];
  bool _isLoading = true;

  List<Wallet> get wallets => _wallets;
  List<TransactionModel> get transactions => _transactions;
  List<DebtItem> get debts => _debts;
  List<SavingsGoal> get savings => _savings;
  bool get isLoading => _isLoading;

  FinanceProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasInitialized = prefs.getBool(_keyInitialized) ?? false;

      if (!hasInitialized) {
        // First run: load initial sample data
        _wallets = DummyData.sampleWallets;
        _transactions = DummyData.sampleTransactions;
        _debts = DummyData.sampleDebts;
        _savings = DummyData.sampleSavings;
        await _saveAll();
        await prefs.setBool(_keyInitialized, true);
      } else {
        // Load existing data
        final walletsJson = prefs.getString(_keyWallets);
        if (walletsJson != null) {
          final list = jsonDecode(walletsJson) as List<dynamic>;
          _wallets = list.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _wallets = DummyData.sampleWallets;
        }

        final txJson = prefs.getString(_keyTransactions);
        if (txJson != null) {
          final list = jsonDecode(txJson) as List<dynamic>;
          _transactions = list
              .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _transactions.sort((a, b) => b.date.compareTo(a.date));
        } else {
          _transactions = DummyData.sampleTransactions;
        }

        final debtsJson = prefs.getString(_keyDebts);
        if (debtsJson != null) {
          final list = jsonDecode(debtsJson) as List<dynamic>;
          _debts = list.map((e) => DebtItem.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _debts = DummyData.sampleDebts;
        }

        final savingsJson = prefs.getString(_keySavings);
        if (savingsJson != null) {
          final list = jsonDecode(savingsJson) as List<dynamic>;
          _savings =
              list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _savings = DummyData.sampleSavings;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading finance data: $e');
      }
      _wallets = DummyData.sampleWallets;
      _transactions = DummyData.sampleTransactions;
      _debts = DummyData.sampleDebts;
      _savings = DummyData.sampleSavings;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyWallets, jsonEncode(_wallets.map((w) => w.toJson()).toList()));
    await prefs.setString(
        _keyTransactions, jsonEncode(_transactions.map((t) => t.toJson()).toList()));
    await prefs.setString(
        _keyDebts, jsonEncode(_debts.map((d) => d.toJson()).toList()));
    await prefs.setString(
        _keySavings, jsonEncode(_savings.map((s) => s.toJson()).toList()));
  }

  // --- WALLET GETTERS & HELPERS ---
  Wallet? getWallet(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return _wallets.isNotEmpty ? _wallets.first : null;
    }
  }

  double get totalWalletBalance {
    return _wallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  Future<void> addWallet(Wallet wallet) async {
    _wallets.add(wallet);
    notifyListeners();
    await _saveAll();
  }

  Future<void> updateWallet(Wallet wallet) async {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> deleteWallet(String walletId) async {
    _wallets.removeWhere((w) => w.id == walletId);
    notifyListeners();
    await _saveAll();
  }

  Future<void> transferWalletBalance({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    final from = getWallet(fromWalletId);
    final to = getWallet(toWalletId);
    if (from != null && to != null && amount > 0) {
      from.balance -= amount;
      to.balance += amount;

      // Add a record in transactions for clarity
      final now = DateTime.now();
      _transactions.insert(
        0,
        TransactionModel(
          id: _uuid.v4(),
          title: 'Transfer: ${from.name} ➔ ${to.name}',
          amount: amount,
          type: TransactionType.expense,
          categoryId: 'exp_other',
          walletId: fromWalletId,
          date: now,
          note: note ?? 'Transfer saldo antar dompet',
        ),
      );
      _transactions.insert(
        0,
        TransactionModel(
          id: _uuid.v4(),
          title: 'Terima Transfer dari ${from.name}',
          amount: amount,
          type: TransactionType.income,
          categoryId: 'inc_other',
          walletId: toWalletId,
          date: now,
          note: note ?? 'Transfer saldo antar dompet',
        ),
      );

      notifyListeners();
      await _saveAll();
    }
  }

  // --- TRANSACTIONS ---
  Future<void> addTransaction(TransactionModel tx) async {
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    // Update wallet balance
    final wallet = getWallet(tx.walletId);
    if (wallet != null) {
      if (tx.type == TransactionType.income) {
        wallet.balance += tx.amount;
      } else {
        wallet.balance -= tx.amount;
      }
    }

    notifyListeners();
    await _saveAll();
  }

  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    final index = _transactions.indexWhere((t) => t.id == oldTx.id);
    if (index != -1) {
      // Revert old effect
      final oldWallet = getWallet(oldTx.walletId);
      if (oldWallet != null) {
        if (oldTx.type == TransactionType.income) {
          oldWallet.balance -= oldTx.amount;
        } else {
          oldWallet.balance += oldTx.amount;
        }
      }

      // Apply new effect
      final newWallet = getWallet(newTx.walletId);
      if (newWallet != null) {
        if (newTx.type == TransactionType.income) {
          newWallet.balance += newTx.amount;
        } else {
          newWallet.balance -= newTx.amount;
        }
      }

      _transactions[index] = newTx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tx = _transactions[index];
      final wallet = getWallet(tx.walletId);
      if (wallet != null) {
        if (tx.type == TransactionType.income) {
          wallet.balance -= tx.amount;
        } else {
          wallet.balance += tx.amount;
        }
      }
      _transactions.removeAt(index);
      notifyListeners();
      await _saveAll();
    }
  }

  // --- DEBTS (UTANG & PIUTANG) ---
  double get totalDebt {
    return _debts
        .where((d) => d.type == DebtType.debt)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalReceivable {
    return _debts
        .where((d) => d.type == DebtType.receivable)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  Future<void> addDebt(DebtItem debt) async {
    _debts.insert(0, debt);
    notifyListeners();
    await _saveAll();
  }

  Future<void> updateDebt(DebtItem debt) async {
    final index = _debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      _debts[index] = debt;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
    await _saveAll();
  }

  Future<void> payDebt({
    required String debtId,
    required double amount,
    required String walletId,
    String? notes,
  }) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1 || amount <= 0) return;

    final debt = _debts[index];
    debt.paidAmount += amount;

    final payment = DebtPayment(
      id: _uuid.v4(),
      amount: amount,
      date: DateTime.now(),
      walletId: walletId,
      notes: notes,
    );
    debt.payments.insert(0, payment);

    // Sync with wallet and create transaction
    final wallet = getWallet(walletId);
    if (debt.type == DebtType.debt) {
      // Utang: saya membayar hutang, uang dompet keluar
      if (wallet != null) wallet.balance -= amount;
      _transactions.insert(
        0,
        TransactionModel(
          id: _uuid.v4(),
          title: 'Bayar Utang: ${debt.personName}',
          amount: amount,
          type: TransactionType.expense,
          categoryId: 'exp_other',
          walletId: walletId,
          date: DateTime.now(),
          note: notes ?? 'Pembayaran cicilan / pelunasan utang',
        ),
      );
    } else {
      // Piutang: orang membayar ke saya, uang dompet bertambah
      if (wallet != null) wallet.balance += amount;
      _transactions.insert(
        0,
        TransactionModel(
          id: _uuid.v4(),
          title: 'Terima Piutang: ${debt.personName}',
          amount: amount,
          type: TransactionType.income,
          categoryId: 'inc_other',
          walletId: walletId,
          date: DateTime.now(),
          note: notes ?? 'Penerimaan pembayaran piutang',
        ),
      );
    }

    notifyListeners();
    await _saveAll();
  }

  // --- SAVINGS GOALS (TABUNGAN & IMPIAN) ---
  double get totalSavedInGoals {
    return _savings.fold(0.0, (sum, s) => sum + s.currentAmount);
  }

  double get totalTargetInGoals {
    return _savings.fold(0.0, (sum, s) => sum + s.targetAmount);
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _savings.insert(0, goal);
    notifyListeners();
    await _saveAll();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final index = _savings.indexWhere((s) => s.id == goal.id);
    if (index != -1) {
      _savings[index] = goal;
      notifyListeners();
      await _saveAll();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    _savings.removeWhere((s) => s.id == id);
    notifyListeners();
    await _saveAll();
  }

  Future<void> depositToSavings({
    required String goalId,
    required double amount,
    required String walletId,
    String? notes,
  }) async {
    final index = _savings.indexWhere((s) => s.id == goalId);
    if (index == -1 || amount <= 0) return;

    final goal = _savings[index];
    goal.currentAmount += amount;

    final log = SavingsLog(
      id: _uuid.v4(),
      amount: amount,
      date: DateTime.now(),
      type: SavingsLogType.deposit,
      walletId: walletId,
      notes: notes,
    );
    goal.logs.insert(0, log);

    // Deduct from wallet and record transaction
    final wallet = getWallet(walletId);
    if (wallet != null) wallet.balance -= amount;

    _transactions.insert(
      0,
      TransactionModel(
        id: _uuid.v4(),
        title: 'Setor Tabungan: ${goal.title}',
        amount: amount,
        type: TransactionType.expense,
        categoryId: 'exp_other',
        walletId: walletId,
        date: DateTime.now(),
        note: notes ?? 'Menabung ke impian "${goal.title}"',
      ),
    );

    notifyListeners();
    await _saveAll();
  }

  Future<void> withdrawFromSavings({
    required String goalId,
    required double amount,
    required String walletId,
    String? notes,
  }) async {
    final index = _savings.indexWhere((s) => s.id == goalId);
    if (index == -1 || amount <= 0) return;

    final goal = _savings[index];
    final actualAmount = amount > goal.currentAmount ? goal.currentAmount : amount;
    goal.currentAmount -= actualAmount;

    final log = SavingsLog(
      id: _uuid.v4(),
      amount: actualAmount,
      date: DateTime.now(),
      type: SavingsLogType.withdraw,
      walletId: walletId,
      notes: notes,
    );
    goal.logs.insert(0, log);

    // Return money to wallet and record income transaction
    final wallet = getWallet(walletId);
    if (wallet != null) wallet.balance += actualAmount;

    _transactions.insert(
      0,
      TransactionModel(
        id: _uuid.v4(),
        title: 'Tarik Tabungan: ${goal.title}',
        amount: actualAmount,
        type: TransactionType.income,
        categoryId: 'inc_other',
        walletId: walletId,
        date: DateTime.now(),
        note: notes ?? 'Penarikan dari tabungan "${goal.title}"',
      ),
    );

    notifyListeners();
    await _saveAll();
  }

  // --- ANALYTICS & SUMMARIES ---
  double get totalIncomeThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenseThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netSavingsThisMonth => totalIncomeThisMonth - totalExpenseThisMonth;

  Map<String, double> getExpenseByCategory({DateTime? start, DateTime? end}) {
    final map = <String, double>{};
    for (final tx in _transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (start != null && tx.date.isBefore(start)) continue;
      if (end != null && tx.date.isAfter(end)) continue;

      map[tx.categoryId] = (map[tx.categoryId] ?? 0.0) + tx.amount;
    }
    return map;
  }

  Map<String, double> getIncomeByCategory({DateTime? start, DateTime? end}) {
    final map = <String, double>{};
    for (final tx in _transactions) {
      if (tx.type != TransactionType.income) continue;
      if (start != null && tx.date.isBefore(start)) continue;
      if (end != null && tx.date.isAfter(end)) continue;

      map[tx.categoryId] = (map[tx.categoryId] ?? 0.0) + tx.amount;
    }
    return map;
  }

  Future<void> resetAllData() async {
    _wallets = DummyData.sampleWallets;
    _transactions = DummyData.sampleTransactions;
    _debts = DummyData.sampleDebts;
    _savings = DummyData.sampleSavings;
    await _saveAll();
    notifyListeners();
  }
}
