import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class CategoryItem {
  final String id;
  final String name;
  final TransactionType type;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'color': color.value,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['color'] as int),
    );
  }

  static List<CategoryItem> get defaultExpenseCategories => [
        const CategoryItem(
          id: 'exp_food',
          name: 'Makanan & Minuman',
          type: TransactionType.expense,
          icon: Icons.restaurant,
          color: Colors.orange,
        ),
        const CategoryItem(
          id: 'exp_transport',
          name: 'Transportasi',
          type: TransactionType.expense,
          icon: Icons.directions_car,
          color: Colors.blue,
        ),
        const CategoryItem(
          id: 'exp_shopping',
          name: 'Belanja',
          type: TransactionType.expense,
          icon: Icons.shopping_bag,
          color: Colors.pink,
        ),
        const CategoryItem(
          id: 'exp_bills',
          name: 'Tagihan & Listrik',
          type: TransactionType.expense,
          icon: Icons.receipt_long,
          color: Colors.redAccent,
        ),
        const CategoryItem(
          id: 'exp_entertainment',
          name: 'Hiburan',
          type: TransactionType.expense,
          icon: Icons.sports_esports,
          color: Colors.purple,
        ),
        const CategoryItem(
          id: 'exp_health',
          name: 'Kesehatan',
          type: TransactionType.expense,
          icon: Icons.medical_services,
          color: Colors.teal,
        ),
        const CategoryItem(
          id: 'exp_education',
          name: 'Pendidikan',
          type: TransactionType.expense,
          icon: Icons.school,
          color: Colors.indigo,
        ),
        const CategoryItem(
          id: 'exp_donation',
          name: 'Donasi & Amal',
          type: TransactionType.expense,
          icon: Icons.volunteer_activism,
          color: Colors.amber,
        ),
        const CategoryItem(
          id: 'exp_other',
          name: 'Lain-lain',
          type: TransactionType.expense,
          icon: Icons.category,
          color: Colors.grey,
        ),
      ];

  static List<CategoryItem> get defaultIncomeCategories => [
        const CategoryItem(
          id: 'inc_salary',
          name: 'Gaji Pokok',
          type: TransactionType.income,
          icon: Icons.account_balance_wallet,
          color: Colors.green,
        ),
        const CategoryItem(
          id: 'inc_bonus',
          name: 'Bonus / THR',
          type: TransactionType.income,
          icon: Icons.card_giftcard,
          color: Colors.cyan,
        ),
        const CategoryItem(
          id: 'inc_business',
          name: 'Usaha & Bisnis',
          type: TransactionType.income,
          icon: Icons.store,
          color: Colors.blueAccent,
        ),
        const CategoryItem(
          id: 'inc_investment',
          name: 'Investasi / Dividen',
          type: TransactionType.income,
          icon: Icons.trending_up,
          color: Colors.deepPurple,
        ),
        const CategoryItem(
          id: 'inc_freelance',
          name: 'Freelance / Side Job',
          type: TransactionType.income,
          icon: Icons.computer,
          color: Colors.teal,
        ),
        const CategoryItem(
          id: 'inc_other',
          name: 'Pemasukan Lain',
          type: TransactionType.income,
          icon: Icons.attach_money,
          color: Colors.blueGrey,
        ),
      ];

  static CategoryItem findCategory(String id, {TransactionType? fallbackType}) {
    final all = [...defaultExpenseCategories, ...defaultIncomeCategories];
    for (final cat in all) {
      if (cat.id == id) return cat;
    }
    return CategoryItem(
      id: id,
      name: 'Lainnya',
      type: fallbackType ?? TransactionType.expense,
      icon: Icons.category,
      color: Colors.grey,
    );
  }
}
