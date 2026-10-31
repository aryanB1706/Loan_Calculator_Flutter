import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  // EMI and interest are not whole rupees, so results keep the paise.
  static final NumberFormat _currencyPrecise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');

  static final DateFormat _dobInput = DateFormat('dd - MM - yyyy');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String currency(num value) => _currency.format(value);

  static String currencyPrecise(num value) => _currencyPrecise.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dobInput(DateTime value) => _dobInput.format(value);

  // The backend expects a plain calendar date (no time, no timezone).
  static String isoDate(DateTime value) => _isoDate.format(value);
}
