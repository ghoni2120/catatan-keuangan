import 'package:flutter/material.dart';

enum WalletType { cash, bank, ewallet, other }

class Wallet {
  final String id;
  String name;
  WalletType type;
  double balance;
  IconData icon;
  Color color;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'color': color.value,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletType.cash,
      ),
      balance: (json['balance'] as num).toDouble(),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['color'] as int),
    );
  }

  static List<Wallet> get defaultWallets => [
        Wallet(
          id: 'wallet_cash',
          name: 'Uang Tunai / Cash',
          type: WalletType.cash,
          balance: 500000,
          icon: Icons.payments,
          color: Colors.green,
        ),
        Wallet(
          id: 'wallet_bca',
          name: 'Bank BCA',
          type: WalletType.bank,
          balance: 3500000,
          icon: Icons.account_balance,
          color: Colors.blue,
        ),
        Wallet(
          id: 'wallet_gopay',
          name: 'GoPay / E-Wallet',
          type: WalletType.ewallet,
          balance: 250000,
          icon: Icons.account_balance_wallet,
          color: Colors.teal,
        ),
      ];
}
