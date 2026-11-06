import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class SavingsItemCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTap;

  const SavingsItemCard({
    super.key,
    required this.goal,
    this.onDeposit,
    this.onWithdraw,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (goal.progress * 100).toInt();
    final isDone = goal.isCompleted;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: goal.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(goal.icon, color: goal.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.targetDate != null
                              ? 'Target: ${DateFormatter.formatDate(goal.targetDate!)}'
                              : 'Tidak ada tenggat waktu',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : goal.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDone ? 'TERCAPAI 🎉' : '$percentage%',
                      style: TextStyle(
                        color: isDone ? const Color(0xFF10B981) : goal.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terkumpul',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(goal.currentAmount),
                        style: TextStyle(
                          color: goal.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target Dana',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(goal.targetAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  backgroundColor: theme.dividerColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? const Color(0xFF10B981) : goal.color,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (goal.currentAmount > 0)
                    OutlinedButton.icon(
                      onPressed: onWithdraw,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
                      ),
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Tarik', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onDeposit,
                    style: FilledButton.styleFrom(
                      backgroundColor: goal.color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Setor Tabungan',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
