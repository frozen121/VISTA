import 'package:intl/intl.dart';

class DateUtil {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'ru_RU');
  static final _shortDateFormat = DateFormat('dd MMM', 'ru_RU');
  static final _monthYear = DateFormat('MMM yyyy', 'ru_RU');
  static final _full = DateFormat('EEEE, dd MMMM yyyy', 'ru_RU');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatShort(DateTime date) => _shortDateFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatFull(DateTime date) => _full.format(date);

  static String formatDateRange(DateTime from, DateTime to) {
    return '${_shortDateFormat.format(from)} – ${_dateFormat.format(to)}';
  }

  static int nightsBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  static bool isOverlapping(
    DateTime start1, DateTime end1,
    DateTime start2, DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return _dateFormat.format(date);
    if (diff.inDays > 0) return '${diff.inDays} дн. назад';
    if (diff.inHours > 0) return '${diff.inHours} ч назад';
    if (diff.inMinutes > 0) return '${diff.inMinutes} мин назад';
    return 'только что';
  }
}
