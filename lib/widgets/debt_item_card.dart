import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class DebtItemCard extends StatelessWidget {
  final DebtItem debt;
  final VoidCallback? onPayTap;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DebtItemCard({
    super.key,
    required this.debt,
    this.onPayTap,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebt = debt.type == DebtType.debt;
    final isPaid = debt.isPaidOff;
    final isOverdue = debt.isOverdue;

    Color badgeColor;
    String badgeText;
    if (isPaid) {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'LUNAS';
    } else if (isOverdue) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'JATUH TEMPO';
    } else {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'BELUM LUNAS';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDebt
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDebt ? Icons.upload_rounded : Icons.download_rounded,
                      color: isDebt ? Colors.red.shade700 : Colors.blue.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDebt ? 'Utang ke pihak ini' : 'Piutang (dia pinjam)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDebt ? Colors.red.shade600 : Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pinjaman',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(debt.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Sisa Tagihan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(debt.remainingAmount),
                        style: TextStyle(
                          color: isPaid
                              ? const Color(0xFF10B981)
                              : (isDebt ? Colors.red.shade700 : Colors.blue.shade700),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPaid ? const Color(0xFF10B981) : (isDebt ? Colors.red : Colors.blue),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        debt.dueDate != null
                            ? 'Jatuh tempo: ${DateFormatter.formatDate(debt.dueDate!)}'
                            : 'Tidak ada tenggat waktu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : theme.hintColor,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (!isPaid && onPayTap != null)
                    FilledButton.tonalIcon(
                      onPressed: onPayTap,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.payment, size: 16),
                      label: Text(
                        isDebt ? 'Bayar Cicilan' : 'Terima Pembayaran',
                        style: const TextStyle(fontSize: 12),
                      ),
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
