enum DebtType { debt, receivable }

class DebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String walletId;
  final String? notes;

  DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.walletId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'walletId': walletId,
        'notes': notes,
      };

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      walletId: json['walletId'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class DebtItem {
  final String id;
  final String personName;
  final DebtType type; // debt = Utang (saya berutang), receivable = Piutang (orang berutang ke saya)
  final double amount;
  double paidAmount;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? notes;
  final List<DebtPayment> payments;

  DebtItem({
    required this.id,
    required this.personName,
    required this.type,
    required this.amount,
    this.paidAmount = 0.0,
    this.dueDate,
    required this.createdAt,
    this.notes,
    List<DebtPayment>? payments,
  }) : payments = payments ?? [];

  double get remainingAmount => (amount - paidAmount).clamp(0.0, double.infinity);

  bool get isPaidOff => paidAmount >= amount;

  bool get isOverdue =>
      !isPaidOff && dueDate != null && DateTime.now().isAfter(dueDate!);

  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'type': type.name,
        'amount': amount,
        'paidAmount': paidAmount,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final paymentsList = (json['payments'] as List<dynamic>?)
            ?.map((p) => DebtPayment.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return DebtItem(
      id: json['id'] as String,
      personName: json['personName'] as String,
      type: json['type'] == 'receivable'
          ? DebtType.receivable
          : DebtType.debt,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      payments: paymentsList,
    );
  }

  DebtItem copyWith({
    String? id,
    String? personName,
    DebtType? type,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? createdAt,
    String? notes,
    List<DebtPayment>? payments,
  }) {
    return DebtItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      payments: payments ?? List.from(this.payments),
    );
  }
}
