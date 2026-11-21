import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// Sumber data keuangan aplikasi. Seluruh data berasal dari backend.
///
/// Semua fungsi tulis (add/update/delete/pay/transfer/setor/tarik) memanggil API lebih dulu,
/// lalu memperbarui data lokal dari JAWABAN SERVER (termasuk saldo dompet terbaru).
/// Jika gagal, ApiException dilempar dan data lokal TIDAK berubah.
class FinanceProvider extends ChangeNotifier {
  FinanceProvider({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  String? _userId;
  int _epoch = 0; // naik setiap kali data dikosongkan; membuang hasil pemuatan yang basi

  List<Wallet> _wallets = [];
  List<TransactionModel> _transactions = [];
  List<DebtItem> _debts = [];
  List<SavingsGoal> _savings = [];

  bool _hasLoaded = false;
  String? _loadError;

  List<Wallet> get wallets => _wallets;
  List<TransactionModel> get transactions => _transactions;
  List<DebtItem> get debts => _debts;
  List<SavingsGoal> get savings => _savings;

  /// true selama data awal belum siap (tampilkan spinner layar penuh).
  bool get isLoading => !_hasLoaded && _loadError == null;

  /// true setelah data pertama berhasil dimuat.
  bool get hasLoaded => _hasLoaded;

  /// Pesan error jika pemuatan awal gagal (tampilkan tombol "Coba Lagi").
  String? get loadError => _loadError;

  // ------------------------------------------------------------ siklus sesi

  /// Dipanggil oleh ProxyProvider setiap status login berubah.
  /// Login -> muat data; logout / ganti akun -> kosongkan data.
  void onAuthChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    // Dijadwalkan di luar proses build (fungsi ini dipanggil dari ProxyProvider.update)
    scheduleMicrotask(() {
      _clearData();
      if (userId != null) {
        loadData();
      } else {
        notifyListeners();
      }
    });
  }

  void _clearData() {
    _epoch++;
    _wallets = [];
    _transactions = [];
    _debts = [];
    _savings = [];
    _hasLoaded = false;
    _loadError = null;
  }

  // ------------------------------------------------------------ memuat data

  /// Memuat ulang seluruh data dari server. Tidak pernah melempar exception.
  /// Jika gagal setelah data pernah dimuat, data lama dipertahankan.
  Future<void> loadData() async {
    if (_userId == null) return;
    final epoch = _epoch;

    if (!_hasLoaded && _loadError != null) {
      _loadError = null; // "Coba Lagi" -> kembali ke spinner
      notifyListeners();
    }

    try {
      final results = await Future.wait<dynamic>([
        _api.get('/wallets'),
        _fetchAllTransactions(),
        _api.get('/debts'),
        _api.get('/savings'),
      ]);
      if (epoch != _epoch) return;

      var wallets = _parseList((results[0] as ApiResponse).data, Wallet.fromJson);
      if (!_hasLoaded && wallets.isEmpty) {
        // Akun baru: buatkan satu dompet awal agar aplikasi langsung bisa dipakai
        wallets = [await _createDefaultWallet()];
        if (epoch != _epoch) return;
      }

      _wallets = wallets;
      _transactions = results[1] as List<TransactionModel>;
      _debts = _parseList((results[2] as ApiResponse).data, DebtItem.fromJson);
      _savings = _parseList((results[3] as ApiResponse).data, SavingsGoal.fromJson);
      _hasLoaded = true;
      _loadError = null;
    } catch (e) {
      if (epoch != _epoch) return;
      if (kDebugMode) debugPrint('[Finance] loadData gagal: $e');
      if (!_hasLoaded) {
        _loadError = e is ApiException ? e.message : 'Data dari server tidak dapat dibaca.';
      }
    }

    if (epoch != _epoch) return;
    notifyListeners();
  }

  Future<List<TransactionModel>> _fetchAllTransactions() async {
    final all = <TransactionModel>[];
    var offset = 0;
    while (true) {
      final res = await _api.get(
        '/transactions',
        query: {'limit': '500', 'offset': '$offset'},
      );
      final page = _parseList(res.data, TransactionModel.fromJson);
      all.addAll(page);
      offset += page.length;
      final total = (res.meta?['total'] as num?)?.toInt() ?? all.length;
      if (page.isEmpty || offset >= total) break;
    }
    return all;
  }

  Future<Wallet> _createDefaultWallet() async {
    final res = await _api.post(
      '/wallets',
      body: _walletBody(Wallet.defaultWallets.first, balance: 0),
    );
    return Wallet.fromJson(res.data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------ helper

  static List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    return (data as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Nominal rupiah dikirim sebagai bilangan bulat; tanggal dikirim sebagai UTC.
  static int _rupiah(double value) => value.round();
  static String _utc(DateTime d) => d.toUtc().toIso8601String();

  void _sortTransactions() => _transactions.sort((a, b) => b.date.compareTo(a.date));

  /// Menimpa dompet lokal dengan data terbaru dari server (saldo sudah dihitung server).
  void _mergeWallets(dynamic raw) {
    if (raw is! List) return;
    for (final item in raw) {
      final w = Wallet.fromJson(item as Map<String, dynamic>);
      final i = _wallets.indexWhere((x) => x.id == w.id);
      if (i == -1) {
        _wallets.add(w);
      } else {
        _wallets[i] = w;
      }
    }
  }

  void _removeTransactions(dynamic ids) {
    if (ids is! List || ids.isEmpty) return;
    final gone = ids.cast<String>().toSet();
    _transactions.removeWhere((t) => gone.contains(t.id));
  }

  void _upsertDebt(DebtItem d) {
    final i = _debts.indexWhere((x) => x.id == d.id);
    if (i == -1) {
      _debts.insert(0, d);
    } else {
      _debts[i] = d;
    }
  }

  void _upsertGoal(SavingsGoal g) {
    final i = _savings.indexWhere((x) => x.id == g.id);
    if (i == -1) {
      _savings.insert(0, g);
    } else {
      _savings[i] = g;
    }
  }

  Map<String, dynamic> _walletBody(Wallet w, {double? balance}) => {
        'name': w.name,
        'type': w.type.name,
        'balance': _rupiah(balance ?? w.balance),
        'iconCodePoint': w.icon.codePoint,
        'iconFontFamily': w.icon.fontFamily ?? 'MaterialIcons',
        'color': w.color.value,
      };

  Map<String, dynamic> _transactionBody(TransactionModel tx) => {
        'title': tx.title,
        'amount': _rupiah(tx.amount),
        'type': tx.type.name,
        'categoryId': tx.categoryId,
        'walletId': tx.walletId,
        'date': _utc(tx.date),
        'note': tx.note,
      };

  // ------------------------------------------------------------ DOMPET

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
    final res = await _api.post('/wallets', body: _walletBody(wallet));
    _wallets.add(Wallet.fromJson(res.data as Map<String, dynamic>));
    notifyListeners();
  }

  /// Hanya nama, jenis, ikon, dan warna yang bisa diubah. Saldo hanya berubah lewat transaksi.
  Future<void> updateWallet(Wallet wallet) async {
    final res = await _api.patch('/wallets/${wallet.id}', body: {
      'name': wallet.name,
      'type': wallet.type.name,
      'iconCodePoint': wallet.icon.codePoint,
      'iconFontFamily': wallet.icon.fontFamily ?? 'MaterialIcons',
      'color': wallet.color.value,
    });
    _mergeWallets([res.data]);
    notifyListeners();
  }

  /// Jumlah catatan yang memakai dompet ini (transaksi + pembayaran utang + riwayat tabungan).
  int walletUsageCount(String walletId) {
    var n = _transactions.where((t) => t.walletId == walletId).length;
    for (final d in _debts) {
      n += d.payments.where((p) => p.walletId == walletId).length;
    }
    for (final g in _savings) {
      n += g.logs.where((l) => l.walletId == walletId).length;
    }
    return n;
  }

  /// Tanpa [moveToWalletId]: ditolak server (409) jika dompet masih punya riwayat.
  /// Dengan [moveToWalletId]: seluruh riwayat dan saldo dompet dipindahkan ke dompet tujuan,
  /// lalu dompet dihapus.
  Future<void> deleteWallet(String walletId, {String? moveToWalletId}) async {
    final res = await _api.delete(
      '/wallets/$walletId',
      query: moveToWalletId == null ? null : {'moveToWalletId': moveToWalletId},
    );
    _wallets.removeWhere((w) => w.id == walletId);
    if (moveToWalletId != null) {
      _mergeWallets((res.data as Map<String, dynamic>)['wallets']);
      notifyListeners();
      // Riwayat berpindah dompet di server: muat ulang agar seluruh data lokal konsisten
      await loadData();
      return;
    }
    notifyListeners();
  }

  Future<void> transferWalletBalance({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    final res = await _api.post('/wallets/transfer', body: {
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'amount': _rupiah(amount),
      if (note != null) 'note': note,
    });
    final data = res.data as Map<String, dynamic>;
    _mergeWallets([data['fromWallet'], data['toWallet']]);
    _transactions.addAll(_parseList(data['transactions'], TransactionModel.fromJson));
    _sortTransactions();
    notifyListeners();
  }

  // ------------------------------------------------------------ TRANSAKSI

  Future<void> addTransaction(TransactionModel tx) async {
    final res = await _api.post('/transactions', body: _transactionBody(tx));
    final data = res.data as Map<String, dynamic>;
    _transactions.add(
      TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>),
    );
    _sortTransactions();
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    final res = await _api.put('/transactions/${oldTx.id}', body: _transactionBody(newTx));
    final data = res.data as Map<String, dynamic>;
    final updated = TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>);
    final i = _transactions.indexWhere((t) => t.id == oldTx.id);
    if (i == -1) {
      _transactions.add(updated);
    } else {
      _transactions[i] = updated;
    }
    _sortTransactions();
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  /// Menghapus salah satu sisi transfer juga menghapus pasangannya (server yang menentukan).
  Future<void> deleteTransaction(String id) async {
    final res = await _api.delete('/transactions/$id');
    final data = res.data as Map<String, dynamic>;
    final deleted = (data['deletedIds'] as List<dynamic>).cast<String>().toSet();
    _transactions.removeWhere((t) => deleted.contains(t.id));
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  // ------------------------------------------------------------ UTANG & PIUTANG

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
    final res = await _api.post('/debts', body: {
      'personName': debt.personName,
      'type': debt.type.name,
      'amount': _rupiah(debt.amount),
      'paidAmount': _rupiah(debt.paidAmount),
      'dueDate': debt.dueDate == null ? null : _utc(debt.dueDate!),
      'notes': debt.notes,
    });
    _upsertDebt(DebtItem.fromJson(res.data as Map<String, dynamic>));
    notifyListeners();
  }

  Future<void> updateDebt(DebtItem debt) async {
    final res = await _api.patch('/debts/${debt.id}', body: {
      'personName': debt.personName,
      'amount': _rupiah(debt.amount),
      'dueDate': debt.dueDate == null ? null : _utc(debt.dueDate!),
      'notes': debt.notes,
    });
    _upsertDebt(DebtItem.fromJson(res.data as Map<String, dynamic>));
    notifyListeners();
  }

  /// Default: uang yang sudah bergerak tetap (transaksi pembayaran menjadi transaksi biasa).
  /// Dengan [revertPayments]: semua pembayaran dibatalkan dulu (saldo dompet dikembalikan).
  Future<void> deleteDebt(String id, {bool revertPayments = false}) async {
    final res = await _api.delete(
      '/debts/$id',
      query: revertPayments ? {'revertPayments': 'true'} : null,
    );
    final data = res.data as Map<String, dynamic>;
    _debts.removeWhere((d) => d.id == id);
    _removeTransactions(data['deletedTransactionIds']);
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  /// Membatalkan satu pembayaran: saldo dompet dikembalikan dan transaksinya dihapus.
  Future<void> cancelDebtPayment(String debtId, String paymentId) async {
    final res = await _api.delete('/debts/$debtId/payments/$paymentId');
    final data = res.data as Map<String, dynamic>;
    _upsertDebt(DebtItem.fromJson(data['debt'] as Map<String, dynamic>));
    _removeTransactions(data['deletedTransactionIds']);
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  /// Ditolak server (422) jika nominal melebihi sisa utang/piutang.
  Future<void> payDebt({
    required String debtId,
    required double amount,
    required String walletId,
    String? notes,
  }) async {
    final res = await _api.post('/debts/$debtId/payments', body: {
      'amount': _rupiah(amount),
      'walletId': walletId,
      'notes': notes,
    });
    final data = res.data as Map<String, dynamic>;
    _upsertDebt(DebtItem.fromJson(data['debt'] as Map<String, dynamic>));
    _transactions.add(
      TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>),
    );
    _sortTransactions();
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  // ------------------------------------------------------------ TABUNGAN & IMPIAN

  double get totalSavedInGoals {
    return _savings.fold(0.0, (sum, s) => sum + s.currentAmount);
  }

  double get totalTargetInGoals {
    return _savings.fold(0.0, (sum, s) => sum + s.targetAmount);
  }

  /// Mengembalikan target yang tersimpan (dengan ID dari server).
  Future<SavingsGoal> addSavingsGoal(SavingsGoal goal) async {
    final res = await _api.post('/savings', body: {
      'title': goal.title,
      'targetAmount': _rupiah(goal.targetAmount),
      'targetDate': goal.targetDate == null ? null : _utc(goal.targetDate!),
      'iconCodePoint': goal.icon.codePoint,
      'iconFontFamily': goal.icon.fontFamily ?? 'MaterialIcons',
      'color': goal.color.value,
      'notes': goal.notes,
    });
    final created = SavingsGoal.fromJson(res.data as Map<String, dynamic>);
    _upsertGoal(created);
    notifyListeners();
    return created;
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final res = await _api.patch('/savings/${goal.id}', body: {
      'title': goal.title,
      'targetAmount': _rupiah(goal.targetAmount),
      'targetDate': goal.targetDate == null ? null : _utc(goal.targetDate!),
      'iconCodePoint': goal.icon.codePoint,
      'iconFontFamily': goal.icon.fontFamily ?? 'MaterialIcons',
      'color': goal.color.value,
      'notes': goal.notes,
    });
    _upsertGoal(SavingsGoal.fromJson(res.data as Map<String, dynamic>));
    notifyListeners();
  }

  /// Default: dana yang masih tersimpan tidak dikembalikan (cocok untuk target tercapai).
  /// Dengan [refundWalletId]: sisa dana dikembalikan ke dompet itu (target dibatalkan).
  Future<void> deleteSavingsGoal(String id, {String? refundWalletId}) async {
    final res = await _api.delete(
      '/savings/$id',
      query: refundWalletId == null ? null : {'refundWalletId': refundWalletId},
    );
    final data = res.data as Map<String, dynamic>;
    _savings.removeWhere((s) => s.id == id);
    _mergeWallets(data['wallets']);
    final refund = data['transaction'];
    if (refund != null) {
      _transactions.add(TransactionModel.fromJson(refund as Map<String, dynamic>));
      _sortTransactions();
    }
    notifyListeners();
  }

  /// Membatalkan satu setoran/penarikan: saldo dompet & tabungan dikembalikan.
  Future<void> cancelSavingsLog(String goalId, String logId) async {
    final res = await _api.delete('/savings/$goalId/logs/$logId');
    final data = res.data as Map<String, dynamic>;
    _upsertGoal(SavingsGoal.fromJson(data['goal'] as Map<String, dynamic>));
    _removeTransactions(data['deletedTransactionIds']);
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  Future<void> depositToSavings({
    required String goalId,
    required double amount,
    required String walletId,
    String? notes,
  }) =>
      _moveSavings('deposit', goalId, amount, walletId, notes);

  /// Jika nominal melebihi saldo tabungan, server membatasi sebesar saldo tabungan.
  Future<void> withdrawFromSavings({
    required String goalId,
    required double amount,
    required String walletId,
    String? notes,
  }) =>
      _moveSavings('withdraw', goalId, amount, walletId, notes);

  Future<void> _moveSavings(
    String kind,
    String goalId,
    double amount,
    String walletId,
    String? notes,
  ) async {
    final res = await _api.post('/savings/$goalId/$kind', body: {
      'amount': _rupiah(amount),
      'walletId': walletId,
      'notes': notes,
    });
    final data = res.data as Map<String, dynamic>;
    _upsertGoal(SavingsGoal.fromJson(data['goal'] as Map<String, dynamic>));
    _transactions.add(
      TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>),
    );
    _sortTransactions();
    _mergeWallets(data['wallets']);
    notifyListeners();
  }

  // ------------------------------------------------------------ ANALITIK & RINGKASAN

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
}