import 'package:intl/intl.dart';

/// All user-facing number/date formatting lives here so prices, dates and
/// distances look identical on every screen.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

  static String _group(num amount) =>
      _grouped.format(amount).replaceAll(',', ' ');

  /// 120000 -> "120 000 so'm"
  static String currency(num amount) => "${_group(amount)} so'm";

  /// 120000 -> "120 000" (pair it with a "so'm" caption in tight layouts)
  static String currencyShort(num amount) => _group(amount);

  /// 1250000 -> "1,25 mln so'm" — used on summary tiles.
  static String currencyCompact(num amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return "${millions.toStringAsFixed(millions >= 10 ? 0 : 2).replaceAll('.', ',')} mln so'm";
    }
    return currency(amount);
  }

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// 35 -> "35 daqiqa", 95 -> "1 soat 35 daqiqa"
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes daqiqa';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours soat' : '$hours soat $rest daqiqa';
  }

  /// Short ETA label for chips: "35 daq"
  static String eta(int minutes) =>
      minutes < 60 ? '$minutes daq' : '${(minutes / 60).toStringAsFixed(1).replaceAll('.', ',')} soat';

  static const List<String> _monthsUz = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// "12 sentabr, 14:30" — locale data free, so it can never throw.
  static String date(DateTime date) =>
      '${date.day} ${_monthsUz[date.month - 1]}, ${_two(date.hour)}:${_two(date.minute)}';

  static String dateOnly(DateTime date) =>
      '${date.day} ${_monthsUz[date.month - 1]} ${date.year}';

  static String time(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

  /// "Bugun, 14:30" / "Kecha, 09:12" / "12 sentabr, 14:30"
  static String relativeDate(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(value.year, value.month, value.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Bugun, ${time(value)}';
    if (diff == 1) return 'Kecha, ${time(value)}';
    return date(value);
  }

  /// "+998901234567" -> "+998 90 123 45 67"
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 12) return raw;
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
  }

  /// Masks all but the last four digits of a stored card token.
  static String maskedCard(String last4) => '•••• •••• •••• $last4';
}
