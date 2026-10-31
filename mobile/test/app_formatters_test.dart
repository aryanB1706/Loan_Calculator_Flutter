import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/utils/app_formatters.dart';

void main() {
  group('AppFormatters', () {
    test('currency drops paise and groups digits the Indian way', () {
      expect(AppFormatters.currency(0), '₹0');
      expect(AppFormatters.currency(99999), '₹99,999');
      expect(AppFormatters.currency(1250000), '₹12,50,000');
    });

    test('currencyPrecise always keeps two decimals', () {
      expect(AppFormatters.currencyPrecise(4442), '₹4,442.00');
      expect(AppFormatters.currencyPrecise(53309.276), '₹53,309.28');
    });

    test('dates use the formats the screens and the backend expect', () {
      final date = DateTime(2026, 3, 7);

      expect(AppFormatters.date(date), '07 Mar 2026');
      expect(AppFormatters.dobInput(date), '07 - 03 - 2026');
      expect(AppFormatters.isoDate(date), '2026-03-07');
    });
  });
}
