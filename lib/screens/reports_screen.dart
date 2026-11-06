import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';

enum ReportPeriod { thisMonth, lastMonth, thisYear, allTime }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  int _touchedPieIndex = -1;

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month - 1, 1);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.allTime:
        return null;
    }
  }

  DateTime? _getEndDate() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month, 0, 23, 59, 59);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case ReportPeriod.allTime:
        return null;
    }
  }

  String _getPeriodLabel() {
    switch (_period) {
      case ReportPeriod.thisMonth:
        return 'Bulan Ini';
      case ReportPeriod.lastMonth:
        return 'Bulan Lalu';
      case ReportPeriod.thisYear:
        return 'Tahun Ini';
      case ReportPeriod.allTime:
        return 'Semua Waktu';
    }
  }

  void _exportSummary(double income, double expense, Map<String, double> catExpenses) {
    final net = income - expense;
    final buffer = StringBuffer();
    buffer.writeln('📊 *RINGKASAN KEUANGAN PRIBADI*');
    buffer.writeln('Periode: ${_getPeriodLabel()}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('💰 Total Pemasukan: ${CurrencyFormatter.format(income)}');
    buffer.writeln('💸 Total Pengeluaran: ${CurrencyFormatter.format(expense)}');
    buffer.writeln('📈 Selisih / Arus Kas: ${CurrencyFormatter.format(net)}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('📋 Rincian Pengeluaran per Kategori:');
    catExpenses.forEach((catId, amount) {
      final cat = CategoryItem.findCategory(catId);
      final pct = expense > 0 ? (amount / expense * 100).toStringAsFixed(1) : '0';
      buffer.writeln(' • ${cat.name}: ${CurrencyFormatter.format(amount)} ($pct%)');
    });

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan ringkasan berhasil disalin ke clipboard!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FinanceProvider>(context);

    final start = _getStartDate();
    final end = _getEndDate();

    // Filter transactions
    final periodTransactions = provider.transactions.where((t) {
      if (start != null && t.date.isBefore(start)) return false;
      if (end != null && t.date.isAfter(end)) return false;
      return true;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    final expenseMap = <String, double>{};

    for (final tx in periodTransactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        expenseMap[tx.categoryId] = (expenseMap[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final netFlow = totalIncome - totalExpense;
    final savingRate =
        totalIncome > 0 ? ((netFlow > 0 ? netFlow : 0) / totalIncome * 100) : 0.0;

    // Sort categories by highest expense
    final sortedCategories = expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analitik'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Salin Ringkasan Laporan',
            onPressed: () => _exportSummary(totalIncome, totalExpense, expenseMap),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip(ReportPeriod.thisMonth, 'Bulan Ini'),
                _periodChip(ReportPeriod.lastMonth, 'Bulan Lalu'),
                _periodChip(ReportPeriod.thisYear, 'Tahun Ini'),
                _periodChip(ReportPeriod.allTime, 'Semua Waktu'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview Grid Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        title: 'Total Pemasukan',
                        amount: totalIncome,
                        color: const Color(0xFF10B981),
                        icon: Icons.arrow_downward,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricBox(
                        title: 'Total Pengeluaran',
                        amount: totalExpense,
                        color: const Color(0xFFEF4444),
                        icon: Icons.arrow_upward,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arus Kas Bersih',
                            style: TextStyle(color: theme.hintColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${netFlow >= 0 ? '+' : ''}${CurrencyFormatter.format(netFlow)}',
                          style: TextStyle(
                            color: netFlow >= 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: savingRate > 20
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Saving Rate',
                              style: TextStyle(
                                fontSize: 11,
                                color: savingRate > 20
                                    ? const Color(0xFF10B981)
                                    : Colors.orange.shade800,
                              )),
                          Text(
                            '${savingRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: savingRate > 20
                                  ? const Color(0xFF10B981)
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pie Chart Section
          Text(
            'Distribusi Pengeluaran',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (totalExpense == 0)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 48, color: theme.hintColor),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada pengeluaran pada periode ini',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        sections: sortedCategories.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isTouched = idx == _touchedPieIndex;
                          final radius = isTouched ? 65.0 : 55.0;
                          final cat = CategoryItem.findCategory(item.key);
                          final pct = (item.value / totalExpense * 100);

                          return PieChartSectionData(
                            color: cat.color,
                            value: item.value,
                            title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                            radius: radius,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Pengeluaran: ${CurrencyFormatter.format(totalExpense)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category breakdown list
            Text(
              'Rincian per Kategori',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...sortedCategories.map((entry) {
              final cat = CategoryItem.findCategory(entry.key);
              final amount = entry.value;
              final pct = (amount / totalExpense * 100);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 5,
                              backgroundColor: theme.dividerColor.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _periodChip(ReportPeriod period, String label) {
    final isSelected = _period == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _period = period);
        },
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: theme.hintColor, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
