import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class DummyData {
  static List<Wallet> get sampleWallets => [
        Wallet(
          id: 'w_cash',
          name: 'Uang Tunai',
          type: WalletType.cash,
          balance: 850000,
          icon: Icons.payments,
          color: Colors.green,
        ),
        Wallet(
          id: 'w_bca',
          name: 'Bank BCA',
          type: WalletType.bank,
          balance: 4750000,
          icon: Icons.account_balance,
          color: Colors.blue,
        ),
        Wallet(
          id: 'w_gopay',
          name: 'GoPay / E-Wallet',
          type: WalletType.ewallet,
          balance: 320000,
          icon: Icons.account_balance_wallet,
          color: Colors.teal,
        ),
      ];

  static List<TransactionModel> get sampleTransactions {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 't_1',
        title: 'Gaji Bulanan',
        amount: 6500000,
        type: TransactionType.income,
        categoryId: 'inc_salary',
        walletId: 'w_bca',
        date: now.subtract(const Duration(days: 3, hours: 2)),
        note: 'Gaji bulan ini telah masuk',
      ),
      TransactionModel(
        id: 't_2',
        title: 'Project Freelance UI/UX',
        amount: 1200000,
        type: TransactionType.income,
        categoryId: 'inc_freelance',
        walletId: 'w_bca',
        date: now.subtract(const Duration(days: 1, hours: 4)),
        note: 'Pembayaran DP project web app',
      ),
      TransactionModel(
        id: 't_3',
        title: 'Belanja Mingguan Supermarket',
        amount: 385000,
        type: TransactionType.expense,
        categoryId: 'exp_shopping',
        walletId: 'w_cash',
        date: now.subtract(const Duration(days: 1, hours: 1)),
        note: 'Beli kebutuhan dapur dan sabun',
      ),
      TransactionModel(
        id: 't_4',
        title: 'Makan Siang & Es Kopi',
        amount: 48000,
        type: TransactionType.expense,
        categoryId: 'exp_food',
        walletId: 'w_gopay',
        date: now.subtract(const Duration(hours: 4)),
        note: 'Nasi padang & es teh manis',
      ),
      TransactionModel(
        id: 't_5',
        title: 'Bensin Motor Pertamax',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'exp_transport',
        walletId: 'w_cash',
        date: now.subtract(const Duration(days: 2, hours: 5)),
        note: 'Isi full tank',
      ),
      TransactionModel(
        id: 't_6',
        title: 'Tagihan Listrik & WiFi',
        amount: 375000,
        type: TransactionType.expense,
        categoryId: 'exp_bills',
        walletId: 'w_bca',
        date: now.subtract(const Duration(days: 4, hours: 8)),
        note: 'Token listrik dan IndiHome',
      ),
      TransactionModel(
        id: 't_7',
        title: 'Tiket Nonton Bioskop',
        amount: 90000,
        type: TransactionType.expense,
        categoryId: 'exp_entertainment',
        walletId: 'w_gopay',
        date: now.subtract(const Duration(days: 5, hours: 3)),
        note: 'Nonton bareng teman',
      ),
    ];
  }

  static List<DebtItem> get sampleDebts {
    final now = DateTime.now();
    return [
      DebtItem(
        id: 'd_1',
        personName: 'Budi Santoso',
        type: DebtType.debt, // Utang saya
        amount: 500000,
        paidAmount: 200000,
        dueDate: now.add(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 15)),
        notes: 'Pinjam untuk bayar servis motor mendadak',
        payments: [
          DebtPayment(
            id: 'dp_1',
            amount: 200000,
            date: now.subtract(const Duration(days: 3)),
            walletId: 'w_bca',
            notes: 'Cicilan pertama',
          )
        ],
      ),
      DebtItem(
        id: 'd_2',
        personName: 'Rian Pratama',
        type: DebtType.receivable, // Piutang (Rian pinjam ke saya)
        amount: 350000,
        paidAmount: 0,
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 7)),
        notes: 'Pinjam buat beli modul kuliah',
        payments: [],
      ),
      DebtItem(
        id: 'd_3',
        personName: 'Siti Rahma',
        type: DebtType.receivable,
        amount: 150000,
        paidAmount: 150000,
        dueDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 12)),
        notes: 'Talangan beli tiket seminar (Sudah Lunas)',
        payments: [
          DebtPayment(
            id: 'dp_2',
            amount: 150000,
            date: now.subtract(const Duration(days: 2)),
            walletId: 'w_gopay',
            notes: 'Pelunasan via transfer',
          )
        ],
      ),
    ];
  }

  static List<SavingsGoal> get sampleSavings {
    final now = DateTime.now();
    return [
      SavingsGoal(
        id: 's_1',
        title: 'Dana Darurat 6 Bulan',
        targetAmount: 12000000,
        currentAmount: 4500000,
        targetDate: now.add(const Duration(days: 180)),
        createdAt: now.subtract(const Duration(days: 60)),
        icon: Icons.shield,
        color: Colors.blueAccent,
        notes: 'Tabungan dana darurat disimpan di deposito / bank aman',
        logs: [
          SavingsLog(
            id: 'sl_1',
            amount: 2500000,
            date: now.subtract(const Duration(days: 45)),
            type: SavingsLogType.deposit,
            walletId: 'w_bca',
            notes: 'Setoran awal',
          ),
          SavingsLog(
            id: 'sl_2',
            amount: 2000000,
            date: now.subtract(const Duration(days: 15)),
            type: SavingsLogType.deposit,
            walletId: 'w_bca',
            notes: 'Dari bonus project',
          ),
        ],
      ),
      SavingsGoal(
        id: 's_2',
        title: 'Beli Laptop Baru',
        targetAmount: 8500000,
        currentAmount: 5200000,
        targetDate: now.add(const Duration(days: 90)),
        createdAt: now.subtract(const Duration(days: 40)),
        icon: Icons.laptop_mac,
        color: Colors.purple,
        notes: 'Laptop untuk ngoding dan tugas kuliah',
        logs: [
          SavingsLog(
            id: 'sl_3',
            amount: 3000000,
            date: now.subtract(const Duration(days: 35)),
            type: SavingsLogType.deposit,
            walletId: 'w_bca',
          ),
          SavingsLog(
            id: 'sl_4',
            amount: 2200000,
            date: now.subtract(const Duration(days: 10)),
            type: SavingsLogType.deposit,
            walletId: 'w_bca',
          ),
        ],
      ),
      SavingsGoal(
        id: 's_3',
        title: 'Liburan Akhir Tahun',
        targetAmount: 2500000,
        currentAmount: 1100000,
        targetDate: now.add(const Duration(days: 50)),
        createdAt: now.subtract(const Duration(days: 20)),
        icon: Icons.beach_access,
        color: Colors.orange,
        notes: 'Healing dan liburan santai bareng teman-teman',
        logs: [
          SavingsLog(
            id: 'sl_5',
            amount: 1100000,
            date: now.subtract(const Duration(days: 10)),
            type: SavingsLogType.deposit,
            walletId: 'w_cash',
          ),
        ],
      ),
    ];
  }
}
