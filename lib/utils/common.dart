import 'package:intl/intl.dart';

String getCurrentDateFormatted() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}
