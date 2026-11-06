import 'package:flutter/material.dart';

enum SavingsLogType { deposit, withdraw }

class SavingsLog {
  final String id;
  final double amount;
  final DateTime date;
  final SavingsLogType type;
  final String walletId;
  final String? notes;

  SavingsLog({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.walletId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.name,
        'walletId': walletId,
        'notes': notes,
      };

  factory SavingsLog.fromJson(Map<String, dynamic> json) {
    return SavingsLog(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] == 'withdraw'
          ? SavingsLogType.withdraw
          : SavingsLogType.deposit,
      walletId: json['walletId'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String? notes;
  final List<SavingsLog> logs;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.notes,
    List<SavingsLog>? logs,
  }) : logs = logs ?? [];

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'color': color.value,
        'notes': notes,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final logsList = (json['logs'] as List<dynamic>?)
            ?.map((l) => SavingsLog.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];

    return SavingsGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['color'] as int),
      notes: json['notes'] as String?,
      logs: logsList,
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    IconData? icon,
    Color? color,
    String? notes,
    List<SavingsLog>? logs,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      logs: logs ?? List.from(this.logs),
    );
  }
}
