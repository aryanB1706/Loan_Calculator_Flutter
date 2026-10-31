import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');

  static String currency(num value) => _currency.format(value);

  static String date(DateTime value) => _date.format(value);
}
