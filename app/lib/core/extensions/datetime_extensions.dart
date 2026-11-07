import 'package:timeago/timeago.dart' as timeago;

extension DateTimeX on DateTime {
  String get timeAgo => timeago.format(this);

  String get formatted =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  String get formattedWithTime =>
      '$formatted ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
