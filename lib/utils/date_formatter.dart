import 'package:intl/intl.dart';

class DateFormatter {
  static final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static final List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static final List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static String formatDate(DateTime date) {
    return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
  }

  static String formatFull(DateTime date) {
    final dayName = _days[date.weekday - 1];
    final monthName = _months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) {
      return 'Hari Ini';
    } else if (diffDays == -1) {
      return 'Kemarin';
    } else if (diffDays == 1) {
      return 'Besok';
    } else {
      return formatDate(date);
    }
  }
}
