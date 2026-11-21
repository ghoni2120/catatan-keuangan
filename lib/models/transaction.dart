import 'category.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final DateTime date;
  final String? note;

  /// Asal transaksi: manual | transfer | debt_payment | savings
  final String source;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
    this.source = 'manual',
  });

  /// Hanya transaksi manual yang boleh diubah langsung.
  bool get canEdit => source == 'manual';

  /// Transfer boleh dihapus (pasangannya ikut terhapus). Transaksi dari pembayaran utang
  /// atau tabungan dibatalkan lewat fitur terkait.
  bool get canDelete => source == 'manual' || source == 'transfer';

  String? get sourceHint {
    switch (source) {
      case 'transfer':
        return 'Transaksi ini bagian dari transfer antar dompet. Menghapusnya juga menghapus pasangannya dan mengembalikan kedua saldo.';
      case 'debt_payment':
        return 'Transaksi ini berasal dari pembayaran utang/piutang. Untuk membatalkannya, buka menu Utang lalu batalkan pembayarannya.';
      case 'savings':
        return 'Transaksi ini berasal dari setoran/penarikan tabungan. Untuk membatalkannya, buka menu Tabungan lalu batalkan riwayatnya.';
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'walletId': walletId,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['categoryId'] as String,
      walletId: json['walletId'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      note: json['note'] as String?,
      source: (json['source'] as String?) ?? 'manual',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
      source: source,
    );
  }
}